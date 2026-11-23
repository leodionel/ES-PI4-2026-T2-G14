// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.AnaliseHistorico;
import br.com.talhao.dto.EventoHistoricoResponse;
import br.com.talhao.dto.TipoEventoHistorico;
import br.com.talhao.service.HistoricoTalhaoService;

import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa a rota da linha do tempo do talhao
@WebMvcTest(HistoricoTalhaoController.class)
class HistoricoTalhaoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private HistoricoTalhaoService historicoTalhaoService;

    // Simula a validacao do JWT feita pelo interceptor
    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";
    private static final String AUTHORIZATION = "Bearer " + TOKEN;

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
    void deveRetornar401SemToken() throws Exception {

        mockMvc.perform(get("/api/talhoes/t1/historico"))
                .andExpect(status().isUnauthorized());
    }

    // TESTE 2 - Devolve os eventos com tipo, data e dados principais
    @Test
    void deveDevolverAsLinhasDoTempo() throws Exception {

        autenticarComoUsuario1();
        when(historicoTalhaoService.montar("t1", "u1")).thenReturn(List.of(
                new EventoHistoricoResponse(
                        TipoEventoHistorico.PLANTIO,
                        LocalDate.of(2026, 3, 1),
                        "pl1", "soja", "Soja", null),
                new EventoHistoricoResponse(
                        TipoEventoHistorico.ANALISE_SOLO,
                        LocalDate.of(2026, 4, 1),
                        "a1", null, null,
                        new AnaliseHistorico(5.5, 12.0, 2.5, 60.0, null))
        ));

        mockMvc.perform(get("/api/talhoes/t1/historico")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].tipo").value("PLANTIO"))
                .andExpect(jsonPath("$[0].data").value("2026-03-01"))
                .andExpect(jsonPath("$[0].referenciaId").value("pl1"))
                .andExpect(jsonPath("$[0].culturaNome").value("Soja"))
                .andExpect(jsonPath("$[0].analise").doesNotExist())
                .andExpect(jsonPath("$[1].tipo").value("ANALISE_SOLO"))
                .andExpect(jsonPath("$[1].analise.ph").value(5.5))
                .andExpect(jsonPath("$[1].analise.saturacaoBases").value(60.0));
    }

    // TESTE 3 - Talhao inexistente ou de outro usuario: HTTP 404
    @Test
    void deveRetornar404QuandoOTalhaoNaoExiste() throws Exception {

        autenticarComoUsuario1();
        when(historicoTalhaoService.montar("t9", "u1"))
                .thenThrow(new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Talhao nao encontrado"));

        mockMvc.perform(get("/api/talhoes/t9/historico")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isNotFound());
    }
}
