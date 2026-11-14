
package br.com.talhao.controller;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.dto.CadastroAnaliseSoloRequest;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.service.AnaliseSoloService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verifyNoInteractions;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa os endpoints HTTP de analises de solo
@WebMvcTest(AnaliseSoloController.class)
class AnaliseSoloControllerTest {

    @Autowired
    private MockMvc mockMvc;

    // Simula o Service, sem acessar o MongoDB
    @MockitoBean
    private AnaliseSoloService analiseSoloService;

    // Simula a validacao do JWT
    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";
    private static final String AUTHORIZATION = "Bearer " + TOKEN;

    // Configura um JWT valido para o usuario de teste
    private void configurarJwtValido() {

        Instant agora = Instant.now();

        Jwt jwt = new Jwt(
                TOKEN,
                agora,
                agora.plusSeconds(3600),
                Map.of("alg", "HS256"),
                Map.of(
                        "iss", "talhao-api",
                        "sub", "usuario-1"
                )
        );

        when(jwtDecoder.decode(TOKEN)).thenReturn(jwt);
    }

    // Cria uma analise simulada
    private AnaliseSolo criarAnalise() {

        return new AnaliseSolo(
                "analise-1",
                "usuario-1",
                "propriedade-1",
                "talhao-1",
                LocalDate.of(2026, 10, 20),
                5.8,
                12.0,
                4.0,
                60.0,
                "Amostra de teste"
        );
    }

    // JSON valido utilizado nos testes
    private String dadosValidos() {

        return """
                {
                    "propriedadeId": "propriedade-1",
                    "talhaoId": "talhao-1",
                    "dataColeta": "2026-10-20",
                    "ph": 5.8,
                    "fosforo": 12.0,
                    "potassio": 4.0,
                    "saturacaoBases": 60.0,
                    "observacoes": "Amostra de teste"
                }
                """;
    }

    // TESTE 1 - Bloquear acesso sem JWT
    @Test
    void deveBloquearAcessoSemToken() throws Exception {

        mockMvc.perform(get("/api/analises-solo"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 2 - Bloquear JWT invalido
    @Test
    void deveBloquearTokenInvalido() throws Exception {

        when(jwtDecoder.decode("token-invalido"))
                .thenThrow(new JwtException("Token invalido"));

        mockMvc.perform(get("/api/analises-solo")
                .header("Authorization", "Bearer token-invalido"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 3 - Cadastrar analise de solo
    @Test
    void deveCadastrarAnaliseSolo() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.cadastrar(
                eq("usuario-1"),
                any(CadastroAnaliseSoloRequest.class)
        )).thenReturn(criarAnalise());

        mockMvc.perform(post("/api/analises-solo")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content(dadosValidos()))

                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value("analise-1"))
                .andExpect(jsonPath("$.usuarioId").value("usuario-1"))
                .andExpect(jsonPath("$.propriedadeId").value("propriedade-1"))
                .andExpect(jsonPath("$.talhaoId").value("talhao-1"))
                .andExpect(jsonPath("$.ph").value(5.8));
    }

    // TESTE 4 - Recusar pH fora do intervalo permitido
    @Test
    void deveRecusarPhInvalido() throws Exception {

        configurarJwtValido();

        String dadosInvalidos = """
                {
                    "propriedadeId": "propriedade-1",
                    "talhaoId": "talhao-1",
                    "dataColeta": "2026-10-20",
                    "ph": 15.0,
                    "fosforo": 12.0,
                    "potassio": 4.0,
                    "saturacaoBases": 60.0
                }
                """;

        mockMvc.perform(post("/api/analises-solo")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content(dadosInvalidos))

                .andExpect(status().isBadRequest());

        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 4B - Recusar analise sem V% e com V% acima de 100
    @Test
    void deveRecusarSaturacaoAusenteOuInvalida() throws Exception {

        configurarJwtValido();

        String semV = """
                {
                    "propriedadeId": "propriedade-1",
                    "talhaoId": "talhao-1",
                    "dataColeta": "2026-10-20",
                    "ph": 5.8,
                    "fosforo": 12.0,
                    "potassio": 4.0
                }
                """;

        String vAcimaDe100 = semV.replace(
                "\"potassio\": 4.0",
                "\"potassio\": 4.0, \"saturacaoBases\": 101.0"
        );

        for (String corpo : new String[] {semV, vAcimaDe100}) {
            mockMvc.perform(post("/api/analises-solo")
                    .header("Authorization", AUTHORIZATION)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(corpo))

                    .andExpect(status().isBadRequest());
        }

        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 5 - Listar analises do usuario
    @Test
    void deveListarAnalisesDoUsuario() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.listarPorUsuario("usuario-1"))
                .thenReturn(List.of(criarAnalise()));

        mockMvc.perform(get("/api/analises-solo")
                .header("Authorization", AUTHORIZATION))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value("analise-1"))
                .andExpect(jsonPath("$[0].usuarioId").value("usuario-1"));
    }

    // TESTE 6 - Listar analises de uma propriedade
    @Test
    void deveListarPorPropriedade() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.listarPorPropriedade(
                "usuario-1",
                "propriedade-1"
        )).thenReturn(List.of(criarAnalise()));

        mockMvc.perform(get(
                "/api/analises-solo/propriedade/propriedade-1"
        ).header("Authorization", AUTHORIZATION))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].propriedadeId")
                        .value("propriedade-1"));
    }

    // TESTE 7 - Listar historico de um talhao
    @Test
    void deveListarPorTalhao() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.listarPorTalhao(
                "usuario-1",
                "propriedade-1",
                "talhao-1"
        )).thenReturn(List.of(criarAnalise()));

        mockMvc.perform(get(
                "/api/analises-solo/propriedade/propriedade-1/talhao/talhao-1"
        ).header("Authorization", AUTHORIZATION))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].talhaoId")
                        .value("talhao-1"));
    }

    // TESTE 8 - Buscar analise pelo ID
    @Test
    void deveBuscarAnalisePorId() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.buscarPorId(
                "analise-1",
                "usuario-1"
        )).thenReturn(criarAnalise());

        mockMvc.perform(get("/api/analises-solo/analise-1")
                .header("Authorization", AUTHORIZATION))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("analise-1"))
                .andExpect(jsonPath("$.ph").value(5.8));
    }

    // TESTE 9 - Atualizar analise de solo
    @Test
    void deveAtualizarAnaliseSolo() throws Exception {

        configurarJwtValido();

        when(analiseSoloService.atualizar(
                eq("analise-1"),
                eq("usuario-1"),
                any(CadastroAnaliseSoloRequest.class)
        )).thenReturn(criarAnalise());

        mockMvc.perform(put("/api/analises-solo/analise-1")
                .header("Authorization", AUTHORIZATION)
                .contentType(MediaType.APPLICATION_JSON)
                .content(dadosValidos()))

                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("analise-1"))
                .andExpect(jsonPath("$.usuarioId").value("usuario-1"));
    }

    // TESTE 10 - Excluir analise de solo
    @Test
    void deveExcluirAnaliseSolo() throws Exception {

        configurarJwtValido();

        mockMvc.perform(delete("/api/analises-solo/analise-1")
                .header("Authorization", AUTHORIZATION))

                .andExpect(status().isNoContent());
    }
}
