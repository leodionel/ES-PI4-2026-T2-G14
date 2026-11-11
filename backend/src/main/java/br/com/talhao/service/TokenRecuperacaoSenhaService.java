package br.com.talhao.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.TokenRecuperacaoSenha;
import br.com.talhao.repository.TokenRecuperacaoSenhaRepository;

@Service
public class TokenRecuperacaoSenhaService {

    private static final Duration VALIDADE = Duration.ofMinutes(15);

    private static final SecureRandom RANDOM = new SecureRandom();

    private final TokenRecuperacaoSenhaRepository repository;
    private final MongoTemplate mongoTemplate;

    public TokenRecuperacaoSenhaService(
            TokenRecuperacaoSenhaRepository repository,
            MongoTemplate mongoTemplate) {

        this.repository = repository;
        this.mongoTemplate = mongoTemplate;
    }

    // Gera um token de recuperação para determinado usuário.
    public String gerarToken(String usuarioId) {

        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);

        String token = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);

        String tokenHash = calcularHash(token);

        Instant agora = Instant.now();

        // Invalida tokens anteriores do usuário.
        repository.deleteByUsuarioId(usuarioId);

        TokenRecuperacaoSenha recuperacao =
                new TokenRecuperacaoSenha(
                        null,
                        usuarioId,
                        tokenHash,
                        agora,
                        agora.plus(VALIDADE)
                );

        repository.save(recuperacao);

        // O token original não deve ser salvo no MongoDB.
        return token;
    }

    // Valida e consome o token em uma única operação.
    // Isso impede que duas solicitações utilizem
    // o mesmo token ao mesmo tempo.
    public String consumirToken(String token) {

        if (token == null || token.isBlank()) {
            throw tokenInvalido();
        }

        String tokenHash = calcularHash(token);

        Query consulta = new Query(
                Criteria.where("tokenHash")
                        .is(tokenHash)
                        .and("expiraEm")
                        .gt(Instant.now())
        );

        // Busca e remove o token de forma atômica.
        TokenRecuperacaoSenha recuperacao =
                mongoTemplate.findAndRemove(
                        consulta,
                        TokenRecuperacaoSenha.class
                );

        if (recuperacao == null) {
            throw tokenInvalido();
        }

        // Retorna o usuário associado ao token válido.
        return recuperacao.usuarioId();
    }

    // Calcula o hash SHA-256.
    private String calcularHash(String token) {
        try {
            MessageDigest digest =
                    MessageDigest.getInstance("SHA-256");

            byte[] hash = digest.digest(
                    token.getBytes(StandardCharsets.UTF_8)
            );

            return HexFormat.of().formatHex(hash);

        } catch (NoSuchAlgorithmException erro) {
            throw new IllegalStateException(
                    "Erro ao calcular o hash do token.",
                    erro
            );
        }
    }

    // Resposta para tokens inválidos, expirados ou utilizados.
    private ResponseStatusException tokenInvalido() {
        return new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Link de recuperação inválido ou expirado."
        );
    }
}
