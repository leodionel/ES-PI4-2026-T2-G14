package br.com.talhao.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import br.com.talhao.dto.DashboardResponse;
import br.com.talhao.dto.DistribuicaoStatus;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.dto.TalhaoEmAlerta;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

// Monta o resumo da propriedade para a tela inicial.
// O status de cada talhao vem do StatusSoloService, que e a unica
// fonte dessa regra.
@Service
public class DashboardService {

    // Ordem fixa da distribuicao: do mais grave ao menos grave
    private static final List<StatusSolo> ORDEM = List.of(
            StatusSolo.RISCO,
            StatusSolo.ATENCAO,
            StatusSolo.SAUDAVEL,
            StatusSolo.SEM_ANALISE
    );

    private final PropriedadeRepository propriedadeRepository;
    private final TalhaoRepository talhaoRepository;
    private final StatusSoloService statusSoloService;
    private final CulturaService culturaService;

    public DashboardService(
            PropriedadeRepository propriedadeRepository,
            TalhaoRepository talhaoRepository,
            StatusSoloService statusSoloService,
            CulturaService culturaService) {

        this.propriedadeRepository = propriedadeRepository;
        this.talhaoRepository = talhaoRepository;
        this.statusSoloService = statusSoloService;
        this.culturaService = culturaService;
    }

    // Resumo da propriedade do usuario logado
    public DashboardResponse montar(String usuarioId) {

        // No MVP cada usuario tem no maximo uma propriedade (RN11)
        Optional<Propriedade> propriedade = propriedadeRepository
                .findByUsuarioId(usuarioId)
                .stream()
                .findFirst();

        // Sem propriedade nao ha talhoes: o dashboard vem zerado
        if (propriedade.isEmpty()) {
            return montarResposta(null, List.of(), Map.of(), List.of());
        }

        List<Talhao> talhoes = talhaoRepository
                .findByPropriedadeId(propriedade.get().id());

        // O catalogo e lido uma vez para todos os talhoes
        Map<String, Cultura> catalogo = culturaService.listar().stream()
                .collect(Collectors.toMap(Cultura::id, Function.identity()));

        Map<StatusSolo, Integer> contagem = new EnumMap<>(StatusSolo.class);
        List<TalhaoEmAlerta> alertas = new ArrayList<>();

        for (Talhao talhao : talhoes) {

            StatusSoloResponse status =
                    statusSoloService.calcular(talhao, catalogo);

            contagem.merge(status.status(), 1, Integer::sum);

            if (status.status() == StatusSolo.RISCO
                    || status.status() == StatusSolo.ATENCAO) {

                alertas.add(new TalhaoEmAlerta(
                        talhao.id(),
                        talhao.nome(),
                        talhao.areaHa(),
                        status.status(),
                        status.dataAnalise(),
                        status.motivos()
                ));
            }
        }

        // Risco antes de atencao; dentro de cada grupo, por nome
        alertas.sort(
                Comparator
                        .comparing((TalhaoEmAlerta a) ->
                                a.status() == StatusSolo.RISCO ? 0 : 1)
                        .thenComparing(
                                TalhaoEmAlerta::nome,
                                String.CASE_INSENSITIVE_ORDER)
        );

        return montarResposta(
                propriedade.get().nome(), talhoes, contagem, alertas);
    }

    private DashboardResponse montarResposta(
            String propriedadeNome,
            List<Talhao> talhoes,
            Map<StatusSolo, Integer> contagem,
            List<TalhaoEmAlerta> alertas) {

        // Soma em BigDecimal para nao acumular erro de ponto flutuante
        BigDecimal area = talhoes.stream()
                .map(t -> BigDecimal.valueOf(t.areaHa()))
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);

        List<DistribuicaoStatus> distribuicao = ORDEM.stream()
                .map(s -> new DistribuicaoStatus(s, contagem.getOrDefault(s, 0)))
                .toList();

        return new DashboardResponse(
                propriedadeNome,
                talhoes.size(),
                area.doubleValue(),
                distribuicao,
                alertas
        );
    }
}
