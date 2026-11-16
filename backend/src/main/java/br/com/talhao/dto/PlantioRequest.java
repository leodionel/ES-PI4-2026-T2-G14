package br.com.talhao.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

// Dados recebidos para registrar o plantio de uma cultura
public record PlantioRequest(

    @NotBlank(message = "A cultura é obrigatória")
    String culturaId,

    @NotNull(message = "A data de plantio é obrigatória")
    LocalDate dataPlantio

) {}
