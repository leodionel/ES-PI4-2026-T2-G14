// Contribuição de Matheus Azevedo Teixeira RA: 25014927

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_remote.dart';
import 'data/repositories/perfil_repository.dart';
import 'data/repositories/simulacao_repository.dart';
import 'data/repositories/talhao_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/token_storage.dart';
import 'telas/login_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, client) => client.fechar(),
        ),

        Provider<TokenStorage>(create: (_) => TokenStorage()),

        Provider<TalhaoRepository>(
          create: (context) => TalhaoRepository(
            context.read<ApiClient>(),
            context.read<TokenStorage>(),
          ),
        ),

        Provider<SimulacaoRepository>(
          create: (context) => SimulacaoRepository(
            context.read<ApiClient>(),
            context.read<TokenStorage>(),
          ),
        ),

        Provider<PerfilRepository>(
          create: (context) => PerfilRepository(
            context.read<ApiClient>(),
            context.read<TokenStorage>(),
          ),
        ),

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

        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(context.read<AuthRepository>()),
        ),
      ],
      child: const App(),
    ),
  );
}
