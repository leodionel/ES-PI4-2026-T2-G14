
package br.com.talhao.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import br.com.talhao.model.StatusSolo;

// Resumo completo do talhao para lista e dashboard (RF07).
// As regras agronomicas sao calculadas no backend.
public record TalhaoResumoResponse(
    String id,
    String nome,
    double areaHa,
    Instant criadoEm,
    int totalPlantios,
    int totalAnalises,
    CulturaAtualResponse culturaAtual,
    StatusSolo statusSolo,
    LocalDate dataAnalise,
    List<String> motivos
) {}
