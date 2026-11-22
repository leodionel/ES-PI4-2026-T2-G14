package br.com.talhao.dto;

import jakarta.validation.constraints.*;

public record RedefinirSenhaRequest(
        @NotBlank @Email String email,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{32}") String codigo,
        @NotBlank @Size(min = 8, max = 128) String novaSenha) {}
