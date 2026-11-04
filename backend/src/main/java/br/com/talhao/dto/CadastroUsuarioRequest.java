package br.com.talhao.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

//Recebe os dados enviados pelo frontend
//quando um produtor cria uma conta
public record CadastroUsuarioRequest(

    //Nome completo do produtor
    @NotBlank(message = "O nome é obrigatório")
    @Size(
        min = 3,
        max = 120,
        message = "O nome deve ter entre 3 e 120 caracteres"
    )
    String nome,

    //E-mail utilizado para acessar o sistema
    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "Informe um e-mail válido")
    String email,

    // Telefone com DDD
    @NotBlank(message = "O telefone é obrigatório")
    @Pattern(
        regexp = "\\d{10,11}",
        message = "Informe um telefone com DDD válido"
    )
    String telefone,

    // Senha de acesso ao sistema
     @NotBlank(message = "A senha é obrigatória")
     @Size(
        min = 8,
        max = 128,
        message = "A senha deve ter entre 8 e 128 caracteres"
     )
     String senha

){}