package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.SimulacaoResponse;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Classificacao;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa a montagem da simulacao (validacoes, historico e equivalencia)
@ExtendWith(MockitoExtension.class)
class SimulacaoServiceTest {

    @Mock
    private TalhaoService talhaoService;

    @Mock
    private CulturaService culturaService;

    @Mock
    private StatusSoloService statusSoloService;

    @InjectMocks
    private SimulacaoService simulacaoService;

    private final Cultura soja = new Cultura("soja", "Soja", "", "",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);
    private final Cultura feijao = new Cultura("feijao", "Feijão-comum", "", "",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);
    private final Cultura milho = new Cultura("milho", "Milho", "", "",
            Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private final StatusSoloResponse solo = new StatusSoloResponse(
            StatusSolo.SAUDAVEL, null, List.of(), List.of(), null);

    private Talhao talhaoCom(List<Plantio> plantios) {
        return new Talhao("t1", "p1", "Talhão 04", 10.0, Instant.now(), plantios);
    }

    private void prepararCatalogo() {
        when(culturaService.listar()).thenReturn(List.of(feijao, milho, soja));
    }

    @BeforeEach
    void configurar() {
        lenient().when(culturaService.buscar("soja")).thenReturn(soja);
        lenient().when(culturaService.buscar("feijao")).thenReturn(feijao);
        lenient().when(culturaService.buscar("milho")).thenReturn(milho);
    }

    // Uma so cultura nao e uma comparacao (RN01)
    @Test
    void naoDeveSimularComUmaCultura() {

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> simulacaoService.simular("t1", "u1", List.of("soja")));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verifyNoInteractions(talhaoService);
    }

    // Mais de 3 culturas tambem nao (RN01)
    @Test
    void naoDeveSimularComQuatroCulturas() {

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> simulacaoService.simular("t1", "u1",
                        List.of("soja", "milho", "feijao", "trigo")));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
    }

    // Cultura repetida nao conta como cenario novo
    @Test
    void naoDeveSimularCulturaRepetida() {

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> simulacaoService.simular("t1", "u1",
                        List.of("soja", "soja")));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
    }

    // Talhao de outro usuario: o erro 404 vem do TalhaoService
    @Test
    void naoDeveSimularTalhaoDeOutroUsuario() {

        when(talhaoService.buscarEntidade("t1", "u2"))
                .thenThrow(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Talhao nao encontrado"));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> simulacaoService.simular("t1", "u2",
                        List.of("soja", "milho")));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
    }

    // Cultura fora do catalogo: 400 vem do CulturaService
    @Test
    void naoDeveSimularCulturaForaDoCatalogo() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of()));
        when(culturaService.buscar("xyz"))
                .thenThrow(new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Cultura nao encontrada"));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> simulacaoService.simular("t1", "u1",
                        List.of("soja", "xyz")));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
    }

    // T1 de ponta a ponta: historico soja; candidatas milho, feijao, soja
    @Test
    void deveMontarOsCenariosDoCasoT1() {

        prepararCatalogo();
        when(talhaoService.buscarEntidade("t1", "u1")).thenReturn(talhaoCom(
                List.of(new Plantio("pl1", "soja",
                        LocalDate.of(2025, 11, 15), null))));
        when(statusSoloService.calcular(any(Talhao.class))).thenReturn(solo);

        SimulacaoResponse r = simulacaoService.simular("t1", "u1",
                List.of("milho", "feijao", "soja"));

        assertEquals(List.of("Soja"), r.historicoConsiderado());
        assertEquals(Classificacao.RECOMENDADO, r.cenarios().get(0).classificacao());
        assertEquals(Classificacao.ACEITAVEL, r.cenarios().get(1).classificacao());
        assertEquals(Classificacao.NAO_RECOMENDADO, r.cenarios().get(2).classificacao());
        assertFalse(r.opcoesEquivalentes());
        assertNull(r.mensagemEquivalencia());
        assertNotNull(r.aviso());
    }

    // So as duas ultimas safras entram, da mais recente para a mais antiga
    @Test
    void deveConsiderarApenasAsDuasUltimasSafras() {

        prepararCatalogo();
        when(talhaoService.buscarEntidade("t1", "u1")).thenReturn(talhaoCom(List.of(
                new Plantio("a", "soja", LocalDate.of(2024, 11, 1), LocalDate.of(2025, 3, 1)),
                new Plantio("b", "milho", LocalDate.of(2025, 4, 1), LocalDate.of(2025, 8, 1)),
                new Plantio("c", "feijao", LocalDate.of(2025, 11, 1), null))));
        when(statusSoloService.calcular(any(Talhao.class))).thenReturn(solo);

        SimulacaoResponse r = simulacaoService.simular("t1", "u1",
                List.of("soja", "milho"));

        assertEquals(List.of("Feijão-comum", "Milho"), r.historicoConsiderado());
    }

    // Historico vazio: opcoes equivalentes (T3)
    @Test
    void deveInformarEquivalenciaComHistoricoVazio() {

        prepararCatalogo();
        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of()));
        when(statusSoloService.calcular(any(Talhao.class))).thenReturn(solo);

        SimulacaoResponse r = simulacaoService.simular("t1", "u1",
                List.of("soja", "milho"));

        assertTrue(r.opcoesEquivalentes());
        assertNotNull(r.mensagemEquivalencia());
    }
}
