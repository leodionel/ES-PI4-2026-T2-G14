
package br.com.talhao.config;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Map;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.controller.RelatorioController;
import br.com.talhao.service.RelatorioPdfService;

import static org.mockito.Mockito.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Testes de seguranca das rotas protegidas por JWT
@WebMvcTest(RelatorioController.class)
class JwtAuthInterceptorTest {

    @Autowired
    private MockMvc mockMvc;

    // Simula o componente que decodifica o JWT
    @MockitoBean
    private JwtDecoder jwtDecoder;

    // Simula o servico de relatorios
    @MockitoBean
    private RelatorioPdfService relatorioPdfService;

    private static final String URL =
            "/api/relatorios/propriedade/prop-1/pdf";

    // Cria um token JWT para os testes
    private Jwt criarJwt(
            String token,
            String usuarioId,
            String emissor) {

        Instant agora = Instant.now();

        return new Jwt(
                token,
                agora,
                agora.plusSeconds(3600),
                Map.of("alg", "HS256"),
                Map.of(
                        "iss", emissor,
                        "sub", usuarioId
                )
        );
    }

    // TESTE 1 - Bloquear formato de autenticacao incorreto
    @Test
    void deveBloquearAutenticacaoSemBearer() throws Exception {

        mockMvc.perform(
                get(URL)
                        .header(
                                "Authorization",
                                "Basic credenciais"
                        )
        )
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 2 - Bloquear JWT invalido
    @Test
    void deveBloquearJwtInvalido() throws Exception {

        when(jwtDecoder.decode("token-invalido"))
                .thenThrow(
                        new JwtException("Token invalido")
                );

        mockMvc.perform(
                get(URL)
                        .header(
                                "Authorization",
                                "Bearer token-invalido"
                        )
        )
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 3 - Bloquear JWT expirado
    @Test
    void deveBloquearJwtExpirado() throws Exception {

        // Simula a rejeicao de um token expirado
        // pelo componente de validacao JWT
        when(jwtDecoder.decode("token-expirado"))
                .thenThrow(
                        new JwtException("Token expirado")
                );

        mockMvc.perform(
                get(URL)
                        .header(
                                "Authorization",
                                "Bearer token-expirado"
                        )
        )
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 4 - Bloquear JWT de outro emissor
    @Test
    void deveBloquearJwtDeOutroEmissor() throws Exception {

        String token = "token-outro-emissor";

        Jwt jwt = criarJwt(
                token,
                "usuario-1",
                "outro-sistema"
        );

        when(jwtDecoder.decode(token))
                .thenReturn(jwt);

        mockMvc.perform(
                get(URL)
                        .header(
                                "Authorization",
                                "Bearer " + token
                        )
        )
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(relatorioPdfService);
    }

    // TESTE 5 - Permitir JWT valido e identificar usuario
    @Test
    void devePermitirJwtValido() throws Exception {

        String token = "token-valido";

        Jwt jwt = criarJwt(
                token,
                "usuario-1",
                "talhao-api"
        );

        when(jwtDecoder.decode(token))
                .thenReturn(jwt);

        // Simula os bytes do PDF
        byte[] pdf = "%PDF-1.4\nPDF de teste"
                .getBytes(StandardCharsets.US_ASCII);

        when(relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        )).thenReturn(pdf);

        mockMvc.perform(
                get(URL)
                        .header(
                                "Authorization",
                                "Bearer " + token
                        )
        )
                .andExpect(status().isOk())
                .andExpect(
                        content().contentType("application/pdf")
                )
                .andExpect(content().bytes(pdf));

        // Confirma que o ID foi extraido do JWT
        verify(relatorioPdfService).gerarRelatorio(
                "usuario-1",
                "prop-1"
        );
    }
}
