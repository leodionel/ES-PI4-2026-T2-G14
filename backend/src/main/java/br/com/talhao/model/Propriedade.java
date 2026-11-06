package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("propriedades")
public record Propriedade(
        @Id String id,
        @Indexed String usuarioId,
        String nome,
        String localizacao) {}