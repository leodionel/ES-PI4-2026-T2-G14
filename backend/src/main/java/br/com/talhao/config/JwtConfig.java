
package br.com.talhao.config;

import java.util.Base64;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

// Configura a assinatura e a validacao de tokens JWT
@Configuration
public class JwtConfig {

    // Cria a chave secreta usada pelos tokens
    @Bean
    public SecretKey jwtSecretKey(
            @Value("${JWT_SECRET_BASE64:}") String segredoBase64) {

        // Impede iniciar a autenticacao sem uma chave
        if (segredoBase64 == null || segredoBase64.isBlank()) {
            throw new IllegalStateException(
                    "A variavel JWT_SECRET_BASE64 nao foi configurada"
            );
        }

        byte[] chaveBytes;

        try {
            // Converte a chave de Base64 para bytes
            chaveBytes = Base64.getDecoder().decode(segredoBase64);
        } catch (IllegalArgumentException erro) {
            throw new IllegalStateException(
                    "JWT_SECRET_BASE64 deve conter um Base64 valido",
                    erro
            );
        }

        // HS256 exige uma chave com pelo menos 256 bits
        if (chaveBytes.length < 32) {
            throw new IllegalStateException(
                    "A chave JWT deve possuir pelo menos 32 bytes"
            );
        }

        // Cria a chave criptografica para HMAC-SHA256
        return new SecretKeySpec(chaveBytes, "HmacSHA256");
    }

    // Responsavel por gerar e assinar os tokens JWT
    @Bean
    public JwtEncoder jwtEncoder(SecretKey jwtSecretKey) {

        return NimbusJwtEncoder
                .withSecretKey(jwtSecretKey)
                .algorithm(MacAlgorithm.HS256)
                .build();
    }

    // Responsavel por validar a assinatura dos tokens JWT
    @Bean
    public JwtDecoder jwtDecoder(SecretKey jwtSecretKey) {

        return NimbusJwtDecoder
                .withSecretKey(jwtSecretKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
    }
}
