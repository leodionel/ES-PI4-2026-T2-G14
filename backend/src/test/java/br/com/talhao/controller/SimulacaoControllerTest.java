// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.CenarioResponse;
import br.com.talhao.dto.SimulacaoResponse;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Classificacao;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.service.SimulacaoService;

import static org.mockito.Mockito.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa a rota de simulacao
@WebMvcTest(SimulacaoController.class)
class SimulacaoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SimulacaoService simulacaoService;

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

        mockMvc.perform(post("/api/talhoes/t1/simulacoes")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"culturaIds\":[\"soja\",\"milho\"]}"))
                .andExpect(status().isUnauthorized());
    }

    // Simulacao valida retorna HTTP 200 com os cenarios
    @Test
    void deveSimular() throws Exception {

        autenticarComoUsuario1();

        StatusSoloResponse solo = new StatusSoloResponse(
                StatusSolo.SAUDAVEL, null, List.of(), List.of(), null);

        when(simulacaoService.simular("t1", "u1", List.of("milho", "soja")))
                .thenReturn(new SimulacaoResponse(
                        "t1", solo, List.of("Soja"),
                        List.of(
                                new CenarioResponse("milho", "Milho",
                                        Classificacao.RECOMENDADO, List.of()),
                                new CenarioResponse("soja", "Soja",
                                        Classificacao.NAO_RECOMENDADO, List.of())),
                        false, null, "aviso"));

        mockMvc.perform(post("/api/talhoes/t1/simulacoes")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"culturaIds\":[\"milho\",\"soja\"]}"))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cenarios[0].classificacao").value("RECOMENDADO"))
                .andExpect(jsonPath("$.cenarios[1].classificacao").value("NAO_RECOMENDADO"))
                .andExpect(jsonPath("$.opcoesEquivalentes").value(false));
    }

    // Uma cultura so (ou quatro) e recusada antes de chegar ao service
    @Test
    void deveRecusarQuantidadeInvalidaDeCulturas() throws Exception {

        autenticarComoUsuario1();

        for (String corpo : new String[] {
                "{\"culturaIds\":[\"soja\"]}",
                "{\"culturaIds\":[\"a\",\"b\",\"c\",\"d\"]}",
                "{}"}) {

            mockMvc.perform(post("/api/talhoes/t1/simulacoes")
                    .header("Authorization", AUTHORIZATION)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(corpo))
                    .andExpect(status().isBadRequest());
        }

        verifyNoInteractions(simulacaoService);
    }
}
