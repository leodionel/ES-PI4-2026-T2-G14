package br.com.talhao.dto;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

// Culturas que o produtor quer comparar como proxima safra
public record SimulacaoRequest(

        @NotNull(message = "Informe as culturas da simulacao")
        @Size(min = 2, max = 3, message = "Informe de 2 a 3 culturas")
        List<@NotBlank(message = "A cultura nao pode ser vazia") String> culturaIds
) {}
