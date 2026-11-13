import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'telas/dashboard_screen.dart';
import 'telas/login.dart';
import 'telas/recuperacao_senha.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prontuário Digital do Talhão',
      theme: AppTheme.claro,

      // Configuração do idioma português brasileiro.
      locale: const Locale('pt', 'BR'),

      supportedLocales: const [Locale('pt', 'BR')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: Consumer<AuthRepository>(
        builder: (context, auth, child) {
          // Verifica se existe uma sessão JWT salva.
          if (auth.iniciando) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Login realizado: abre o dashboard.
          if (auth.autenticado) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Prontuário Digital do Talhão'),
                actions: [
                  TextButton.icon(
                    onPressed: () async {
                      await auth.sair();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                  ),
                ],
              ),
              body: const DashboardScreen(),
            );
          }

          // Usuário não autenticado: abre o login.
          return Login(
            aoRecuperarSenha: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecuperacaoSenha(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
