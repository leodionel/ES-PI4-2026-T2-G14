// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.model;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

// Pedido de recuperacao de senha em andamento (RF03).
// Cada usuario tem no maximo um pedido por vez.
// O Mongo apaga o documento sozinho depois de expiraEm.
@Document("recuperacoes_senha")
public record RecuperacaoSenha(
        @Id String id,
        @Indexed(unique = true) String usuarioId,
        String codigoHash,                       // hash, nunca o codigo
        @Indexed(expireAfter = "0s") Instant expiraEm,
        int tentativas) {}
