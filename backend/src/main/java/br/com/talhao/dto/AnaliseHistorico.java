// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.dto;

// Dados principais de uma analise de solo na linha do tempo
public record AnaliseHistorico(

    Double ph,
    Double fosforo,
    Double potassio,
    Double saturacaoBases,
    String observacoes

) {}
