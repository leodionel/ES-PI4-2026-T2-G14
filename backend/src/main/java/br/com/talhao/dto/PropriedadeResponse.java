// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.dto;

// Dados da propriedade exibidos no perfil
public record PropriedadeResponse(

    // Identificador usado nas rotas de /api/propriedades
    String id,

    String nome,

    String localizacao

) {}
