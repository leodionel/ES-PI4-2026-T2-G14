import 'package:flutter/material.dart'; // Importa os componentes do Flutter
import 'package:provider/provider.dart';

import 'app.dart'; //Configuracao do aplicativo
import 'data/repositories/auth_repository_indisponivel.dart';
import 'telas/login_view_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoginViewModel(AuthRepositoryIndisponivel()),
      child: const App(),
    ),
  );
}
