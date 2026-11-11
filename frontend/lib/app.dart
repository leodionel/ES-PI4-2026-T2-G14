import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/recuperacao_senha_repository_remote.dart';
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
          // Aguarda a verificação da sessão salva.
          if (auth.iniciando) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Usuário autenticado.
          if (auth.autenticado) {
            return const _TelaAutenticada();
          }

          // Usuário ainda não autenticado.
          return Login(
            aoRecuperarSenha: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => RecuperacaoSenha(
                    // Conecta a tela à API Java.
                    aoSolicitarRecuperacao: context
                        .read<RecuperacaoSenhaRepositoryRemote>()
                        .solicitarRecuperacao,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Tela temporária exibida após autenticação.
// Será substituída pelo dashboard do projeto.
class _TelaAutenticada extends StatelessWidget {
  const _TelaAutenticada();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prontuário Digital do Talhão'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthRepository>().sair();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                'Login realizado com sucesso!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'A integração com o dashboard será feita '
                'nas próximas etapas.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
