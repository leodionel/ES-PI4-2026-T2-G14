package br.com.talhao.model;

import java.time.LocalDate;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

// Analise de solo de um talhao (colecao "analises_solo").
// Parametros: pH (CaCl2), fosforo (P resina, mg/dm3),
// potassio (K, mmolc/dm3) e saturacao por bases (V, %).
@Document(collection = "analises_solo")
@CompoundIndex(name = "talhao_data", def = "{'talhaoId': 1, 'dataColeta': -1}")
public record AnaliseSolo(

        @Id
        String id,

        @Indexed
        String usuarioId,

        @Indexed
        String propriedadeId,

        String talhaoId,

        LocalDate dataColeta,

        Double ph,
        Double fosforo,
        Double potassio,
        Double saturacaoBases,

        String observacoes
) {
}
