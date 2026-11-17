import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:prontuario_talhao/core/app_exception.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository.dart';
import 'package:prontuario_talhao/data/repositories/auth_repository_remote.dart';
import 'package:prontuario_talhao/data/repositories/dados_repository.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/data/services/token_storage.dart';
import 'package:prontuario_talhao/telas/dashboard_screen.dart';

class TokensMemoria extends TokenStorage {
  String? valor;
  @override
  Future<String?> lerToken() async => valor;
  @override
  Future<void> salvarToken(String token) async {
    valor = token;
  }

  @override
  Future<void> apagarToken() async {
    valor = null;
  }
}

http.Response jsonResposta(Object value, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(value)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
Map<String, dynamic> usuario(String nome) => {
  'id': nome,
  'nome': nome,
  'email': '$nome@example.com',
  'telefone': '19999999999',
};

void main() {
  test('login conserva perfil e logout apaga dados e token', () async {
    final tokens = TokensMemoria();
    final api = ApiClient(
      client: MockClient(
        (r) async =>
            jsonResposta({'token': 'token-maria', 'usuario': usuario('Maria')}),
      ),
    );
    final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
    await auth.entrar('maria@example.com', 'senha');
    expect(auth.usuario?.nome, 'Maria');
    expect(auth.autenticado, isTrue);
    await auth.sair();
    expect(auth.usuario, isNull);
    expect(tokens.valor, isNull);
    expect(auth.autenticado, isFalse);
    auth.dispose();
    api.fechar();
  });

  test(
    'sessão restaurada consulta perfil atual em vez de usar nome salvo',
    () async {
      final tokens = TokensMemoria()..valor = 'token-maria';
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.url.path, '/api/usuarios/me');
          expect(r.headers['Authorization'], 'Bearer token-maria');
          return jsonResposta(usuario('Maria Atualizada'));
        }),
      );
      final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
      await auth.restaurarSessao();
      expect(auth.usuario?.nome, 'Maria Atualizada');
      expect(auth.autenticado, isTrue);
      auth.dispose();
      api.fechar();
    },
  );

  test('token rejeitado não mantém perfil da conta anterior', () async {
    final tokens = TokensMemoria()..valor = 'expirado';
    final api = ApiClient(
      client: MockClient((_) async => jsonResposta({}, 401)),
    );
    final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
    await auth.restaurarSessao();
    expect(auth.usuario, isNull);
    expect(auth.autenticado, isFalse);
    expect(tokens.valor, isNull);
    auth.dispose();
    api.fechar();
  });

  test('falha de rede não produz dados nem apaga token válido', () async {
    final tokens = TokensMemoria()..valor = 'token';
    final api = ApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
    await auth.restaurarSessao();
    expect(auth.usuario, isNull);
    expect(tokens.valor, 'token');
    expect(auth.autenticado, isFalse);
    auth.dispose();
    api.fechar();
  });

  test(
    'repositório usa token atual e não reutiliza dados de outra conta',
    () async {
      final tokens = TokensMemoria()..valor = 'conta-1';
      final api = ApiClient(
        client: MockClient((r) async {
          final conta = r.headers['Authorization']!.split(' ').last;
          return jsonResposta([
            {'id': conta, 'nome': conta},
          ]);
        }),
      );
      final repo = DadosRepository(api: api, tokens: tokens);
      expect((await repo.talhoes()).single['id'], 'conta-1');
      tokens.valor = 'conta-2';
      expect((await repo.talhoes()).single['id'], 'conta-2');
      tokens.valor = null;
      await expectLater(repo.talhoes(), throwsA(isA<AppException>()));
      api.fechar();
    },
  );

  testWidgets(
    'dashboard exibe perfil, propriedade e totais retornados pela API',
    (tester) async {
      final tokens = TokensMemoria()..valor = 'token';
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer token');
          return switch (r.url.path) {
            '/api/usuarios/me' => jsonResposta(usuario('Ana Vitória')),
            '/api/propriedades' => jsonResposta([
              {
                'id': 'p1',
                'nome': 'Sítio Horizonte',
                'localizacao': 'Campinas',
              },
            ]),
            '/api/talhoes' => jsonResposta([
              {'id': 't1', 'nome': 'Área Norte', 'areaHa': 8.5},
            ]),
            '/api/talhoes/t1' => jsonResposta({
              'id': 't1',
              'nome': 'Área Norte',
              'areaHa': 8.5,
            }),
            '/api/talhoes/t1/plantios' => jsonResposta([
              {
                'plantioId': 's1',
                'culturaNome': 'Milho',
                'dataPlantio': '2026-01-01',
                'dataColheita': null,
              },
            ]),
            '/api/analises-solo' => jsonResposta([]),
            '/api/talhoes/t1/status-solo' => jsonResposta({
              'status': 'SEM_ANALISE',
              'motivos': [],
            }),
            _ => throw StateError('Rota inesperada: ${r.url.path}'),
          };
        }),
      );
      final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
      await auth.restaurarSessao();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthRepository>.value(value: auth),
            Provider<DadosRepository>.value(
              value: DadosRepository(api: api, tokens: tokens),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Olá, Ana Vitória'), findsOneWidget);
      expect(find.text('Panorama de Sítio Horizonte'), findsOneWidget);
      expect(find.text('8,50 ha'), findsOneWidget);
      expect(find.textContaining('Leonardo'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      api.fechar();
    },
  );

  testWidgets('dashboard sem registros mostra estado vazio', (tester) async {
    final tokens = TokensMemoria()..valor = 'token';
    final api = ApiClient(
      client: MockClient(
        (r) async => r.url.path == '/api/usuarios/me'
            ? jsonResposta(usuario('José'))
            : jsonResposta([]),
      ),
    );
    final auth = AuthRepositoryRemote(apiClient: api, tokenStorage: tokens);
    await auth.restaurarSessao();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthRepository>.value(value: auth),
          Provider<DadosRepository>.value(
            value: DadosRepository(api: api, tokens: tokens),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cadastre sua propriedade para começar.'), findsOneWidget);
    expect(find.text('0,00 ha'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nenhum talhão cadastrado.'),
      250,
    );
    expect(find.text('Nenhum talhão cadastrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    api.fechar();
  });
}
