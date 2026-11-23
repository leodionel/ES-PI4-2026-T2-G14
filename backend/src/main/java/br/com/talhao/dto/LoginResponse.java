// Contribuição: Matheus Rosini
// RA: 25015832

package br.com.talhao.dto;

public record LoginResponse(
    String token,
    UsuarioResponse usuario
) {
}