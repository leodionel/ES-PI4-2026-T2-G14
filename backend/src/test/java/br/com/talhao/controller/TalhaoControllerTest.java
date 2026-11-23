// Feito por Leonardo Dionel RA:25010092

// Contribuição: Matheus Rosini
// RA: 25015832


package br.com.talhao.controller;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CulturaAtualResponse;
import br.com.talhao.dto.TalhaoResumoResponse;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.service.TalhaoResumoService;
import br.com.talhao.service.TalhaoService;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas HTTP do TalhaoController.
@WebMvcTest(TalhaoController.class)
class TalhaoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private TalhaoService talhaoService;

    @MockitoBean
    private TalhaoResumoService talhaoResumoService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";
    private static final String AUTHORIZATION =
            "Bearer " + TOKEN;

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

    // Sem token, retorna HTTP 401.
    @Test
    void deveRetornar401SemToken() throws Exception {
        mockMvc.perform(get("/api/talhoes"))
                .andExpect(status().isUnauthorized());
    }

    // Com token, retorna a lista do usuario.
    @Test
    void deveListarTalhoesComToken() throws Exception {
        autenticarComoUsuario1();

        when(talhaoResumoService.listar("u1"))
                .thenReturn(List.of());

        mockMvc.perform(get("/api/talhoes")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());
    }

    // Valida o contrato da lista completa.
    @Test
    void deveListarComCulturaAtualEStatus() throws Exception {
        autenticarComoUsuario1();

        when(talhaoResumoService.listar("u1")).thenReturn(
                List.of(
                        new TalhaoResumoResponse(
                                "t1",
                                "Talhao Norte",
                                12.5,
                                Instant.parse(
                                        "2026-01-01T12:00:00Z"
                                ),
                                2,
                                3,
                                new CulturaAtualResponse(
                                        "pl1",
                                        "soja",
                                        "Soja",
                                        LocalDate.of(2026, 3, 1)
                                ),
                                StatusSolo.ATENCAO,
                                LocalDate.of(2026, 10, 20),
                                List.of("pH (acidez alta)")
                        ),
                        new TalhaoResumoResponse(
                                "t2",
                                "Talhao Novo",
                                4.0,
                                Instant.parse(
                                        "2026-01-02T12:00:00Z"
                                ),
                                0,
                                0,
                                null,
                                StatusSolo.SEM_ANALISE,
                                null,
                                List.of()
                        )
                )
        );

        mockMvc.perform(get("/api/talhoes")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value("t1"))
                .andExpect(jsonPath("$[0].totalPlantios")
                        .value(2))
                .andExpect(jsonPath("$[0].totalAnalises")
                        .value(3))
                .andExpect(jsonPath(
                        "$[0].culturaAtual.plantioId"
                ).value("pl1"))
                .andExpect(jsonPath(
                        "$[0].culturaAtual.nome"
                ).value("Soja"))
                .andExpect(jsonPath(
                        "$[0].culturaAtual.dataPlantio"
                ).value("2026-03-01"))
                .andExpect(jsonPath(
                        "$[0].statusSolo"
                ).value("ATENCAO"))
                .andExpect(jsonPath(
                        "$[0].dataAnalise"
                ).value("2026-10-20"))
                .andExpect(jsonPath(
                        "$[0].motivos[0]"
                ).value("pH (acidez alta)"))
                .andExpect(jsonPath(
                        "$[1].culturaAtual"
                ).doesNotExist())
                .andExpect(jsonPath(
                        "$[1].statusSolo"
                ).value("SEM_ANALISE"))
                .andExpect(jsonPath(
                        "$[1].motivos"
                ).isEmpty());
    }

    // Area negativa deve ser rejeitada.
    @Test
    void deveRejeitarAreaInvalida() throws Exception {
        autenticarComoUsuario1();

        mockMvc.perform(post("/api/talhoes")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "nome": "Talhão 04", "areaHa": -3 }
                    """))
                .andExpect(status().isBadRequest());
    }

    // Nome de confirmacao incorreto impede exclusao.
    @Test
    void deveRetornar400AoExcluirComNomeErrado()
            throws Exception {

        autenticarComoUsuario1();

        doThrow(new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "nome"
        )).when(talhaoService)
                .excluir("t1", "u1", "errado");

        mockMvc.perform(delete("/api/talhoes/t1")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "confirmacaoNome": "errado" }
                    """))
                .andExpect(status().isBadRequest());
    }
}
