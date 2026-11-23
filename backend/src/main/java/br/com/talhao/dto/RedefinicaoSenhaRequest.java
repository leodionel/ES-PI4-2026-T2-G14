package br.com.talhao.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// Recebe o codigo recebido e a nova senha do produtor
public record RedefinicaoSenhaRequest(

    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "Informe um e-mail válido")
    String email,

    // Codigo de 6 digitos
    @NotBlank(message = "O código é obrigatório")
    @Pattern(
        regexp = "\\d{6}",
        message = "O código tem 6 dígitos"
    )
    String codigo,

    // Mesma regra da senha do cadastro
    @NotBlank(message = "A senha é obrigatória")
    @Size(
        min = 8,
        max = 128,
        message = "A senha deve ter entre 8 e 128 caracteres"
    )
    String novaSenha
){}
