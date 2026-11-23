package br.com.talhao.controller;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.RecuperacaoSenhaResponse;
import br.com.talhao.service.RecuperacaoSenhaService;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas abertas de recuperacao de senha
@WebMvcTest(RecuperacaoSenhaController.class)
class RecuperacaoSenhaControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private RecuperacaoSenhaService recuperacaoSenhaService;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    // TESTE 1 - O pedido e aberto (sem token) e devolve a mensagem e o codigo
    @Test
    void devePedirCodigoSemToken() throws Exception {

        when(recuperacaoSenhaService.solicitar("joao@email.com"))
                .thenReturn(new RecuperacaoSenhaResponse("ok", "123456"));

        mockMvc.perform(post("/api/usuarios/recuperar-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"joao@email.com\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mensagem").value("ok"))
                .andExpect(jsonPath("$.codigoSimulado").value("123456"));
    }

    // TESTE 2 - E-mail invalido: 400 e o service nao e chamado
    @Test
    void deveRecusarEmailInvalido() throws Exception {

        mockMvc.perform(post("/api/usuarios/recuperar-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"isso-nao-e-email\"}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(recuperacaoSenhaService);
    }

    // TESTE 3 - A troca de senha responde 204
    @Test
    void deveTrocarASenha() throws Exception {

        mockMvc.perform(post("/api/usuarios/redefinir-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"joao@email.com\","
                        + "\"codigo\":\"123456\","
                        + "\"novaSenha\":\"NovaSenha1\"}"))
                .andExpect(status().isNoContent());

        verify(recuperacaoSenhaService)
                .redefinir("joao@email.com", "123456", "NovaSenha1");
    }

    // TESTE 4 - Codigo fora do formato ou senha curta: 400
    @Test
    void deveRecusarCodigoOuSenhaForaDoFormato() throws Exception {

        mockMvc.perform(post("/api/usuarios/redefinir-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"joao@email.com\","
                        + "\"codigo\":\"12345\","
                        + "\"novaSenha\":\"NovaSenha1\"}"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(post("/api/usuarios/redefinir-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"joao@email.com\","
                        + "\"codigo\":\"123456\","
                        + "\"novaSenha\":\"curta\"}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(recuperacaoSenhaService);
    }

    // TESTE 5 - Codigo invalido ou expirado vira 400 com a mensagem
    @Test
    void deveRetornar400QuandoOCodigoNaoVale() throws Exception {

        doThrow(new ResponseStatusException(
                HttpStatus.BAD_REQUEST, "Código inválido ou expirado."))
                .when(recuperacaoSenhaService)
                .redefinir(anyString(), anyString(), anyString());

        mockMvc.perform(post("/api/usuarios/redefinir-senha")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"joao@email.com\","
                        + "\"codigo\":\"123456\","
                        + "\"novaSenha\":\"NovaSenha1\"}"))
                .andExpect(status().isBadRequest());
    }
}
