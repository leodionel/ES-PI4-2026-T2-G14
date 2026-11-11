package br.com.talhao.dto;

import java.time.Instant;

//Representa os dados do usuário que serão enviados pelo back pro front
public record UsuarioResponse(

    //Identificador do usuário no MongoDB
    String id,

    //Nome completo do produtor
    String nome,

    //E-mail cadastrado no sistema
    String email,

    //Telefone do produtor
    String telefone,

    //Data e horário de criacão da conta
    Instant criadoEm

){}