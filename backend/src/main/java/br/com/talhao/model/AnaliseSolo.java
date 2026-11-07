package br.com.talhao.model;

import java.time.LocalDate;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

//Representa uma analise de solo cadastrada no MongoDB
@Document (collection = "analises_solo")
public record AnaliseSolo(

    //Identificador unico da analise
    @Id 
    String id,

    //Usuario responsavel pela analise 
    @Indexed 
    String usuarioId,

    //Propriedade onde a analise foi realizada
    @Indexed 
    String propriedadeId,

    //Talhao relacionado a analise
    String talhaoId,

    //Data em que o solo foi coletado
    LocalDate dataColeta,

    //Potencial hidrogenionico do solo
    Double ph,

    //Quantidade de fosforo
    Double fosforo,

    //Quantidade de potassio 
    Double potassio,

    //Teor de materia organica
    Double materiaOrganica,

    //Informacoes adicionais da analise
    String observacoes
) {
}