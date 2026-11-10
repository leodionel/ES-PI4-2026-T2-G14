package br.com.talhao.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;

// Dados recebidos para registrar a colheita de um plantio
public record ColheitaRequest(

    @NotNull(message = "A data de colheita é obrigatória")
    LocalDate dataColheita

) {}
