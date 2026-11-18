package br.com.talhao.dto;

// Dados da tela de perfil: o usuario e a propriedade dele.
// A propriedade e null enquanto o produtor ainda nao cadastrou uma.
public record PerfilResponse(

    UsuarioResponse usuario,

    PropriedadeResponse propriedade

) {}
