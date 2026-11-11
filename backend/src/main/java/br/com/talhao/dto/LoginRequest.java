package br.com.talhao.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

// Recebe os dados enviados pelo frontend quando o produtor realiza o login
public record LoginRequest(

    // E-mail utilizado para acessar o sistema
    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "Informe um e-mail válido")
    String email,

    // Senha de acesso do produtor
    @NotBlank(message = "A senha é obrigatória")
    String senha

) {}
