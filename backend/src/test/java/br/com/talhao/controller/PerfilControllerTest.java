// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import java.time.Instant;
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

import br.com.talhao.dto.AtualizacaoPerfilRequest;
import br.com.talhao.dto.PerfilResponse;
import br.com.talhao.dto.PropriedadeResponse;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.service.PerfilService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as rotas HTTP do PerfilController
@WebMvcTest(PerfilController.class)
class PerfilControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PerfilService perfilService;

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

    private PerfilResponse criarPerfil(String nome, String telefone) {

        return new PerfilResponse(
                new UsuarioResponse(
                        "u1",
                        nome,
                        "maria@email.com",
                        telefone,
                        Instant.parse("2026-01-10T12:00:00Z")
                ),
                new PropriedadeResponse(
                        "p1", "Sitio Boa Vista", "Campinas - SP")
        );
    }

    // TESTE 1 - Sem token, as duas rotas retornam 401
    @Test
    void deveExigirTokenNasDuasRotas() throws Exception {

        mockMvc.perform(get("/api/usuarios/me"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(put("/api/usuarios/me")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"nome\":\"Maria\",\"telefone\":\"19999999999\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(perfilService);
    }

    // TESTE 2 - O perfil e buscado pelo usuario do token
    @Test
    void deveRetornarOPerfilDoUsuarioDoToken() throws Exception {

        autenticarComoUsuario1();
        when(perfilService.buscar("u1"))
                .thenReturn(criarPerfil("Maria Silva", "19999999999"));

        mockMvc.perform(get("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.id").value("u1"))
                .andExpect(jsonPath("$.usuario.nome").value("Maria Silva"))
                .andExpect(jsonPath("$.usuario.email")
                        .value("maria@email.com"))
                .andExpect(jsonPath("$.usuario.criadoEm").exists())
                .andExpect(jsonPath("$.propriedade.id").value("p1"))
                .andExpect(jsonPath("$.propriedade.localizacao")
                        .value("Campinas - SP"))
                // Nenhum dado de senha sai da API
                .andExpect(content().string(
                        org.hamcrest.Matchers.not(
                                org.hamcrest.Matchers.containsString("senha"))));
    }

    // TESTE 3 - Perfil sem propriedade devolve null
    @Test
    void devePermitirPerfilSemPropriedade() throws Exception {

        autenticarComoUsuario1();
        when(perfilService.buscar("u1"))
                .thenReturn(new PerfilResponse(
                        criarPerfil("Maria Silva", "19999999999").usuario(),
                        null));

        mockMvc.perform(get("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.propriedade").doesNotExist())
                .andExpect(jsonPath("$.usuario.id").value("u1"));
    }

    // TESTE 4 - Atualiza nome e telefone do usuario do token
    @Test
    void deveAtualizarOPerfil() throws Exception {

        autenticarComoUsuario1();
        when(perfilService.atualizar(
                org.mockito.ArgumentMatchers.eq("u1"),
                any(AtualizacaoPerfilRequest.class)))
                .thenReturn(criarPerfil("Maria Souza", "1933334444"));

        mockMvc.perform(put("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nome":"Maria Souza","telefone":"1933334444"}
                    """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuario.nome").value("Maria Souza"))
                .andExpect(jsonPath("$.usuario.telefone")
                        .value("1933334444"));

        verify(perfilService).atualizar(
                "u1",
                new AtualizacaoPerfilRequest("Maria Souza", "1933334444"));
    }

    // TESTE 5 - O e-mail enviado no corpo e ignorado
    @Test
    void deveIgnorarEmailEnviadoNoCorpo() throws Exception {

        autenticarComoUsuario1();
        when(perfilService.atualizar(
                org.mockito.ArgumentMatchers.eq("u1"),
                any(AtualizacaoPerfilRequest.class)))
                .thenReturn(criarPerfil("Maria Souza", "1933334444"));

        mockMvc.perform(put("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nome":"Maria Souza","telefone":"1933334444",
                     "email":"outro@email.com","id":"u2"}
                    """))
                .andExpect(status().isOk());

        verify(perfilService).atualizar(
                "u1",
                new AtualizacaoPerfilRequest("Maria Souza", "1933334444"));
    }

    // TESTE 6 - Telefone invalido e rejeitado com o campo indicado
    @Test
    void deveRejeitarTelefoneInvalido() throws Exception {

        autenticarComoUsuario1();

        mockMvc.perform(put("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nome":"Maria Souza","telefone":"123"}
                    """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos.telefone").exists());

        verifyNoInteractions(perfilService);
    }

    // TESTE 7 - Nome em branco e rejeitado
    @Test
    void deveRejeitarNomeEmBranco() throws Exception {

        autenticarComoUsuario1();

        mockMvc.perform(put("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"nome":"   ","telefone":"19999999999"}
                    """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos.nome").exists());

        verifyNoInteractions(perfilService);
    }

    // TESTE 8 - Usuario que nao existe mais recebe 401
    @Test
    void deveRepassar401QuandoAContaNaoExisteMais() throws Exception {

        autenticarComoUsuario1();
        when(perfilService.buscar("u1"))
                .thenThrow(new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Sessão inválida"));

        mockMvc.perform(get("/api/usuarios/me")
                .header("Authorization", AUTHORIZATION))
                .andExpect(status().isUnauthorized());
    }
}
