package br.com.talhao.dto;

import java.time.LocalDate;

// Plantio enviado ao frontend, ja com o nome da cultura
public record PlantioResponse(

    String plantioId,
    String culturaId,
    String culturaNome,
    LocalDate dataPlantio,

    // Nulo enquanto o plantio estiver aberto
    LocalDate dataColheita

) {}
