// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// Dados pessoais que o produtor pode alterar no perfil.
// O e-mail nao entra aqui porque e o login da conta.
public record AtualizacaoPerfilRequest(

    // Nome completo do produtor
    @NotBlank(message = "O nome é obrigatório")
    @Size(
        min = 3,
        max = 120,
        message = "O nome deve ter entre 3 e 120 caracteres"
    )
    String nome,

    // Telefone com DDD, somente numeros
    @NotBlank(message = "O telefone é obrigatório")
    @Pattern(
        regexp = "\\d{10,11}",
        message = "Informe um telefone com DDD válido"
    )
    String telefone

) {}
