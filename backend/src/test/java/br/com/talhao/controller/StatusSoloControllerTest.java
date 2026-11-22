// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.service.StatusSoloService;

import static org.mockito.Mockito.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa a rota do status do solo
@WebMvcTest(StatusSoloController.class)
class StatusSoloControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private StatusSoloService statusSoloService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";
    private static final String AUTHORIZATION = "Bearer " + TOKEN;

    private void autenticarComoUsuario1() {

        Instant agora = Instant.now();

        when(jwtDecoder.decode(TOKEN)).thenReturn(new Jwt(
                TOKEN,
                agora,
                agora.plusSeconds(3600),
                Map.of("alg", "HS256"),
                Map.of("iss", "talhao-api", "sub", "u1")
        ));
    }

    // Sem token, a resposta e HTTP 401
    @Test
    void deveRetornar401SemToken() throws Exception {

        mockMvc.perform(get("/api/talhoes/t1/status-solo"))
                .andExpect(status().isUnauthorized());
    }

    // Retorna o status e os motivos do talhao do usuario
    @Test
    void deveRetornarStatusDoSolo() throws Exception {

        autenticarComoUsuario1();

        when(statusSoloService.buscar("t1", "u1"))
                .thenReturn(new StatusSoloResponse(
                        StatusSolo.ATENCAO, null, List.of(),
                        List.of("P (baixo)"), null));

        mockMvc.perform(get("/api/talhoes/t1/status-solo")
                .header("Authorization", AUTHORIZATION))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ATENCAO"))
                .andExpect(jsonPath("$.motivos[0]").value("P (baixo)"));
    }
}
