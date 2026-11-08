
package br.com.talhao.model;

import java.time.LocalDate;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

// Representa uma analise de solo cadastrada no MongoDB
@Document(collection = "analises_solo")
public record AnaliseSolo(

        // Identificador da analise
        @Id
        String id,

        // Usuario responsavel
        @Indexed
        String usuarioId,

        // Propriedade vinculada
        @Indexed
        String propriedadeId,

        // Talhao relacionado
        String talhaoId,

        // Data da coleta
        LocalDate dataColeta,

        // Indicadores do solo
        Double ph,
        Double fosforo,
        Double potassio,
        Double materiaOrganica,

        // Informacoes adicionais
        String observacoes,

        // Campos do modelo de historico de talhoes
        String analiseId,
        LocalDate data,
        Double saturacao

) {

    // Construtor utilizado pela API de analises de solo
    public AnaliseSolo(
            String id,
            String usuarioId,
            String propriedadeId,
            String talhaoId,
            LocalDate dataColeta,
            Double ph,
            Double fosforo,
            Double potassio,
            Double materiaOrganica,
            String observacoes) {

        this(
                id,
                usuarioId,
                propriedadeId,
                talhaoId,
                dataColeta,
                ph,
                fosforo,
                potassio,
                materiaOrganica,
                observacoes,
                null,
                null,
                null
        );
    }

    // Construtor utilizado pelo historico de talhoes
    // com materia organica
    public AnaliseSolo(
            String analiseId,
            LocalDate data,
            double ph,
            double fosforo,
            double potassio,
            double saturacao,
            Double materiaOrganica) {

        this(
                null,
                null,
                null,
                null,
                data,
                ph,
                fosforo,
                potassio,
                materiaOrganica,
                null,
                analiseId,
                data,
                saturacao
        );
    }

    // Construtor utilizado pelos testes do TalhaoService
    // quando nao ha materia organica informada
    public AnaliseSolo(
            String analiseId,
            LocalDate data,
            double ph,
            double fosforo,
            double potassio,
            double saturacao) {

        this(
                analiseId,
                data,
                ph,
                fosforo,
                potassio,
                saturacao,
                null
        );
    }
}
