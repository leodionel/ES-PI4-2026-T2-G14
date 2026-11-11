package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Recebe o token de recuperação e a nova senha.
public record RedefinirSenhaRequest(

    @NotBlank(message = "O token é obrigatório")
    String token,

    @NotBlank(message = "A nova senha é obrigatória")
    @Size(
        min = 8,
        max = 128,
        message = "A senha deve ter entre 8 e 128 caracteres"
    )
    String novaSenha

) {}
