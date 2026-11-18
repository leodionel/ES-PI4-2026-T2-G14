package br.com.talhao.controller;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.DashboardResponse;
import br.com.talhao.dto.DistribuicaoStatus;
import br.com.talhao.dto.TalhaoEmAlerta;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.service.DashboardService;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa a rota HTTP do DashboardController
@WebMvcTest(DashboardController.class)
class DashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private DashboardService dashboardService;

    // Simula a validacao do JWT feita pelo interceptor
    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";
    private static final String AUTHORIZATION = "Bearer " + TOKEN;

    // Configura um JWT valido para o usuario u1
    private void autenticarComoUsuario1() {

        Instant agora = Instant.now();

        Jwt jwt = new Jwt(
                TOKEN,
                agora,
                agora.plusSeconds(3600),
                Map.of("alg", "HS256"),
                Map.of("iss", "talhao-api", "sub", "u1")
        );

        when(jwtDecoder.decode(TOKEN)).thenReturn(jwt);
    }

    // TESTE 1 - Sem token, a resposta e HTTP 401
    @Test
    void deveExigirToken() throws Exception {

        mockMvc.perform(get("/api/dashboard"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(dashboardService);
    }

    // TESTE 2 - O resumo e montado para o usuario do token
    @Test
    void deveRetornarOResumoDoUsuarioDoToken() throws Exception {

        autenticarComoUsuario1();
        when(dashboardService.montar("u1")).thenReturn(new DashboardResponse(
                "Sitio Boa Vista",
                3,
                42.5,
                List.of(
                        new DistribuicaoStatus(StatusSolo.RISCO, 1),
                        new DistribuicaoStatus(StatusSolo.ATENCAO, 0),
                        new DistribuicaoStatus(StatusSolo.SAUDAVEL, 1),
                        new DistribuicaoStatus(StatusSolo.SEM_ANALISE, 1)),
                List.of(new TalhaoEmAlerta(
                        "t1",
                        "Talhao 04",
                        20.0,
                        StatusSolo.RISCO,
                        LocalDate.of(2026, 1, 10),
                        List.of("pH (acidez muito alta)")))
        ));

        mockMvc.perform(get("/api/dashboard")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.propriedadeNome")
                        .value("Sitio Boa Vista"))
                .andExpect(jsonPath("$.totalTalhoes").value(3))
                .andExpect(jsonPath("$.areaTotalHa").value(42.5))
                .andExpect(jsonPath("$.distribuicao.length()").value(4))
                .andExpect(jsonPath("$.distribuicao[0].status").value("RISCO"))
                .andExpect(jsonPath("$.distribuicao[0].quantidade").value(1))
                .andExpect(jsonPath("$.distribuicao[3].status")
                        .value("SEM_ANALISE"))
                .andExpect(jsonPath("$.talhoesEmAlerta[0].talhaoId")
                        .value("t1"))
                .andExpect(jsonPath("$.talhoesEmAlerta[0].status")
                        .value("RISCO"))
                .andExpect(jsonPath("$.talhoesEmAlerta[0].dataAnalise")
                        .value("2026-01-10"))
                .andExpect(jsonPath("$.talhoesEmAlerta[0].motivos[0]")
                        .value("pH (acidez muito alta)"));

        verify(dashboardService).montar("u1");
    }

    // TESTE 3 - Dashboard vazio tem listas vazias, nao nulas
    @Test
    void deveRetornarListasVaziasQuandoNaoHaTalhoes() throws Exception {

        autenticarComoUsuario1();
        when(dashboardService.montar("u1")).thenReturn(new DashboardResponse(
                null,
                0,
                0.0,
                List.of(
                        new DistribuicaoStatus(StatusSolo.RISCO, 0),
                        new DistribuicaoStatus(StatusSolo.ATENCAO, 0),
                        new DistribuicaoStatus(StatusSolo.SAUDAVEL, 0),
                        new DistribuicaoStatus(StatusSolo.SEM_ANALISE, 0)),
                List.of()
        ));

        mockMvc.perform(get("/api/dashboard")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalTalhoes").value(0))
                .andExpect(jsonPath("$.talhoesEmAlerta").isArray())
                .andExpect(jsonPath("$.talhoesEmAlerta").isEmpty());
    }
}
