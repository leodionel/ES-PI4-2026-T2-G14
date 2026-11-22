import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';

import 'package:prontuario_talhao/app.dart';
import 'package:prontuario_talhao/core/app_textos.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository.dart';
import 'package:prontuario_talhao/telas/login_view_model.dart';

void main() {
  testWidgets('recupera a senha a partir do login', (tester) async {
    final auth = _FakeAuthRepository();
    final api = _ApiDeTeste();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider(create: (_) => LoginViewModel(auth)),
        ],
        child: const App(),
      ),
    );
    Future<void> tocar(String texto) async {
      final alvo = find.text(texto);
      await tester.ensureVisible(alvo);
      await tester.tap(alvo);
      await tester.pumpAndSettle();
    }

    await tocar(AppTextos.esqueciSenha);
    await tester.enterText(find.byType(TextFormField).first, 'ana@example.org');
    await tocar('Enviar código');
    const codigo = '12345678901234567890123456789012';
    await tester.enterText(find.byType(TextFormField).at(1), codigo);
    await tester.enterText(find.byType(TextFormField).at(2), 'novaSenha123');
    await tocar('Alterar senha');
    expect(api.pedidos, [
      [
        '/api/usuarios/recuperacao-senha',
        {'email': 'ana@example.org'},
      ],
      [
        '/api/usuarios/redefinir-senha',
        {
          'email': 'ana@example.org',
          'codigo': codigo,
          'novaSenha': 'novaSenha123',
        },
      ],
    ]);
    expect(
      find.text('Senha alterada. Entre com a nova senha.'),
      findsOneWidget,
    );
    await tocar('Voltar para o login');
    expect(find.text(AppTextos.loginTitulo), findsOneWidget);
  });
  testWidgets('app opens the login screen', (tester) async {
    final auth = _FakeAuthRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider<LoginViewModel>(
            create: (_) => LoginViewModel(auth),
          ),
        ],
        child: const App(),
      ),
    );

    expect(find.text(AppTextos.loginTitulo), findsOneWidget);
  });
}

class _ApiDeTeste extends Fake implements ApiClient {
  final pedidos = <List<Object>>[];
  @override
  Future<Map<String, dynamic>> post(
    String caminho,
    Map<String, dynamic> dados, {
    String? token,
  }) async {
    pedidos.add([caminho, dados]);
    return {};
  }
}

class _FakeAuthRepository extends AuthRepository {
  @override
  bool get iniciando => false;

  @override
  bool get autenticado => false;

  @override
  Future<void> restaurarSessao() async {}

  @override
  Future<void> entrar(String email, String senha) async {}

  @override
  Future<void> sair() async {}
}
