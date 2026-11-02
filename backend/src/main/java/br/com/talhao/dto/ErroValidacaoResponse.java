package br.com.talhao.dto;

import java.util.Map;

//Resposta enviada quando os dados recebidos estao invalidos
public record ErroValidacaoResponse(

    //Mensagem geral do erro
    String mensagem,

    //Nome do campo e o motivo da validacao
    Map<String, String> campos
) {
}