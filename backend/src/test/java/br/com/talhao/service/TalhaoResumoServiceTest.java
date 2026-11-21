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

import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.dto.TalhaoResumoResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.AnaliseSoloRepository;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa a lista de talhoes com cultura atual e status do solo
@ExtendWith(MockitoExtension.class)
class TalhaoResumoServiceTest {

    private static final Instant CRIADO_EM =
            Instant.parse("2026-01-01T12:00:00Z");

    @Mock
    private TalhaoRepository talhaoRepository;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @Mock
    private AnaliseSoloRepository analiseSoloRepository;

    @Mock
    private StatusSoloService statusSoloService;

    @Mock
    private CulturaService culturaService;

    @InjectMocks
    private TalhaoResumoService talhaoResumoService;

    private final Cultura soja = new Cultura(
            "soja", "Soja", "Glycine max", "Fabaceae",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private Talhao talhao(String id, String nome, Plantio... plantios) {
        return new Talhao(id, "p1", nome, 12.5, CRIADO_EM, List.of(plantios));
    }

    private StatusSoloResponse status(StatusSolo status) {
        return new StatusSoloResponse(
                status, null, List.of(), List.of(), null);
    }

    private void comPropriedadeETalhoes(Talhao... talhoes) {
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(new Propriedade(
                        "p1", "u1", "Sitio", "Campinas - SP")));
        when(talhaoRepository.findByPropriedadeId("p1"))
                .thenReturn(List.of(talhoes));
    }

    // TESTE 1 - Sem propriedade a lista vem vazia
    @Test
    void deveRetornarListaVaziaSemPropriedade() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        assertTrue(talhaoResumoService.listar("u1").isEmpty());
        verifyNoInteractions(talhaoRepository, statusSoloService);
    }

    // TESTE 2 - Propriedade sem talhoes
    @Test
    void deveRetornarListaVaziaSemTalhoes() {

        comPropriedadeETalhoes();

        assertTrue(talhaoResumoService.listar("u1").isEmpty());
        verifyNoInteractions(statusSoloService);
    }

    // TESTE 3 - Talhao com cultura plantada e status
    @Test
    void deveMontarOResumoComCulturaAtualEStatus() {

        Talhao t = talhao("t1", "Talhao Norte",
                new Plantio("pl1", "soja",
                        LocalDate.now().minusMonths(2), null));
        comPropriedadeETalhoes(t);
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.countByTalhaoId("t1")).thenReturn(3L);
        when(statusSoloService.calcular(eq(t), anyMap()))
                .thenReturn(status(StatusSolo.ATENCAO));

        TalhaoResumoResponse resumo = talhaoResumoService.listar("u1").get(0);

        assertEquals("t1", resumo.id());
        assertEquals("Talhao Norte", resumo.nome());
        assertEquals(12.5, resumo.areaHa());
        assertEquals(CRIADO_EM, resumo.criadoEm());
        assertEquals(1, resumo.totalPlantios());
        assertEquals(3, resumo.totalAnalises());
        assertEquals("pl1", resumo.culturaAtual().plantioId());
        assertEquals("soja", resumo.culturaAtual().culturaId());
        assertEquals("Soja", resumo.culturaAtual().nome());
        assertEquals(LocalDate.now().minusMonths(2),
                resumo.culturaAtual().dataPlantio());
        assertEquals(StatusSolo.ATENCAO, resumo.statusSolo());
    }

    // TESTE 4 - Talhao novo: sem cultura e sem analise
    @Test
    void deveVirSemCulturaAtualQuandoNaoHaPlantio() {

        Talhao t = talhao("t1", "Talhao Novo");
        comPropriedadeETalhoes(t);
        when(analiseSoloRepository.countByTalhaoId("t1")).thenReturn(0L);
        when(statusSoloService.calcular(eq(t), anyMap()))
                .thenReturn(status(StatusSolo.SEM_ANALISE));

        TalhaoResumoResponse resumo = talhaoResumoService.listar("u1").get(0);

        assertNull(resumo.culturaAtual());
        assertEquals(0, resumo.totalPlantios());
        assertEquals(StatusSolo.SEM_ANALISE, resumo.statusSolo());
    }

    // TESTE 5 - Safra colhida conta no total, mas nao e a cultura atual
    @Test
    void deveContarSafraColhidaSemTratarComoAtual() {

        Talhao t = talhao("t1", "Talhao Sul",
                new Plantio("pl1", "soja",
                        LocalDate.now().minusMonths(8),
                        LocalDate.now().minusMonths(4)));
        comPropriedadeETalhoes(t);
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.countByTalhaoId("t1")).thenReturn(1L);
        when(statusSoloService.calcular(eq(t), anyMap()))
                .thenReturn(status(StatusSolo.SAUDAVEL));

        TalhaoResumoResponse resumo = talhaoResumoService.listar("u1").get(0);

        assertEquals(1, resumo.totalPlantios());
        assertNull(resumo.culturaAtual());
    }

    // TESTE 6 - O catalogo e lido uma vez so, para todos os talhoes
    @Test
    void deveLerOCatalogoUmaVezParaTodosOsTalhoes() {

        Talhao a = talhao("t1", "A");
        Talhao b = talhao("t2", "B");
        Talhao c = talhao("t3", "C");
        comPropriedadeETalhoes(a, b, c);
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(statusSoloService.calcular(
                any(Talhao.class), eq(Map.of("soja", soja))))
                .thenReturn(status(StatusSolo.SEM_ANALISE));

        List<TalhaoResumoResponse> lista = talhaoResumoService.listar("u1");

        assertEquals(3, lista.size());
        verify(culturaService, times(1)).listar();
        verify(statusSoloService, times(3)).calcular(
                any(Talhao.class), eq(Map.of("soja", soja)));
    }

    // TESTE 7 - A ordem dos talhoes e a do repositorio
    @Test
    void deveManterAOrdemDoRepositorio() {

        Talhao a = talhao("t1", "Zeta");
        Talhao b = talhao("t2", "Alfa");
        comPropriedadeETalhoes(a, b);
        when(statusSoloService.calcular(any(Talhao.class), anyMap()))
                .thenReturn(status(StatusSolo.SEM_ANALISE));

        List<String> nomes = talhaoResumoService.listar("u1").stream()
                .map(TalhaoResumoResponse::nome)
                .toList();

        assertEquals(List.of("Zeta", "Alfa"), nomes);
    }

    // TESTE 8 - So os talhoes da propriedade do usuario sao lidos
    @Test
    void deveLerSomenteOsTalhoesDaPropriedadeDoUsuario() {

        comPropriedadeETalhoes();

        talhaoResumoService.listar("u1");

        verify(talhaoRepository).findByPropriedadeId("p1");
        verifyNoMoreInteractions(talhaoRepository);
    }
}
