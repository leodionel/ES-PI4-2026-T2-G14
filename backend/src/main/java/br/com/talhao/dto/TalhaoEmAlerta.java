package br.com.talhao.dto;

import java.time.LocalDate;
import java.util.List;

import br.com.talhao.model.StatusSolo;

// Talhao que precisa de atencao e o que motivou o status
public record TalhaoEmAlerta(

    String talhaoId,

    String nome,

    double areaHa,

    // RISCO ou ATENCAO
    StatusSolo status,

    // Data da analise usada no status
    LocalDate dataAnalise,

    // Parametros que motivaram o status, ex.: "pH (acidez alta)"
    List<String> motivos

) {}
