package br.com.talhao.service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CenarioResponse;
import br.com.talhao.dto.RegraAplicada;
import br.com.talhao.dto.SimulacaoResponse;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Talhao;

// Compara cenarios de rotacao para a proxima safra de um talhao
@Service
public class SimulacaoService {

    static final String AVISO =
            "A recomendação é um apoio à decisão e não substitui um "
            + "engenheiro agrônomo.";

    static final String MENSAGEM_EQUIVALENTES =
            "As opções são equivalentes pelas regras do sistema: nenhuma se "
            + "destaca.";

    private final TalhaoService talhaoService;
    private final CulturaService culturaService;
    private final StatusSoloService statusSoloService;

    public SimulacaoService(
            TalhaoService talhaoService,
            CulturaService culturaService,
            StatusSoloService statusSoloService) {

        this.talhaoService = talhaoService;
        this.culturaService = culturaService;
        this.statusSoloService = statusSoloService;
    }

    // SIMULAR DE 2 A 3 CULTURAS COMO PROXIMA SAFRA
    public SimulacaoResponse simular(
            String talhaoId,
            String usuarioId,
            List<String> culturaIds) {

        // RN01: de 2 a 3 cenarios, sem repetir cultura
        if (culturaIds == null
                || culturaIds.size() < 2
                || culturaIds.size() > 3) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Informe de 2 a 3 culturas para comparar"
            );
        }

        if (new HashSet<>(culturaIds).size() != culturaIds.size()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Nao repita a mesma cultura na simulacao"
            );
        }

        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);

        // 400 se alguma cultura nao estiver no catalogo
        List<Cultura> candidatas = culturaIds.stream()
                .map(culturaService::buscar)
                .toList();

        Map<String, Cultura> catalogo = culturaService.listar().stream()
                .collect(Collectors.toMap(Cultura::id, Function.identity()));

        // RN05: so as duas ultimas safras entram nas regras
        List<Cultura> historico = HistoricoTalhao
                .culturasRecentes(talhao, catalogo, LocalDate.now())
                .stream()
                .limit(2)
                .toList();

        StatusSoloResponse status = statusSoloService.calcular(talhao);

        List<CenarioResponse> cenarios = candidatas.stream()
                .map(c -> montarCenario(c, historico, status))
                .toList();

        boolean equivalentes = RegrasRotacao.equivalentes(cenarios);

        return new SimulacaoResponse(
                talhao.id(),
                status,
                historico.stream().map(Cultura::nome).toList(),
                cenarios,
                equivalentes,
                equivalentes ? MENSAGEM_EQUIVALENTES : null,
                AVISO
        );
    }

    private CenarioResponse montarCenario(
            Cultura candidata,
            List<Cultura> historico,
            StatusSoloResponse status) {

        List<RegraAplicada> regras =
                RegrasRotacao.avaliar(candidata, historico, status);

        return new CenarioResponse(
                candidata.id(),
                candidata.nome(),
                RegrasRotacao.classificar(regras),
                regras
        );
    }
}
