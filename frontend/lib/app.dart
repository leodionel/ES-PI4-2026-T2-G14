import 'package:flutter/material.dart';


// Tela de login
import 'telas/login.dart';

// Configuração principal do app
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Tira a faixa de debug do canto
      debugShowCheckedModeBanner: false,

      title: 'Prontuário Digital do Talhão',

      // Primeira tela ao abrir o app
      home: const Login(),
    );
  }
}
