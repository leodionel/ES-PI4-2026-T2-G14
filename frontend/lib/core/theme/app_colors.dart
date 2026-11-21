import 'package:flutter/material.dart';

// Cores do guia do projeto
class AppColors {
  static const fundo = Color(0xFFFAF7F2);
  static const painel = Color(0xFFEDE4D3);
  static const verdeEscuro = Color(0xFF4A5D23);
  static const verde = Color(0xFF6B8E23);
  static const ambar = Color(0xFFC6902E);
  static const terracota = Color(0xFFB5533C);
  static const texto = Color(0xFF3A342B);
  static const textoSecundario = Color(0xFF7A7264);
  static const borda = Color(0xFFDDD2BB);

  // Status do solo (RN02): o mesmo código de cor em todas as telas.
  static const statusSaudavel = verde;
  static const statusAtencao = ambar;
  static const statusRisco = terracota;
  static const statusSemAnalise = textoSecundario;

  // Fundo suave dos itens selecionados e das áreas de destaque.
  static const selecao = Color(0xFFE6EBD9);
}
