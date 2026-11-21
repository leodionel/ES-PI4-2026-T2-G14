package br.com.talhao.dto;

import java.time.Instant;

import br.com.talhao.model.StatusSolo;

// Item da lista de talhoes (RF07).
// Tem os mesmos campos de TalhaoResponse mais a cultura atual e o status.
public record TalhaoResumoResponse(

    String id,
    String nome,
    double areaHa,
    Instant criadoEm,

    // Quantidade de safras registradas no talhao
    int totalPlantios,

    // Quantidade de analises de solo registradas no talhao
    int totalAnalises,

    // Nulo quando o talhao nao tem cultura plantada
    CulturaAtualResponse culturaAtual,

    // Status do solo pela ultima analise
    StatusSolo statusSolo

) {}
