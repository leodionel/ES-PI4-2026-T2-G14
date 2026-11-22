// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.time.Duration;
import java.time.Instant;
import java.util.Base64;

import javax.crypto.SecretKey;

import org.junit.jupiter.api.Test;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;

import br.com.talhao.config.JwtConfig;

import static org.junit.jupiter.api.Assertions.*;

// Testa a geracao do token com o mesmo encoder e decoder da aplicacao
class JwtServiceTest {

    private static final String SEGREDO = Base64.getEncoder()
            .encodeToString("chave-de-teste-com-32-bytes-ok!!".getBytes());

    private final JwtConfig config = new JwtConfig();
    private final SecretKey chave = config.jwtSecretKey(SEGREDO);
    private final JwtEncoder encoder = config.jwtEncoder(chave);
    private final JwtDecoder decoder = config.jwtDecoder(chave);
    private final JwtService jwtService = new JwtService(encoder);

    // TESTE 1 - O token carrega o usuario e o emissor
    @Test
    void deveGerarTokenComUsuarioEEmissor() {

        Jwt jwt = decoder.decode(jwtService.gerarToken("u1"));

        assertEquals("u1", jwt.getSubject());
        assertEquals("talhao-api", jwt.getClaimAsString("iss"));
    }

    // TESTE 2 - O token vale por duas horas
    @Test
    void deveGerarTokenValidoPorDuasHoras() {

        Jwt jwt = decoder.decode(jwtService.gerarToken("u1"));

        Duration validade = Duration.between(
                jwt.getIssuedAt(), jwt.getExpiresAt());

        assertEquals(Duration.ofHours(2), validade);
        assertTrue(jwt.getExpiresAt().isAfter(Instant.now()));
    }

    // TESTE 3 - Token assinado com outra chave e recusado
    @Test
    void deveRecusarTokenAssinadoComOutraChave() {

        String outro = Base64.getEncoder()
                .encodeToString("outra-chave-com-32-bytes-ok!!!!!".getBytes());
        JwtConfig outraConfig = new JwtConfig();
        JwtService servicoDeOutraChave = new JwtService(
                outraConfig.jwtEncoder(outraConfig.jwtSecretKey(outro)));

        String token = servicoDeOutraChave.gerarToken("u1");

        assertThrows(Exception.class, () -> decoder.decode(token));
    }

    // TESTE 4 - Segredo curto impede a aplicacao de subir
    @Test
    void deveRecusarSegredoCurto() {

        String curto = Base64.getEncoder().encodeToString("curta".getBytes());

        assertThrows(IllegalStateException.class,
                () -> config.jwtSecretKey(curto));
    }
}
