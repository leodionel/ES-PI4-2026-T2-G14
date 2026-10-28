import 'package:flutter/material.dart';

// Tela inicial do aplicativo
import 'telas/dashboard.dart';
import 'core/theme/app_theme.dart';

// Configuração principal do app
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Tira a faixa de debug do canto
      debugShowCheckedModeBanner: false,

      title: 'Pay4 · Prontuário Digital do Talhão',

      // Primeira tela ao abrir o app
      theme: AppTheme.claro,
      home: const Dashboard(),
    );
  }
}
