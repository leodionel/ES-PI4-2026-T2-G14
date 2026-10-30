package br.com.talhao.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// Dados recebidos pela API para cadastrar um usuario
public record CadastroUsuarioRequest(

    // Nome precisa ter algum texto
    @NotBlank(message = "Informe seu nome.")
    String nome,

    // Confere se o email foi preenchido e tem formato valido
    @NotBlank(message = "Informe seu e-mail.")
    @Email(message = "Informe um e-mail válido.")
    String email,

    // Telefone deve chegar apenas com os numeros, incluindo DDD
    @NotBlank (message = "Informe seu telefone.")
    @Pattern (
        regexp = "\\d{10,11}",
        message = "Informe um telefone com DDD."
    )
    String telefone,

    //Aplica a mesma regra de tamanho usada no cadastro do app
    @NotBlank (message = "Informe sua senha.")
    @Size(
        min = 8,
        message = "A senha deve ter pelo menos 8 caracteres."
    )
    String senha 
) {
}