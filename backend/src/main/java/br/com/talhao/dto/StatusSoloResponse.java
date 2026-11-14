package br.com.talhao.dto;

import java.time.LocalDate;
import java.util.List;

import br.com.talhao.model.StatusSolo;

// Status do solo de um talhao e os parametros que o motivaram
public record StatusSoloResponse(

        StatusSolo status,

        // Data da analise usada (nula quando nao ha analise)
        LocalDate dataAnalise,

        // Todos os parametros avaliados
        List<IndicadorSolo> indicadores,

        // Parametros em classe critica ou de atencao, ex.: "pH (acidez alta)"
        List<String> motivos,

        // Observacao quando algum parametro nao entrou no status
        String aviso
) {}
