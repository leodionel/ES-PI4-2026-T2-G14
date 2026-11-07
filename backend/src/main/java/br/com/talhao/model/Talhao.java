package br.com.talhao.model;

import java.time.Instant;
import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("talhoes")
public record Talhao(
        @Id String id,
        @Indexed String propriedadeId,
        String nome,
        double areaHa,
        Instant criadoEm,
        List<Plantio> plantios,
        List<AnaliseSolo> analises) {

    public Talhao {                              // $push falha se o campo for null
        plantios = plantios == null ? List.of() : plantios;
        analises = analises == null ? List.of() : analises;
    }
}