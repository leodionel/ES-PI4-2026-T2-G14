
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'telas/dashboard_screen.dart';
import 'telas/login.dart';
import 'telas/perfil_screen.dart';
import 'telas/recuperacao_senha.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prontuário Digital do Talhão',
      theme: AppTheme.claro,

      home: Consumer<AuthRepository>(
        builder: (context, auth, child) {
          if (auth.iniciando) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // USUÁRIO AUTENTICADO
          if (auth.autenticado) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Prontuário Digital do Talhão',
                ),
                actions: [
                  IconButton(
                    tooltip: 'Meu perfil',
                    icon: const Icon(
                      Icons.person_outline,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const PerfilScreen(),
                        ),
                      );
                    },
                  ),

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

          // USUÁRIO NÃO AUTENTICADO
          return Login(
            aoRecuperarSenha: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const RecuperacaoSenha(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
