package br.com.talhao.model;

// Fonte tecnica citada por uma regra (url pode ser nula)
public record FonteTecnica(
    String id, String titulo, String url
) {}
