package br.com.talhao.dto;

public record LoginResponse(
    String token,
    UsuarioResponse usuario
) {
}