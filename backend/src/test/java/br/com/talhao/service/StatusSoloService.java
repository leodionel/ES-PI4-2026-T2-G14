package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.AnaliseSoloRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa a leitura dos dados e o uso do catalogo no status do solo
@ExtendWith(MockitoExtension.class)
class StatusSoloServiceTest {

    @Mock
    private TalhaoService talhaoService;

    @Mock
    private AnaliseSoloRepository analiseSoloRepository;

    @Mock
    private CulturaService culturaService;

    @InjectMocks
    private StatusSoloService statusSoloService;

    private final Cultura soja = new Cultura(
            "soja", "Soja", "Glycine max", "Fabaceae",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private Talhao talhaComSoja() {
        return new Talhao(
                "t1", "p1", "Talhao 1", 10, Instant.now(),
                List.of(new Plantio(
                        "pl1", "soja", LocalDate.now().minusMonths(6), null)));
    }

    // Analise com pH, V e K sem alerta e fosforo baixo para soja (<= 15)
    private AnaliseSolo analiseComFosforoBaixo() {
        return new AnaliseSolo(
                "a1", "u1", "p1", "t1", LocalDate.of(2026, 1, 10),
                5.6, 10.0, 2.0, 60.0, null);
    }

    // TESTE 1 - Sem analise o status e SEM_ANALISE
    @Test
    void deveRetornarSemAnaliseQuandoNaoHaAnalise() {

        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.empty());

        StatusSoloResponse resposta =
                statusSoloService.calcular(talhaComSoja(), Map.of("soja", soja));

        assertEquals(StatusSolo.SEM_ANALISE, resposta.status());
    }

    // TESTE 2 - O fosforo usa o grupo da ultima cultura comercial
    @Test
    void deveUsarOCatalogoRecebidoParaOFosforo() {

        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.of(analiseComFosforoBaixo()));

        StatusSoloResponse resposta =
                statusSoloService.calcular(talhaComSoja(), Map.of("soja", soja));

        assertEquals(StatusSolo.ATENCAO, resposta.status());
        assertEquals(List.of("P (baixo)"), resposta.motivos());
        assertEquals(LocalDate.of(2026, 1, 10), resposta.dataAnalise());
    }

    // TESTE 3 - Com o catalogo recebido, o CulturaService nao e consultado
    @Test
    void naoDeveLerOCatalogoQuandoElePassaPronto() {

        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.of(analiseComFosforoBaixo()));

        statusSoloService.calcular(talhaComSoja(), Map.of("soja", soja));

        verifyNoInteractions(culturaService);
    }

    // TESTE 4 - Sem catalogo informado, ele e lido do CulturaService
    @Test
    void deveLerOCatalogoQuandoNaoRecebeUm() {

        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.of(analiseComFosforoBaixo()));

        StatusSoloResponse resposta =
                statusSoloService.calcular(talhaComSoja());

        assertEquals(StatusSolo.ATENCAO, resposta.status());
        verify(culturaService).listar();
    }

    // TESTE 5 - Sem cultura comercial o fosforo fica de fora e ha aviso
    @Test
    void deveAvisarQuandoOTalhaoNaoTemCulturaComercial() {

        Talhao semPlantios = new Talhao(
                "t1", "p1", "Talhao 1", 10, Instant.now(), List.of());

        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.of(analiseComFosforoBaixo()));

        StatusSoloResponse resposta =
                statusSoloService.calcular(semPlantios, Map.of("soja", soja));

        assertEquals(StatusSolo.SAUDAVEL, resposta.status());
        assertNotNull(resposta.aviso());
    }

    // TESTE 6 - buscar() so aceita talhao do usuario
    @Test
    void deveBuscarOTalhaoPeloUsuario() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaComSoja());
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.empty());

        StatusSoloResponse resposta = statusSoloService.buscar("t1", "u1");

        assertEquals(StatusSolo.SEM_ANALISE, resposta.status());
        verify(talhaoService).buscarEntidade("t1", "u1");
    }
}
