package br.com.talhao.controller;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.PlantioResponse;
import br.com.talhao.service.PlantioService;

import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas HTTP do PlantioController
@WebMvcTest(PlantioController.class)
class PlantioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PlantioService plantioService;

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

        mockMvc.perform(get("/api/talhoes/t1/plantios"))
                .andExpect(status().isUnauthorized());
    }

    // TESTE 2 - Registra um plantio e retorna HTTP 201
    @Test
    void deveRegistrarPlantio() throws Exception {

        autenticarComoUsuario1();
        when(plantioService.registrar(
                "t1", "u1", "soja", LocalDate.of(2026, 11, 15)))
                .thenReturn(new PlantioResponse(
                        "pl1", "soja", "Soja",
                        LocalDate.of(2026, 11, 15), null));

        mockMvc.perform(post("/api/talhoes/t1/plantios")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "culturaId": "soja", "dataPlantio": "2026-11-15" }
                    """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.plantioId").value("pl1"))
                .andExpect(jsonPath("$.culturaNome").value("Soja"));
    }

    // TESTE 3 - Plantio sem cultura e rejeitado pela validacao
    @Test
    void deveRejeitarPlantioSemCultura() throws Exception {

        autenticarComoUsuario1();

        mockMvc.perform(post("/api/talhoes/t1/plantios")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "dataPlantio": "2026-11-15" }
                    """))
                .andExpect(status().isBadRequest());
    }

    // TESTE 4 - Registra a colheita e retorna HTTP 200
    @Test
    void deveRegistrarColheita() throws Exception {

        autenticarComoUsuario1();
        when(plantioService.registrarColheita(
                "t1", "pl1", "u1", LocalDate.of(2027, 3, 20)))
                .thenReturn(new PlantioResponse(
                        "pl1", "soja", "Soja",
                        LocalDate.of(2026, 11, 15),
                        LocalDate.of(2027, 3, 20)));

        mockMvc.perform(put("/api/talhoes/t1/plantios/pl1/colheita")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "dataColheita": "2027-03-20" }
                    """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dataColheita").value("2027-03-20"));
    }
}
