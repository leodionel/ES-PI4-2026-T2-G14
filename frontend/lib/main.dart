import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_remote.dart';
import 'data/repositories/recuperacao_senha_repository_remote.dart';
import 'data/services/api_client.dart';
import 'data/services/token_storage.dart';
import 'telas/login_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Cliente HTTP compartilhado.
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, apiClient) => apiClient.fechar(),
        ),

        // Armazenamento seguro do token JWT.
        Provider<TokenStorage>(create: (_) => TokenStorage()),

        // Repository de recuperação de senha.
        Provider<RecuperacaoSenhaRepositoryRemote>(
          create: (context) => RecuperacaoSenhaRepositoryRemote(
            apiClient: context.read<ApiClient>(),
          ),
        ),

        // Autenticação real com a API Java.
        ChangeNotifierProvider<AuthRepository>(
          create: (context) {
            final auth = AuthRepositoryRemote(
              apiClient: context.read<ApiClient>(),
              tokenStorage: context.read<TokenStorage>(),
            );

            unawaited(auth.restaurarSessao());

            return auth;
          },
        ),

        // ViewModel de login.
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(context.read<AuthRepository>()),
        ),
      ],
      child: const App(),
    ),
  );
}
