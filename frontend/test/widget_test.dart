import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:prontuario_talhao/app.dart';
import 'package:prontuario_talhao/core/app_textos.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository.dart';
import 'package:prontuario_talhao/telas/login_view_model.dart';

void main() {
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
