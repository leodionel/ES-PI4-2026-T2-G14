// Feito por Leonardo Dionel RA:25010092

// Contribuição: Matheus Rosini
// RA: 25015832


package br.com.talhao.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import br.com.talhao.dto.CulturaAtualResponse;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.dto.TalhaoResumoResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.AnaliseSoloRepository;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

// Monta a lista de talhoes com dados completos (RF07).
// O status vem do StatusSoloService.
@Service
public class TalhaoResumoService {

    private final TalhaoRepository talhaoRepository;
    private final PropriedadeRepository propriedadeRepository;
    private final AnaliseSoloRepository analiseSoloRepository;
    private final StatusSoloService statusSoloService;
    private final CulturaService culturaService;

    public TalhaoResumoService(
            TalhaoRepository talhaoRepository,
            PropriedadeRepository propriedadeRepository,
            AnaliseSoloRepository analiseSoloRepository,
            StatusSoloService statusSoloService,
            CulturaService culturaService) {

        this.talhaoRepository = talhaoRepository;
        this.propriedadeRepository = propriedadeRepository;
        this.analiseSoloRepository = analiseSoloRepository;
        this.statusSoloService = statusSoloService;
        this.culturaService = culturaService;
    }

    // Lista os talhoes da propriedade do usuario.
    public List<TalhaoResumoResponse> listar(String usuarioId) {

        // No MVP, cada usuario tem no maximo uma propriedade.
        Optional<Propriedade> propriedade = propriedadeRepository
                .findByUsuarioId(usuarioId)
                .stream()
                .findFirst();

        if (propriedade.isEmpty()) {
            return List.of();
        }

        List<Talhao> talhoes = talhaoRepository
                .findByPropriedadeId(propriedade.get().id());

        // Carrega o catalogo de culturas uma unica vez.
        Map<String, Cultura> catalogo = culturaService
                .listar()
                .stream()
                .collect(Collectors.toMap(
                        Cultura::id,
                        Function.identity()
                ));

        LocalDate hoje = LocalDate.now();

        return talhoes.stream()
                .map(talhao -> paraResumo(
                        talhao,
                        catalogo,
                        hoje
                ))
                .toList();
    }

    private TalhaoResumoResponse paraResumo(
            Talhao talhao,
            Map<String, Cultura> catalogo,
            LocalDate hoje) {

        // O backend determina qual plantio esta em andamento.
        CulturaAtualResponse culturaAtual = HistoricoTalhao
                .plantioAtual(talhao, catalogo, hoje)
                .map(plantio -> paraCulturaAtual(
                        plantio,
                        catalogo
                ))
                .orElse(null);

        // Calcula o status apenas uma vez e reutiliza os dados.
        StatusSoloResponse statusSolo =
                statusSoloService.calcular(talhao, catalogo);

        return new TalhaoResumoResponse(
                talhao.id(),
                talhao.nome(),
                talhao.areaHa(),
                talhao.criadoEm(),
                talhao.plantios().size(),
                (int) analiseSoloRepository.countByTalhaoId(
                        talhao.id()
                ),
                culturaAtual,
                statusSolo.status(),
                statusSolo.dataAnalise(),
                statusSolo.motivos()
        );
    }

    private CulturaAtualResponse paraCulturaAtual(
            Plantio plantio,
            Map<String, Cultura> catalogo) {

        return new CulturaAtualResponse(
                plantio.plantioId(),
                plantio.culturaId(),
                catalogo.get(plantio.culturaId()).nome(),
                plantio.dataPlantio()
        );
    }
}
