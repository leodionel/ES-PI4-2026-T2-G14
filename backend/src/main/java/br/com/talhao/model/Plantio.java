package br.com.talhao.model;

import java.time.LocalDate;

public record Plantio(String plantioId, String culturaId, LocalDate dataPlantio, LocalDate dataColheita) {}