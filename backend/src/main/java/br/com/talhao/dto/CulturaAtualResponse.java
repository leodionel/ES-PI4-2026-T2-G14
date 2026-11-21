package br.com.talhao.dto;

import java.time.LocalDate;

// Cultura que esta plantada no talhao agora
public record CulturaAtualResponse(

    // Identifica o plantio, usado para registrar a colheita
    String plantioId,

    String culturaId,

    // Nome da cultura no catalogo, ex.: "Soja"
    String nome,

    LocalDate dataPlantio

) {}
