package br.com.talhao.dto;

import java.time.Instant;

// Dados do talhao enviados ao frontend.
// As contagens alimentam o aviso exibido antes da exclusao.
public record TalhaoResponse(

    String id,
    String nome,
    double areaHa,
    Instant criadoEm,

    // Quantidade de safras registradas no talhao
    int totalPlantios,

    // Quantidade de analises de solo registradas no talhao
    int totalAnalises

) {}
