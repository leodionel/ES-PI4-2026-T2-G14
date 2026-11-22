// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
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

// Testa a montagem do status: ultima analise + ultima cultura comercial
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

    private Talhao talhao(List<Plantio> plantios) {
        return new Talhao("t1", "p1", "Talhão 04", 10.0,
                Instant.now(), plantios);
    }

    // TESTE 1 - Sem nenhuma analise o status e SEM_ANALISE
    @Test
    void deveRetornarSemAnaliseQuandoNaoHaAnalise() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhao(List.of()));
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.empty());

        StatusSoloResponse resposta = statusSoloService.buscar("t1", "u1");

        assertEquals(StatusSolo.SEM_ANALISE, resposta.status());
        assertNull(resposta.dataAnalise());
    }

    // TESTE 2 - Usa a ultima analise e avisa quando nao ha cultura comercial
    @Test
    void deveUsarUltimaAnaliseEAvisarSemCulturaComercial() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhao(List.of()));
        when(culturaService.listar()).thenReturn(List.of(soja));
        when(analiseSoloRepository.findFirstByTalhaoIdOrderByDataColetaDesc("t1"))
                .thenReturn(Optional.of(new AnaliseSolo(
                        "a1", "u1", "p1", "t1",
                        LocalDate.of(2026, 10, 20),
                        6.0, 20.0, 1.5, 65.0, null)));

        StatusSoloResponse resposta = statusSoloService.buscar("t1", "u1");

        assertEquals(LocalDate.of(2026, 10, 20), resposta.dataAnalise());
        assertNotEquals(StatusSolo.SEM_ANALISE, resposta.status());
        assertNotNull(resposta.aviso());
    }

    // TESTE 3 - Talhao de outro usuario nao chega a consultar a analise
    @Test
    void naoDeveConsultarAnaliseDeTalhaoDeOutroUsuario() {

        when(talhaoService.buscarEntidade("t1", "intruso"))
                .thenThrow(new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.NOT_FOUND));

        assertThrows(org.springframework.web.server.ResponseStatusException.class,
                () -> statusSoloService.buscar("t1", "intruso"));
        verifyNoInteractions(analiseSoloRepository);
    }
}
