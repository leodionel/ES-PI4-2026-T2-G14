// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:prontuario_talhao/data/repositories/auth_repository.dart';
import 'package:prontuario_talhao/telas/login_view_model.dart';
import 'package:prontuario_talhao/app.dart';
import 'package:prontuario_talhao/core/app_textos.dart';

void main() {
  testWidgets('app opens the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LoginViewModel>(
        create: (_) => LoginViewModel(_FakeAuthRepository()),
        child: const App(),
      ),
    );

    expect(find.text(AppTextos.loginTitulo), findsOneWidget);
  });
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
