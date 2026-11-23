// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import br.com.talhao.dto.AnaliseHistorico;
import br.com.talhao.dto.EventoHistoricoResponse;
import br.com.talhao.dto.TipoEventoHistorico;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.AnaliseSoloRepository;

// Linha do tempo de um talhao: plantios, colheitas e analises de solo
// juntos, em ordem cronologica (RF13)
@Service
public class HistoricoTalhaoService {

    private final TalhaoService talhaoService;
    private final CulturaService culturaService;
    private final AnaliseSoloRepository analiseSoloRepository;

    public HistoricoTalhaoService(
            TalhaoService talhaoService,
            CulturaService culturaService,
            AnaliseSoloRepository analiseSoloRepository) {

        this.talhaoService = talhaoService;
        this.culturaService = culturaService;
        this.analiseSoloRepository = analiseSoloRepository;
    }

    // MONTAR A LINHA DO TEMPO DE UM TALHAO DO USUARIO
    public List<EventoHistoricoResponse> montar(
            String talhaoId,
            String usuarioId) {

        // Confirma que o talhao pertence ao usuario (404 se nao pertencer)
        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);

        Map<String, String> nomes = culturaService.listar()
                .stream()
                .collect(Collectors.toMap(
                        Cultura::id,
                        Cultura::nome
                ));

        List<AnaliseSolo> analises = analiseSoloRepository
                .findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                        usuarioId,
                        talhao.propriedadeId(),
                        talhao.id()
                );

        return montar(talhao, analises, nomes);
    }

    // Monta e ordena os eventos (sem acesso ao banco)
    static List<EventoHistoricoResponse> montar(
            Talhao talhao,
            List<AnaliseSolo> analises,
            Map<String, String> nomesDasCulturas) {

        List<Item> itens = new ArrayList<>();

        for (Plantio plantio : talhao.plantios()) {

            // Plantio sem data nao tem lugar na linha do tempo
            if (plantio.dataPlantio() == null) {
                continue;
            }

            String nome = nomesDasCulturas.getOrDefault(
                    plantio.culturaId(),
                    plantio.culturaId()
            );

            itens.add(new Item(
                    new EventoHistoricoResponse(
                            TipoEventoHistorico.PLANTIO,
                            plantio.dataPlantio(),
                            plantio.plantioId(),
                            plantio.culturaId(),
                            nome,
                            null
                    ),
                    ORDEM_PLANTIO
            ));

            if (plantio.dataColheita() != null) {

                // Colheita no mesmo dia do proprio plantio vem depois dele
                boolean mesmoDia = plantio.dataColheita()
                        .equals(plantio.dataPlantio());

                itens.add(new Item(
                        new EventoHistoricoResponse(
                                TipoEventoHistorico.COLHEITA,
                                plantio.dataColheita(),
                                plantio.plantioId(),
                                plantio.culturaId(),
                                nome,
                                null
                        ),
                        mesmoDia ? ORDEM_COLHEITA_NO_DIA_DO_PLANTIO
                                : ORDEM_COLHEITA
                ));
            }
        }

        for (AnaliseSolo analise : analises) {

            if (analise.dataColeta() == null) {
                continue;
            }

            itens.add(new Item(
                    new EventoHistoricoResponse(
                            TipoEventoHistorico.ANALISE_SOLO,
                            analise.dataColeta(),
                            analise.id(),
                            null,
                            null,
                            new AnaliseHistorico(
                                    analise.ph(),
                                    analise.fosforo(),
                                    analise.potassio(),
                                    analise.saturacaoBases(),
                                    analise.observacoes()
                            )
                    ),
                    ORDEM_ANALISE
            ));
        }

        // Ordena por data; no mesmo dia vale a ordem natural do campo:
        // colheita da safra anterior, analise e depois o plantio novo.
        // O sort e estavel: empates mantem a ordem em que entraram.
        itens.sort(
                Comparator.comparing((Item item) -> item.evento().data())
                        .thenComparingInt(Item::ordemNoDia)
        );

        return itens.stream().map(Item::evento).toList();
    }

    private static final int ORDEM_COLHEITA = 0;
    private static final int ORDEM_ANALISE = 1;
    private static final int ORDEM_PLANTIO = 2;
    private static final int ORDEM_COLHEITA_NO_DIA_DO_PLANTIO = 3;

    private record Item(EventoHistoricoResponse evento, int ordemNoDia) {
    }
}
