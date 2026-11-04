package br.com.talhao.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

//Recebe o email do produtor quando ele solicita a recuperação de senha
public record RecuperacaoSenhaRequest(

    // E-mail cadastrado nos sistema
    @NotBlank (message = "O e-mail é obrigatório")
    @Email(message = "Informe um e-mail válido")
    String email
){}