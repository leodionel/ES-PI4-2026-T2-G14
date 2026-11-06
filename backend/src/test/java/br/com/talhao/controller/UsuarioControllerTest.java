
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
import static org.mockito.Mockito.verifyNoInteractions;

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

    // TESTE 1 - Cadastro deve retornar HTTP 201
    @Test
    void deveCadastrarUsuario() throws Exception {

        // Cria a resposta simulada do usuario
        UsuarioResponse resposta = new UsuarioResponse(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                Instant.now()
        );

        // Simula o retorno do Service
        when(usuarioService.cadastrar(any(CadastroUsuarioRequest.class)))
                .thenReturn(resposta);

        // Envia uma requisicao POST para cadastro
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

                // Verifica se retornou HTTP 201
                .andExpect(status().isCreated())

                // Verifica os dados retornados
                .andExpect(jsonPath("$.id").value("123"))
                .andExpect(jsonPath("$.email").value("joao@email.com"));
    }

    // TESTE 2 - Login deve retornar HTTP 200
    @Test
    void deveRealizarLogin() throws Exception {

        // Cria a resposta simulada do usuario
        UsuarioResponse resposta = new UsuarioResponse(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                Instant.now()
        );

        // Simula o retorno do Service
        when(usuarioService.login(any(LoginRequest.class)))
                .thenReturn(resposta);

        // Envia uma requisicao POST para login
        mockMvc.perform(post("/api/usuarios/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "email": "joao@email.com",
                        "senha": "Senha123"
                    }
                    """))

                // Verifica se retornou HTTP 200
                .andExpect(status().isOk())

                // Verifica os dados retornados
                .andExpect(jsonPath("$.id").value("123"))
                .andExpect(jsonPath("$.nome").value("Joao"));
    }

    // TESTE 3 - Login com email invalido
    @Test
    void deveRecusarLoginComEmailInvalido() throws Exception {

        // Envia um email que nao segue o formato correto
        mockMvc.perform(post("/api/usuarios/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "email": "email-invalido",
                        "senha": "Senha123"
                    }
                    """))

                // Espera HTTP 400 - Bad Request
                .andExpect(status().isBadRequest());

        // O Service nao deve ser chamado
        verifyNoInteractions(usuarioService);
    }

    // TESTE 4 - Login com senha vazia
    @Test
    void deveRecusarLoginComSenhaVazia() throws Exception {

        // Envia uma senha vazia
        mockMvc.perform(post("/api/usuarios/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "email": "joao@email.com",
                        "senha": ""
                    }
                    """))

                // Espera HTTP 400 - Bad Request
                .andExpect(status().isBadRequest());

        // O Service nao deve ser chamado
        verifyNoInteractions(usuarioService);
    }

    // TESTE 5 - Cadastro sem nome
    @Test
    void deveRecusarCadastroSemNome() throws Exception {

        // Envia um cadastro com o nome vazio
        mockMvc.perform(post("/api/usuarios/cadastro")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                        "nome": "",
                        "email": "joao@email.com",
                        "telefone": "19999999999",
                        "senha": "Senha123"
                    }
                    """))

                // Espera HTTP 400 - Bad Request
                .andExpect(status().isBadRequest());

        // O Service nao deve ser chamado
        verifyNoInteractions(usuarioService);
    }
}
