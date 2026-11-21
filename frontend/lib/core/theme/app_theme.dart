import 'package:flutter/material.dart';

import 'app_colors.dart';

// Tema usado em todas as telas
class AppTheme {
  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.fundo,
    fontFamily: 'Inter',

    // Cores dos componentes
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary: AppColors.verde,
      onPrimary: AppColors.fundo,
      secondary: AppColors.verdeEscuro,
      surface: AppColors.fundo,
      onSurface: AppColors.texto,
      error: AppColors.terracota,
    ),

    // Títulos e textos
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.verdeEscuro,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.verdeEscuro,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.verdeEscuro,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.texto,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.texto,
      ),
      bodyLarge: TextStyle(fontSize: 18, color: AppColors.texto),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.texto),
      bodySmall: TextStyle(fontSize: 16, color: AppColors.textoSecundario),
    ),

    // Aparência dos campos
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.painel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.texto),
      hintStyle: const TextStyle(color: AppColors.textoSecundario),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.verdeEscuro, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.terracota),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.terracota, width: 2),
      ),
      errorMaxLines: 3,
    ),

    // Botão principal
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.verde,
        foregroundColor: AppColors.fundo,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Barra superior das telas internas
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fundo,
      foregroundColor: AppColors.verdeEscuro,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.verdeEscuro,
      ),
    ),

    // Cartões: fundo do painel, borda fina e sem sombra
    cardTheme: CardThemeData(
      color: AppColors.painel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borda),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borda,
      thickness: 1,
      space: 1,
    ),

    // Botão secundário
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.verdeEscuro,
        side: const BorderSide(color: AppColors.verdeEscuro),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Janelas de diálogo
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.fundo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borda),
      ),
    ),

    // Avisos rápidos
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.verdeEscuro,
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: AppColors.fundo,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // Botões de texto, como criar conta e recuperar senha
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.verdeEscuro,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
