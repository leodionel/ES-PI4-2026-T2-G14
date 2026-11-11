
package br.com.talhao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Representa os dados recebidos para cadastrar
// ou atualizar uma propriedade rural.
public record CadastroPropriedadeRequest(

    // Nome obrigatorio da propriedade
    @NotBlank(message = "O nome da propriedade e obrigatorio")
    @Size(
        max = 150,
        message = "O nome deve ter no maximo 150 caracteres"
    )
    String nome,

    // Localizacao obrigatoria da propriedade
    @NotBlank(message = "A localizacao e obrigatoria")
    @Size(
        max = 255,
        message = "A localizacao deve ter no maximo 255 caracteres"
    )
    String localizacao

) {}
