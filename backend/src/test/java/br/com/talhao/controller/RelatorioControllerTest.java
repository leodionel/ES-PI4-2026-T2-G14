
package br.com.talhao.controller;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.service.RelatorioPdfService;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testa os endpoints de relatorios PDF
@WebMvcTest(RelatorioController.class)
class RelatorioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    // Simula o servico de geracao de PDF
    @MockitoBean
    private RelatorioPdfService relatorioPdfService;

    // Simula a validacao dos tokens JWT
    @MockitoBean
    private JwtDecoder jwtDecoder;

    private static final String TOKEN = "token-teste";

    // Configura um JWT valido para o usuario informado
    private void configurarJwtValido(String usuarioId) {

        Instant agora = Instant.now();

        Jwt jwt = new Jwt(
                TOKEN,
                agora,
                agora.plusSeconds(3600),
                Map.of("alg", "HS256"),
                Map.of(
                        "iss", "talhao-api",
                        "sub", usuarioId
                )
        );

        when(jwtDecoder.decode(TOKEN)).thenReturn(jwt);
    }

    // TESTE 1 - Bloquear download sem JWT
    @Test
    void deveBloquearDownloadSemToken() throws Exception {

        mockMvc.perform(get(
                "/api/relatorios/propriedade/prop-1/pdf"
        ))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 2 - Bloquear token invalido
    @Test
    void deveBloquearTokenInvalido() throws Exception {

        when(jwtDecoder.decode("token-invalido"))
                .thenThrow(new JwtException("Token invalido"));

        mockMvc.perform(get(
                "/api/relatorios/propriedade/prop-1/pdf"
        ).header("Authorization", "Bearer token-invalido"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 3 - Retornar o arquivo PDF
    @Test
    void deveBaixarRelatorioPdf() throws Exception {

        configurarJwtValido("usuario-1");

        // Simula os bytes retornados pelo servico
        byte[] pdf = "%PDF-1.4\narquivo-teste"
                .getBytes(StandardCharsets.US_ASCII);

        when(relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        )).thenReturn(pdf);

        mockMvc.perform(get(
                "/api/relatorios/propriedade/prop-1/pdf"
        ).header("Authorization", "Bearer " + TOKEN))

                .andExpect(status().isOk())
                .andExpect(content().contentType("application/pdf"))
                .andExpect(header().string(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"relatorio-propriedade.pdf\""
                ))
                .andExpect(content().bytes(pdf));

        verify(relatorioPdfService).gerarRelatorio(
                "usuario-1",
                "prop-1"
        );
    }

    // TESTE 4 - Bloquear relatorio de outro usuario
    @Test
    void deveBloquearRelatorioDeOutroUsuario() throws Exception {

        configurarJwtValido("usuario-2");

        // Simula a propriedade inacessivel ao usuario
        when(relatorioPdfService.gerarRelatorio(
                "usuario-2",
                "prop-1"
        )).thenThrow(new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "Propriedade nao encontrada"
        ));

        mockMvc.perform(get(
                "/api/relatorios/propriedade/prop-1/pdf"
        ).header("Authorization", "Bearer " + TOKEN))

                .andExpect(status().isNotFound());

        verify(relatorioPdfService).gerarRelatorio(
                "usuario-2",
                "prop-1"
        );
    }
}
