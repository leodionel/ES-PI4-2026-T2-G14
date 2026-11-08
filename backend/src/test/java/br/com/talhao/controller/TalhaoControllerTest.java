package br.com.talhao.controller;

import java.util.List;

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

import br.com.talhao.service.TalhaoService;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas HTTP do TalhaoController
@WebMvcTest(TalhaoController.class)
class TalhaoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private TalhaoService talhaoService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    // Simula um token valido do usuario u1
    private void autenticarComoUsuario1() {
        Jwt jwt = Jwt.withTokenValue("abc")
                .header("alg", "HS256")
                .subject("u1")
                .build();
        when(jwtDecoder.decode("abc")).thenReturn(jwt);
    }

    // TESTE 1 - Sem token, a resposta e HTTP 401
    @Test
    void deveRetornar401SemToken() throws Exception {

        mockMvc.perform(get("/api/talhoes"))
                .andExpect(status().isUnauthorized());
    }

    // TESTE 2 - Com token, a lista do usuario e retornada
    @Test
    void deveListarTalhoesComToken() throws Exception {

        autenticarComoUsuario1();
        when(talhaoService.listar("u1")).thenReturn(List.of());

        mockMvc.perform(get("/api/talhoes")
                .header("Authorization", "Bearer abc"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());
    }

    // TESTE 3 - Area negativa e rejeitada pela validacao
    @Test
    void deveRejeitarAreaInvalida() throws Exception {

        autenticarComoUsuario1();

        mockMvc.perform(post("/api/talhoes")
                .header("Authorization", "Bearer abc")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "nome": "Talhão 04", "areaHa": -3 }
                    """))
                .andExpect(status().isBadRequest());
    }

    // TESTE 4 - Exclusao com nome errado retorna HTTP 400
    @Test
    void deveRetornar400AoExcluirComNomeErrado() throws Exception {

        autenticarComoUsuario1();
        doThrow(new ResponseStatusException(HttpStatus.BAD_REQUEST, "nome"))
                .when(talhaoService).excluir("t1", "u1", "errado");

        mockMvc.perform(delete("/api/talhoes/t1")
                .header("Authorization", "Bearer abc")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    { "confirmacaoNome": "errado" }
                    """))
                .andExpect(status().isBadRequest());
    }
}
