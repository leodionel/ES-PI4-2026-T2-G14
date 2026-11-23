// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

// Resposta do pedido de recuperacao de senha.
// A mensagem e sempre a mesma, exista o e-mail ou nao.
// O codigo so vai na resposta no modo simulado (sem envio de e-mail).
@JsonInclude(JsonInclude.Include.NON_NULL)
public record RecuperacaoSenhaResponse(
        String mensagem,
        String codigoSimulado) {}
