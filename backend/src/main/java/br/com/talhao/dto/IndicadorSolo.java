package br.com.talhao.dto;

import br.com.talhao.model.Tratamento;

// Um parametro da analise ja classificado (valor arredondado como na tabela)
public record IndicadorSolo(
        String parametro,
        double valor,
        String unidade,
        String classe,
        Tratamento tratamento
) {}
