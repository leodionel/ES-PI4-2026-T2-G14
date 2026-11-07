package br.com.talhao.model;

import java.time.LocalDate;

public record AnaliseSolo(String analiseId, LocalDate data, double ph, double fosforo,
                          double potassio, double saturacao, Double materiaOrganica) {}