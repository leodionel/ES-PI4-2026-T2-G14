package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;

// Nome digitado pelo usuario para confirmar a exclusao do talhao
public record ExclusaoTalhaoRequest(

    @NotBlank(message = "Digite o nome do talhão para confirmar")
    String confirmacaoNome

) {}
