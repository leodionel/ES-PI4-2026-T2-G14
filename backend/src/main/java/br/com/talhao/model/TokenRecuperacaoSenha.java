
package br.com.talhao.model;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

// Armazena os dados necessários para recuperar
// a senha de um usuário.
@Document("tokens_recuperacao_senha")
public record TokenRecuperacaoSenha(

    @Id
    String id,

    // Identifica o usuário que solicitou a recuperação.
    String usuarioId,

    // Hash do token, nunca o token original.
    @Indexed(unique = true)
    String tokenHash,

    // Data e hora de criação do token.
    Instant criadoEm,

    // Data e hora em que o token deixa de ser válido.
    @Indexed(expireAfter = "0s")
    Instant expiraEm

) {}
