package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

// Cultura do catalogo fixo do sistema (carregado no inicio da aplicacao)
@Document("culturas")
public record Cultura(

    // Identificador fixo: "soja", "feijao", "milho"
    @Id String id,

    String nome,
    String nomeCientifico,
    String familia,
    Grupo grupo,
    TipoUso tipoUso,

    // Nulo para culturas de cobertura
    GrupoP grupoP

) {}
