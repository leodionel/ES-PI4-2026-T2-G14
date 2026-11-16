
package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// Dados permitidos para editar o perfil.
public record AtualizarPerfilRequest(

        @NotBlank(message = "O nome é obrigatório")
        @Size(
                min = 3,
                max = 120,
                message = "O nome deve ter entre 3 e 120 caracteres"
        )
        String nome,

        @NotBlank(message = "O telefone é obrigatório")
        @Pattern(
                regexp = "\\d{10,11}",
                message = "Informe um telefone com DDD válido"
        )
        String telefone

) {}
