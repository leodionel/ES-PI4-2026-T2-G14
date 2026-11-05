
package br.com.talhao.controller;

import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.CadastroUsuarioRequest;
import br.com.talhao.dto.LoginRequest;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.service.UsuarioService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas HTTP do UsuarioController
@WebMvcTest(UsuarioController.class)
class UsuarioControllerTest {

    // Simula requisicoes HTTP sem iniciar um servidor real
    @Autowired
    private MockMvc mockMvc;

    // Simula o UsuarioService
    @MockitoBean
    private UsuarioService usuarioService;

    // Teste 1: cadastro deve retornar HTTP 201
    @Test
    void deveCadastrarUsuario() throws Exception {

        UsuarioResponse resposta = new UsuarioResponse(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                Instant.now()
        );

        when(usuarioService.cadastrar(any(CadastroUsuarioRequest.class)))
                .thenReturn(resposta);

        mockMvc.perform(post("/api/usuarios/cadastro")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "nome": "Joao",
                        "email": "joao@email.com",
                        "telefone": "19999999999",
                        "senha": "Senha123"
                    }
                    """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value("123"))
                .andExpect(jsonPath("$.email").value("joao@email.com"));
    }

    // Teste 2: login deve retornar HTTP 200
    @Test
    void deveRealizarLogin() throws Exception {

        UsuarioResponse resposta = new UsuarioResponse(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                Instant.now()
        );

        when(usuarioService.login(any(LoginRequest.class)))
                .thenReturn(resposta);

        mockMvc.perform(post("/api/usuarios/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "email": "joao@email.com",
                        "senha": "Senha123"
                    }
                    """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("123"))
                .andExpect(jsonPath("$.nome").value("Joao"));
    }
}
