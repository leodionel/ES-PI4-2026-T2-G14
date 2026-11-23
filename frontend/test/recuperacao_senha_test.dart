import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:prontuario_talhao/core/app_exception.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository_remote.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/data/services/servidor_http.dart';
import 'package:prontuario_talhao/data/services/token_storage.dart';
import 'package:prontuario_talhao/telas/recuperacao_senha.dart';

AuthRepositoryRemote _repositorio(MockClient cliente) {
  return AuthRepositoryRemote(
    apiClient: ApiClient(
      servidor: ServidorHttp(
        enderecoBase: 'http://localhost:3001',
        cliente: cliente,
      ),
    ),
    tokenStorage: TokenStorage(),
  );
}

void main() {
  group('Recuperação de senha - repositório', () {
    test('solicita o código sem token e devolve o código simulado', () async {
      late http.Request recebido;

      final auth = _repositorio(
        MockClient((pedido) async {
          recebido = pedido;
          return http.Response(
            jsonEncode({'mensagem': 'ok', 'codigoSimulado': '123456'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final codigo = await auth.solicitarRecuperacao('  Ana@Email.com ');

      expect(codigo, '123456');
      expect(recebido.method, 'POST');
      expect(recebido.url.path, '/api/usuarios/recuperar-senha');
      expect(recebido.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(recebido.body), {'email': 'ana@email.com'});
    });

    test('devolve null quando o backend não exibe o código', () async {
      final auth = _repositorio(
        MockClient((_) async => http.Response(
          jsonEncode({'mensagem': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        )),
      );

      expect(await auth.solicitarRecuperacao('ana@email.com'), isNull);
    });

    test('redefine a senha enviando e-mail, código e nova senha', () async {
      late http.Request recebido;

      final auth = _repositorio(
        MockClient((pedido) async {
          recebido = pedido;
          return http.Response('', 204);
        }),
      );

      await auth.redefinirSenha(
        email: 'ana@email.com',
        codigo: '123456',
        novaSenha: 'NovaSenha123',
      );

      expect(recebido.url.path, '/api/usuarios/redefinir-senha');
      expect(jsonDecode(recebido.body), {
        'email': 'ana@email.com',
        'codigo': '123456',
        'novaSenha': 'NovaSenha123',
      });
    });

    test('repassa a mensagem do backend quando o código é inválido', () async {
      final auth = _repositorio(
        MockClient((_) async => http.Response(
          jsonEncode({'detail': 'Código inválido ou expirado.'}),
          400,
          headers: {'content-type': 'application/json'},
        )),
      );

      expect(
        () => auth.redefinirSenha(
          email: 'ana@email.com',
          codigo: '000000',
          novaSenha: 'NovaSenha123',
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.tipo, 'tipo', TipoErro.validacao)
              .having(
                (e) => e.mensagem,
                'mensagem',
                'Código inválido ou expirado.',
              ),
        ),
      );
    });
  });

  group('Recuperação de senha - tela', () {
    Future<void> abrir(
      WidgetTester tester, {
      Future<String?> Function(String)? solicitar,
      Future<void> Function(String, String, String)? redefinir,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: RecuperacaoSenha(
            aoSolicitarRecuperacao: solicitar,
            aoRedefinirSenha: redefinir,
          ),
        ),
      );
    }

    testWidgets('sem integração informa que não está conectada', (
      tester,
    ) async {
      await abrir(tester);

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pump();

      expect(
        find.text('A recuperação de senha ainda não está conectada ao '
            'servidor.'),
        findsOneWidget,
      );
    });

    testWidgets('mostra o código simulado e redefine a senha', (tester) async {
      String? emailRecebido;
      List<String>? dadosRedefinicao;

      await abrir(
        tester,
        solicitar: (email) async {
          emailRecebido = email;
          return '123456';
        },
        redefinir: (email, codigo, senha) async {
          dadosRedefinicao = [email, codigo, senha];
        },
      );

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      expect(emailRecebido, 'ana@email.com');
      expect(find.textContaining('123456'), findsWidgets);

      final campos = find.byType(TextFormField);
      expect(campos, findsNWidgets(4));

      await tester.enterText(campos.at(1), '123456');
      await tester.enterText(campos.at(2), 'NovaSenha123');
      await tester.enterText(campos.at(3), 'NovaSenha123');

      await tester.ensureVisible(find.text('Redefinir senha').last);
      await tester.tap(find.text('Redefinir senha').last);
      await tester.pumpAndSettle();

      expect(dadosRedefinicao, ['ana@email.com', '123456', 'NovaSenha123']);
    });

    testWidgets('não redefine quando as senhas não coincidem', (tester) async {
      var chamou = false;

      await abrir(
        tester,
        solicitar: (_) async => '123456',
        redefinir: (_, _, _) async {
          chamou = true;
        },
      );

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(1), '123456');
      await tester.enterText(campos.at(2), 'NovaSenha123');
      await tester.enterText(campos.at(3), 'OutraSenha123');

      await tester.ensureVisible(find.text('Redefinir senha').last);
      await tester.tap(find.text('Redefinir senha').last);
      await tester.pumpAndSettle();

      expect(chamou, isFalse);
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
    });

    testWidgets('exibe a mensagem do backend quando o código é inválido', (
      tester,
    ) async {
      await abrir(
        tester,
        solicitar: (_) async => '123456',
        redefinir: (_, _, _) async {
          throw const AppException(
            tipo: TipoErro.validacao,
            mensagem: 'Código inválido ou expirado.',
          );
        },
      );

      await tester.enterText(find.byType(TextFormField), 'ana@email.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(1), '000000');
      await tester.enterText(campos.at(2), 'NovaSenha123');
      await tester.enterText(campos.at(3), 'NovaSenha123');

      await tester.ensureVisible(find.text('Redefinir senha').last);
      await tester.tap(find.text('Redefinir senha').last);
      await tester.pumpAndSettle();

      expect(find.text('Código inválido ou expirado.'), findsOneWidget);
    });
  });
}
