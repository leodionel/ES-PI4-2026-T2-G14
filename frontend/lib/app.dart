
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'telas/cadastro_screen.dart';
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

      home: Consumer<AuthRepository>(
        builder: (context, auth, child) {
          // Verifica se existe uma sessão JWT salva.
          if (auth.iniciando) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Usuário autenticado: abre o Dashboard.
          if (auth.autenticado) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Prontuário Digital do Talhão',
                ),
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

          // Usuário sem sessão: abre o Login.
          return Login(
            // CADASTRO DE USUÁRIO
            aoCriarConta: () async {
              final cadastrado =
                  await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      const CadastroScreen(),
                ),
              );

              if (cadastrado == true &&
                  context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Conta criada com sucesso! '
                      'Faça login para continuar.',
                    ),
                    backgroundColor:
                        Color(0xFF4A5D23),
                  ),
                );
              }
            },

            // RECUPERAÇÃO DE SENHA
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
