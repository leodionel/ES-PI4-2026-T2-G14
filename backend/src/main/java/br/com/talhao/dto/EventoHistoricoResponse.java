// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.dto;

import java.time.LocalDate;

// Um evento da linha do tempo do talhao.
// Os campos que nao se aplicam ao tipo do evento vem nulos:
//  - PLANTIO e COLHEITA: culturaId e culturaNome; analise nulo
//  - ANALISE_SOLO: analise; culturaId e culturaNome nulos
public record EventoHistoricoResponse(

    TipoEventoHistorico tipo,
    LocalDate data,

    // plantioId (PLANTIO e COLHEITA) ou id da analise (ANALISE_SOLO)
    String referenciaId,

    String culturaId,
    String culturaNome,
    AnaliseHistorico analise

) {}
