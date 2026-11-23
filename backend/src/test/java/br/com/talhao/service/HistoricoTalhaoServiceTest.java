// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.EventoHistoricoResponse;
import br.com.talhao.dto.TipoEventoHistorico;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.AnaliseSoloRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa a linha do tempo do talhao (plantios, colheitas e analises)
@ExtendWith(MockitoExtension.class)
class HistoricoTalhaoServiceTest {

    private static final Instant CRIADO_EM =
            Instant.parse("2026-01-01T12:00:00Z");

    private static final Map<String, String> NOMES = Map.of(
            "soja", "Soja",
            "milho", "Milho"
    );

    @Mock
    private TalhaoService talhaoService;

    @Mock
    private CulturaService culturaService;

    @Mock
    private AnaliseSoloRepository analiseSoloRepository;

    @InjectMocks
    private HistoricoTalhaoService historicoTalhaoService;

    private static LocalDate dia(int mes, int dia) {
        return LocalDate.of(2026, mes, dia);
    }

    private Talhao talhao(Plantio... plantios) {
        return new Talhao("t1", "p1", "Norte", 10.0, CRIADO_EM,
                List.of(plantios));
    }

    private AnaliseSolo analise(String id, LocalDate data) {
        return new AnaliseSolo(id, "u1", "p1", "t1", data,
                5.5, 12.0, 2.5, 60.0, "coleta de rotina");
    }

    private List<TipoEventoHistorico> tipos(
            List<EventoHistoricoResponse> eventos) {
        return eventos.stream().map(EventoHistoricoResponse::tipo).toList();
    }

    // TESTE 1 - Junta plantio, colheita e analise e ordena por data
    @Test
    void deveOrdenarPlantiosColheitasEAnalisesPorData() {

        Talhao talhao = talhao(
                new Plantio("pl2", "milho", dia(10, 1), null),
                new Plantio("pl1", "soja", dia(3, 1), dia(8, 15))
        );

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao,
                        List.of(analise("a1", dia(9, 20))),
                        NOMES
                );

