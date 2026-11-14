package br.com.talhao.dto;

import java.util.List;

import br.com.talhao.model.Efeito;
import br.com.talhao.model.FonteTecnica;

// Regra de rotacao acionada em um cenario, com a mensagem e as fontes
public record RegraAplicada(
        String regraId,
        Efeito efeito,
        String mensagem,
        List<FonteTecnica> fontes
) {}
