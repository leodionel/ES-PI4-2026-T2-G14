package br.com.talhao.dto;

import br.com.talhao.model.StatusSolo;

// Quantos talhoes estao em cada status do solo
public record DistribuicaoStatus(

    StatusSolo status,

    int quantidade

) {}