        assertEquals(
                List.of(
                        TipoEventoHistorico.PLANTIO,
                        TipoEventoHistorico.COLHEITA,
                        TipoEventoHistorico.ANALISE_SOLO,
                        TipoEventoHistorico.PLANTIO
                ),
                tipos(eventos)
        );
        assertEquals(
                List.of(dia(3, 1), dia(8, 15), dia(9, 20), dia(10, 1)),
                eventos.stream().map(EventoHistoricoResponse::data).toList()
        );
    }

    // TESTE 2 - Plantio traz cultura e referencia; analise traz os dados
    @Test
    void deveTrazerOsDadosPrincipaisDeCadaEvento() {

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao(new Plantio("pl1", "soja", dia(3, 1), null)),
                        List.of(analise("a1", dia(4, 1))),
                        NOMES
                );

        EventoHistoricoResponse plantio = eventos.get(0);
        assertEquals("pl1", plantio.referenciaId());
        assertEquals("soja", plantio.culturaId());
        assertEquals("Soja", plantio.culturaNome());
        assertNull(plantio.analise());

        EventoHistoricoResponse analise = eventos.get(1);
        assertEquals("a1", analise.referenciaId());
        assertNull(analise.culturaId());
        assertNull(analise.culturaNome());
        assertEquals(5.5, analise.analise().ph());
        assertEquals(12.0, analise.analise().fosforo());
        assertEquals(2.5, analise.analise().potassio());
        assertEquals(60.0, analise.analise().saturacaoBases());
        assertEquals("coleta de rotina", analise.analise().observacoes());
    }

    // TESTE 3 - Plantio aberto nao gera colheita
    @Test
    void naoDeveCriarColheitaParaPlantioAberto() {

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao(new Plantio("pl1", "soja", dia(3, 1), null)),
                        List.of(),
                        NOMES
                );

        assertEquals(List.of(TipoEventoHistorico.PLANTIO), tipos(eventos));
    }

    // TESTE 4 - No mesmo dia: colheita, analise e depois plantio novo
    @Test
    void deveOrdenarEventosDoMesmoDiaNaOrdemDoCampo() {

        Talhao talhao = talhao(
                new Plantio("pl2", "milho", dia(9, 1), null),
                new Plantio("pl1", "soja", dia(3, 1), dia(9, 1))
        );

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao,
                        List.of(analise("a1", dia(9, 1))),
                        NOMES
                );

        assertEquals(
                List.of(
                        TipoEventoHistorico.PLANTIO,
                        TipoEventoHistorico.COLHEITA,
                        TipoEventoHistorico.ANALISE_SOLO,
                        TipoEventoHistorico.PLANTIO
                ),
                tipos(eventos)
        );
        assertEquals("pl1", eventos.get(1).referenciaId());
        assertEquals("pl2", eventos.get(3).referenciaId());
    }

    // TESTE 5 - Colheita no mesmo dia do proprio plantio vem depois dele
    @Test
    void colheitaNoDiaDoProprioPlantioFicaDepoisDoPlantio() {

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao(new Plantio("pl1", "soja", dia(3, 1), dia(3, 1))),
                        List.of(),
                        NOMES
                );

        assertEquals(
                List.of(TipoEventoHistorico.PLANTIO,
                        TipoEventoHistorico.COLHEITA),
                tipos(eventos)
        );
    }

    // TESTE 6 - Cultura fora do catalogo mostra o id no lugar do nome
    @Test
    void deveUsarOIdQuandoACulturaSaiuDoCatalogo() {

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao(new Plantio("pl1", "trigo", dia(3, 1), null)),
                        List.of(),
                        NOMES
                );

        assertEquals("trigo", eventos.get(0).culturaNome());
    }

    // TESTE 7 - Registros sem data ficam de fora
    @Test
    void deveIgnorarRegistrosSemData() {

        List<EventoHistoricoResponse> eventos =
                HistoricoTalhaoService.montar(
                        talhao(
                                new Plantio("pl1", "soja", null, null),
                                new Plantio("pl2", "milho", dia(3, 1), null)
                        ),
                        List.of(analise("a1", null)),
                        NOMES
                );

        assertEquals(1, eventos.size());
        assertEquals("pl2", eventos.get(0).referenciaId());
    }

    // TESTE 8 - Talhao sem nada devolve lista vazia
    @Test
    void deveDevolverListaVaziaQuandoNaoHaEventos() {

        assertTrue(
                HistoricoTalhaoService.montar(talhao(), List.of(), NOMES)
                        .isEmpty()
        );
    }

    // TESTE 9 - Busca as analises so do talhao e da propriedade do usuario
    @Test
    void deveBuscarAsAnalisesDoTalhaoDoUsuario() {

        Talhao talhao = talhao(new Plantio("pl1", "soja", dia(3, 1), null));

        when(talhaoService.buscarEntidade("t1", "u1")).thenReturn(talhao);
        when(culturaService.listar()).thenReturn(List.of(new Cultura(
                "soja", "Soja", "Glycine max", "Fabaceae",
                Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS)));
        when(analiseSoloRepository
                .findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                        "u1", "p1", "t1"))
                .thenReturn(List.of(analise("a1", dia(2, 1))));

        List<EventoHistoricoResponse> eventos =
                historicoTalhaoService.montar("t1", "u1");

        assertEquals(
                List.of(TipoEventoHistorico.ANALISE_SOLO,
                        TipoEventoHistorico.PLANTIO),
                tipos(eventos)
        );
        assertEquals("Soja", eventos.get(1).culturaNome());
    }

    // TESTE 10 - Talhao de outro usuario: 404 e nenhuma analise e lida
    @Test
    void naoDeveLerAnalisesDeTalhaoQueNaoEDoUsuario() {

        when(talhaoService.buscarEntidade("t1", "u2"))
                .thenThrow(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Talhao nao encontrado"));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> historicoTalhaoService.montar("t1", "u2")
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
        verifyNoInteractions(analiseSoloRepository);
    }
}
