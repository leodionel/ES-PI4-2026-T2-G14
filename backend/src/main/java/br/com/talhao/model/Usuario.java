package br.com.talhao.model;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("usuarios")
public record Usuario(
        @Id String id,
        String nome,
        @Indexed(unique = true) String email,   // gravar em minúsculas
        String telefone,
        String senhaHash,                        // hash, nunca a senha (RNF03)
        Instant criadoEm) {}