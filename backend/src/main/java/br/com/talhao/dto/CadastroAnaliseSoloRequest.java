
package br.com.talhao.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

// Dados recebidos pela API para cadastrar uma analise de solo
public record CadastroAnaliseSoloRequest(

        // Identificador da propriedade
        @NotBlank(message = "A propriedade e obrigatoria")
        String propriedadeId,

        // Identificador do talhao
        @NotBlank(message = "O talhao e obrigatorio")
        String talhaoId,

        // Data em que a amostra de solo foi coletada
        @NotNull(message = "A data de coleta e obrigatoria")
        @PastOrPresent(message = "A data de coleta nao pode ser futura")
        LocalDate dataColeta,

        // pH do solo: valor entre 0 e 14
        @NotNull(message = "O pH e obrigatorio")
        @DecimalMin(
                value = "0.0",
                message = "O pH nao pode ser negativo"
        )
        @DecimalMax(
                value = "14.0",
                message = "O pH nao pode ser maior que 14"
        )
        Double ph,

        // Teor de fosforo
        @PositiveOrZero(
                message = "O fosforo nao pode ser negativo"
        )
        Double fosforo,

        // Teor de potassio
        @PositiveOrZero(
                message = "O potassio nao pode ser negativo"
        )
        Double potassio,

        // Teor de materia organica
        @PositiveOrZero(
                message = "A materia organica nao pode ser negativa"
        )
        Double materiaOrganica,

        // Observacoes complementares
        @Size(
                max = 1000,
                message = "As observacoes devem ter no maximo 1000 caracteres"
        )
        String observacoes

) {
}
