package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

// Dados recebidos para cadastrar ou editar um talhao
public record TalhaoRequest(

    // Nome obrigatorio do talhao
    @NotBlank(message = "O nome do talhão é obrigatório")
    @Size(
        max = 100,
        message = "O nome deve ter no máximo 100 caracteres"
    )
    String nome,

    // Area em hectares, maior que zero
    @NotNull(message = "A área é obrigatória")
    @Positive(message = "A área deve ser maior que zero")
    Double areaHa

) {}
