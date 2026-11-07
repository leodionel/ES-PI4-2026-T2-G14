
package br.com.talhao.exception;

import java.time.Instant;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
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

import br.com.talhao.controller.AnaliseSoloController;
import br.com.talhao.service.AnaliseSoloService;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;

import static org.mockito.Mockito.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa as respostas de erro da API
@WebMvcTest(AnaliseSoloController.class)
class GlobalExceptionHandlerTest {

    @Autowired
    private MockMvc mockMvc;

    // Simula o servico de analises de solo
    @MockitoBean
    private AnaliseSoloService analiseSoloService;

    // Simula a validacao do token JWT
    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";

    // Configura um usuario autenticado antes de cada teste
    @BeforeEach
    void configurarAutenticacao() {

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

    // TESTE 1
    // Verifica o retorno de HTTP 400 quando o DTO
    // possui um campo invalido
    @Test
    void deveRetornarErroDeValidacao() throws Exception {

        String json = """
                {
                    "propriedadeId": "prop-1",
                    "talhaoId": "talhao-1",
                    "dataColeta": "2026-10-20",
                    "ph": 17.0,
                    "fosforo": 12.0,
                    "potassio": 4.0,
                    "materiaOrganica": 2.5,
                    "observacoes": "Teste"
                }
                """;

        mockMvc.perform(
                post("/api/analises-solo")
                        .header(
                                "Authorization",
                                "Bearer " + TOKEN
                        )
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json)
        )
                // Confirma o codigo HTTP 400
                .andExpect(status().isBadRequest())

                // Confirma o formato atual de erro da API
                .andExpect(jsonPath("$.erro")
                        .value("Dados inválidos"))

                // Confirma que o campo ph foi identificado
                .andExpect(jsonPath("$.campos.ph").exists());

        // Dados invalidos nao devem chegar ao service
        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 2
    // Verifica o retorno de HTTP 400 quando o JSON
    // enviado possui sintaxe invalida
    @Test
    void deveRetornarErroParaJsonInvalido() throws Exception {

        String jsonInvalido = """
                {
                    "propriedadeId":
                """;

        mockMvc.perform(
                post("/api/analises-solo")
                        .header(
                                "Authorization",
                                "Bearer " + TOKEN
                        )
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonInvalido)
        )
                // Confirma o codigo HTTP 400
                .andExpect(status().isBadRequest())

                // Confirma que a API retorna uma
                // mensagem explicando o erro
                .andExpect(jsonPath("$.erro").isString());

        // JSON invalido nao deve chegar ao service
        verifyNoInteractions(analiseSoloService);
    }

    // TESTE 3
    // Verifica o retorno HTTP 404 quando uma
    // analise nao existe
    @Test
    void deveRetornarErroQuandoAnaliseNaoExiste()
            throws Exception {

        when(analiseSoloService.buscarPorId(
                "analise-inexistente",
                "usuario-1"
        )).thenThrow(
                new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Analise nao encontrada"
                )
        );

        mockMvc.perform(
                get("/api/analises-solo/analise-inexistente")
                        .header(
                                "Authorization",
                                "Bearer " + TOKEN
                        )
        )
                // Confirma o codigo HTTP 404
                .andExpect(status().isNotFound())

                // Confirma o status no corpo da resposta
                .andExpect(jsonPath("$.status").value(404));

        verify(analiseSoloService).buscarPorId(
                "analise-inexistente",
                "usuario-1"
        );
    }

    // TESTE 4
    // Verifica se erros internos retornam HTTP 500
    // sem expor informacoes internas ao cliente
    @Test
    void deveOcultarDetalhesDeErroInterno()
            throws Exception {

        // Simula uma falha interna com uma mensagem
        // que nao deve aparecer na resposta ao Flutter
        when(analiseSoloService.buscarPorId(
                "analise-1",
                "usuario-1"
        )).thenThrow(
                new IllegalStateException(
                        "segredo-interno-do-servidor"
                )
        );

        mockMvc.perform(
                get("/api/analises-solo/analise-1")
                        .header(
                                "Authorization",
                                "Bearer " + TOKEN
                        )
        )
                // Confirma o codigo HTTP 500
                .andExpect(status().isInternalServerError())

                // Confirma a resposta padronizada
                .andExpect(jsonPath("$.status").value(500))

                .andExpect(jsonPath("$.title")
                        .value("Erro interno do servidor"))

                .andExpect(jsonPath("$.detail")
                        .value(
                                "Ocorreu um erro interno. Tente novamente."
                        ))

                // Impede que a mensagem interna seja
                // enviada na resposta HTTP
                .andExpect(content().string(
                        not(containsString(
                                "segredo-interno-do-servidor"
                        ))
                ));

        verify(analiseSoloService).buscarPorId(
                "analise-1",
                "usuario-1"
        );
    }
}
