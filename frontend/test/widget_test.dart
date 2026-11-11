import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:prontuario_talhao/app.dart';
import 'package:prontuario_talhao/core/app_textos.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository.dart';
import 'package:prontuario_talhao/data/repositories/recuperacao_senha_repository_remote.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/telas/login_view_model.dart';
import 'package:prontuario_talhao/telas/recuperacao_senha.dart';

// Testes automatizados das telas de autenticação.
void main() {
  testWidgets('Abre o login e navega para recuperação de senha', (
    WidgetTester tester,
  ) async {
    // Prepara os Providers necessários para o aplicativo.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Cliente HTTP utilizado pelo repository.
          // Nenhuma requisição é feita neste teste.
          Provider<ApiClient>(
            create: (_) => ApiClient(),
            dispose: (_, apiClient) => apiClient.fechar(),
          ),

          // Repository da recuperação de senha.
          Provider<RecuperacaoSenhaRepositoryRemote>(
            create: (context) => RecuperacaoSenhaRepositoryRemote(
              apiClient: context.read<ApiClient>(),
            ),
          ),

          // Autenticação simulada somente para testes.
          ChangeNotifierProvider<AuthRepository>(
            create: (_) => _FakeAuthRepository(),
          ),

          // ViewModel utilizado pela tela de login.
          ChangeNotifierProvider<LoginViewModel>(
            create: (context) => LoginViewModel(context.read<AuthRepository>()),
          ),
        ],
        child: const App(),
      ),
    );

    // Verifica se a tela de login apareceu.
    expect(find.text(AppTextos.loginTitulo), findsOneWidget);

    // Encontra o botão de recuperação de senha.
    final botaoRecuperacao = find.text(AppTextos.esqueciSenha);

    expect(botaoRecuperacao, findsOneWidget);

    // Clica no botão.
    await tester.tap(botaoRecuperacao);

    // Aguarda a navegação terminar.
    await tester.pumpAndSettle();

    // Confirma que a tela de recuperação foi aberta.
    expect(find.byType(RecuperacaoSenha), findsOneWidget);

    // Confirma que o botão de envio está visível.
    expect(find.text('Enviar link de recuperação'), findsOneWidget);

    // Confirma que existe uma opção para voltar ao login.
    expect(find.text('Voltar para o login'), findsOneWidget);
  });
}

// Implementação simulada usada apenas no teste.
// Não altera a autenticação real do aplicativo.
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
