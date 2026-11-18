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

import br.com.talhao.dto.DashboardResponse;
import br.com.talhao.dto.DistribuicaoStatus;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

// Testa a montagem do dashboard (contagens, area e alertas)
@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    private static final LocalDate DATA = LocalDate.of(2026, 1, 10);

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @Mock
    private TalhaoRepository talhaoRepository;

    @Mock
    private StatusSoloService statusSoloService;

    @Mock
    private CulturaService culturaService;

    @InjectMocks
    private DashboardService dashboardService;

    private Propriedade propriedade() {
        return new Propriedade("p1", "u1", "Sitio Boa Vista", "Campinas - SP");
    }

    private Talhao talhao(String id, String nome, double area) {
        return new Talhao(id, "p1", nome, area, Instant.now(), List.of());
    }

    private StatusSoloResponse status(StatusSolo status, String... motivos) {
        return new StatusSoloResponse(
                status,
                status == StatusSolo.SEM_ANALISE ? null : DATA,
                List.of(),
                List.of(motivos),
                null
        );
    }

    private void comPropriedadeETalhoes(Talhao... talhoes) {
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedade()));
        when(talhaoRepository.findByPropriedadeId("p1"))
                .thenReturn(List.of(talhoes));
    }

    private void definirStatus(Talhao talhao, StatusSoloResponse resposta) {
        when(statusSoloService.calcular(eq(talhao), anyMap()))
                .thenReturn(resposta);
    }

    private int quantidade(DashboardResponse resposta, StatusSolo status) {
        return resposta.distribuicao().stream()
                .filter(d -> d.status() == status)
                .mapToInt(DistribuicaoStatus::quantidade)
                .sum();
    }

    // TESTE 1 - Sem propriedade o dashboard vem zerado
    @Test
    void deveVirZeradoSemPropriedade() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        DashboardResponse resposta = dashboardService.montar("u1");

        assertNull(resposta.propriedadeNome());
        assertEquals(0, resposta.totalTalhoes());
        assertEquals(0.0, resposta.areaTotalHa());
        assertEquals(4, resposta.distribuicao().size());
        assertTrue(resposta.talhoesEmAlerta().isEmpty());
        verifyNoInteractions(talhaoRepository, statusSoloService);
    }

    // TESTE 2 - Propriedade sem talhoes
    @Test
    void deveVirZeradoSemTalhoes() {

        comPropriedadeETalhoes();

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals("Sitio Boa Vista", resposta.propriedadeNome());
        assertEquals(0, resposta.totalTalhoes());
        assertEquals(0.0, resposta.areaTotalHa());
        assertTrue(resposta.talhoesEmAlerta().isEmpty());
        verifyNoInteractions(statusSoloService);
    }

    // TESTE 3 - Total de talhoes e soma da area (RF14)
    @Test
    void deveSomarAreaEContarTalhoes() {

        Talhao a = talhao("t1", "A", 0.1);
        Talhao b = talhao("t2", "B", 0.2);
        Talhao c = talhao("t3", "C", 10.5);
        comPropriedadeETalhoes(a, b, c);
        definirStatus(a, status(StatusSolo.SAUDAVEL));
        definirStatus(b, status(StatusSolo.SAUDAVEL));
        definirStatus(c, status(StatusSolo.SAUDAVEL));

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals(3, resposta.totalTalhoes());
        // 0,1 + 0,2 + 10,5 sem o erro de ponto flutuante
        assertEquals(10.8, resposta.areaTotalHa());
    }

    // TESTE 4 - Distribuicao com os quatro status, em ordem (RF15)
    @Test
    void deveContarTalhoesPorStatusNaOrdemFixa() {

        Talhao a = talhao("t1", "A", 1);
        Talhao b = talhao("t2", "B", 1);
        Talhao c = talhao("t3", "C", 1);
        Talhao d = talhao("t4", "D", 1);
        Talhao e = talhao("t5", "E", 1);
        comPropriedadeETalhoes(a, b, c, d, e);
        definirStatus(a, status(StatusSolo.RISCO, "pH (acidez muito alta)"));
        definirStatus(b, status(StatusSolo.ATENCAO, "K (baixo)"));
        definirStatus(c, status(StatusSolo.ATENCAO, "P (baixo)"));
        definirStatus(d, status(StatusSolo.SAUDAVEL));
        definirStatus(e, status(StatusSolo.SEM_ANALISE));

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals(
                List.of(
                        StatusSolo.RISCO,
                        StatusSolo.ATENCAO,
                        StatusSolo.SAUDAVEL,
                        StatusSolo.SEM_ANALISE),
                resposta.distribuicao().stream()
                        .map(DistribuicaoStatus::status)
                        .toList());
        assertEquals(1, quantidade(resposta, StatusSolo.RISCO));
        assertEquals(2, quantidade(resposta, StatusSolo.ATENCAO));
        assertEquals(1, quantidade(resposta, StatusSolo.SAUDAVEL));
        assertEquals(1, quantidade(resposta, StatusSolo.SEM_ANALISE));
    }

    // TESTE 5 - Status sem nenhum talhao aparece com zero
    @Test
    void deveMostrarZeroNosStatusSemTalhoes() {

        Talhao a = talhao("t1", "A", 1);
        comPropriedadeETalhoes(a);
        definirStatus(a, status(StatusSolo.SAUDAVEL));

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals(4, resposta.distribuicao().size());
        assertEquals(0, quantidade(resposta, StatusSolo.RISCO));
        assertEquals(0, quantidade(resposta, StatusSolo.ATENCAO));
        assertEquals(1, quantidade(resposta, StatusSolo.SAUDAVEL));
        assertEquals(0, quantidade(resposta, StatusSolo.SEM_ANALISE));
    }

    // TESTE 6 - So risco e atencao entram na lista de alertas (RF16)
    @Test
    void deveListarApenasTalhoesEmRiscoOuAtencao() {

        Talhao saudavel = talhao("t1", "Saudavel", 1);
        Talhao semAnalise = talhao("t2", "Sem analise", 1);
        Talhao atencao = talhao("t3", "Atencao", 2.5);
        comPropriedadeETalhoes(saudavel, semAnalise, atencao);
        definirStatus(saudavel, status(StatusSolo.SAUDAVEL));
        definirStatus(semAnalise, status(StatusSolo.SEM_ANALISE));
        definirStatus(atencao, status(StatusSolo.ATENCAO, "K (baixo)"));

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals(1, resposta.talhoesEmAlerta().size());
        assertEquals("t3", resposta.talhoesEmAlerta().get(0).talhaoId());
        assertEquals("Atencao", resposta.talhoesEmAlerta().get(0).nome());
        assertEquals(2.5, resposta.talhoesEmAlerta().get(0).areaHa());
        assertEquals(StatusSolo.ATENCAO,
                resposta.talhoesEmAlerta().get(0).status());
        assertEquals(DATA, resposta.talhoesEmAlerta().get(0).dataAnalise());
        assertEquals(List.of("K (baixo)"),
                resposta.talhoesEmAlerta().get(0).motivos());
    }

    // TESTE 7 - Risco vem antes de atencao; depois, ordem de nome
    @Test
    void deveOrdenarAlertasPorGravidadeENome() {

        Talhao atencaoB = talhao("t1", "bravo", 1);
        Talhao riscoZ = talhao("t2", "Zulu", 1);
        Talhao atencaoA = talhao("t3", "Alfa", 1);
        Talhao riscoC = talhao("t4", "Charlie", 1);
        comPropriedadeETalhoes(atencaoB, riscoZ, atencaoA, riscoC);
        definirStatus(atencaoB, status(StatusSolo.ATENCAO, "P (baixo)"));
        definirStatus(riscoZ, status(StatusSolo.RISCO, "V% (muito baixa)"));
        definirStatus(atencaoA, status(StatusSolo.ATENCAO, "K (baixo)"));
        definirStatus(riscoC, status(StatusSolo.RISCO, "pH (acidez muito alta)"));

        DashboardResponse resposta = dashboardService.montar("u1");

        assertEquals(
                List.of("Charlie", "Zulu", "Alfa", "bravo"),
                resposta.talhoesEmAlerta().stream()
                        .map(a -> a.nome())
                        .toList());
    }

    // TESTE 8 - O catalogo de culturas e lido uma vez so
    @Test
    void deveLerOCatalogoUmaVezParaTodosOsTalhoes() {

        Cultura soja = new Cultura(
                "soja", "Soja", "Glycine max", "Fabaceae",
                Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);
        Talhao a = talhao("t1", "A", 1);
        Talhao b = talhao("t2", "B", 1);
        Talhao c = talhao("t3", "C", 1);
        comPropriedadeETalhoes(a, b, c);
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(statusSoloService.calcular(any(Talhao.class), eq(Map.of("soja", soja))))
                .thenReturn(status(StatusSolo.SAUDAVEL));

        dashboardService.montar("u1");

        verify(culturaService, times(1)).listar();
        verify(statusSoloService, times(3))
                .calcular(any(Talhao.class), eq(Map.of("soja", soja)));
    }

    // TESTE 9 - So os talhoes da propriedade do usuario sao lidos
    @Test
    void deveLerSomenteOsTalhoesDaPropriedadeDoUsuario() {

        comPropriedadeETalhoes();

        dashboardService.montar("u1");

        verify(propriedadeRepository).findByUsuarioId("u1");
        verify(talhaoRepository).findByPropriedadeId("p1");
        verifyNoMoreInteractions(talhaoRepository);
    }
}
