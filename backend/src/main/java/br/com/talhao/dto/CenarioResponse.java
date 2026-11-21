package br.com.talhao.dto;

import java.util.List;

import br.com.talhao.model.Classificacao;

// Resultado da simulacao para uma cultura candidata
public record CenarioResponse(
        String culturaId,
        String culturaNome,
        Classificacao classificacao,
        List<RegraAplicada> regras
) {}
