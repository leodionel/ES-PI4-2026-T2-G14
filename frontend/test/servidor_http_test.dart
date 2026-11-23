// Feito por Leonardo Dionel RA:25010092

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prontuario_talhao/core/app_exception.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/data/services/servidor_http.dart';
import 'package:prontuario_talhao/data/services/servidor_transporte.dart';

void main() {
  group('ServidorHttp', () {
    test('envia método, caminho, token e corpo ao servidor', () async {
      late http.Request recebido;

      final cliente = MockClient((pedido) async {
        recebido = pedido;
        return http.Response('{"ok":true}', 201, headers: {
          'content-type': 'application/json',
        });
      });

      final servidor = ServidorHttp(
        enderecoBase: 'http://localhost:3001/',
        cliente: cliente,
      );

      final resposta = await servidor.enviar(
        metodo: 'POST',
        caminho: '/api/talhoes',
        token: 'abc.def',
        corpo: Uint8List.fromList(utf8.encode('{"nome":"A"}')),
      );

      expect(recebido.method, 'POST');
      expect(recebido.url.toString(), 'http://localhost:3001/api/talhoes');
      expect(recebido.headers['Authorization'], 'Bearer abc.def');
      expect(recebido.body, '{"nome":"A"}');
      expect(resposta.status, 201);
      expect(utf8.decode(resposta.corpo), '{"ok":true}');
    });

    test('não envia Authorization nem corpo quando não há', () async {
      late http.Request recebido;

      final servidor = ServidorHttp(
        enderecoBase: 'http://localhost:3001',
        cliente: MockClient((pedido) async {
          recebido = pedido;
          return http.Response('[]', 200);
        }),
      );

      await servidor.enviar(metodo: 'GET', caminho: '/api/talhoes');

      expect(recebido.headers.containsKey('Authorization'), isFalse);
      expect(recebido.body, isEmpty);
    });

    test('falha de conexão vira ConexaoFalhouException', () async {
      final servidor = ServidorHttp(
        enderecoBase: 'http://localhost:3001',
        cliente: MockClient((pedido) async {
          throw http.ClientException('sem conexão');
        }),
      );

      expect(
        () => servidor.enviar(metodo: 'GET', caminho: '/status'),
        throwsA(isA<ConexaoFalhouException>()),
      );
    });
  });

  group('ApiClient com ServidorHttp', () {
    ApiClient clienteCom(MockClient mock) {
      return ApiClient(
        servidor: ServidorHttp(
          enderecoBase: 'http://localhost:3001',
          cliente: mock,
        ),
      );
    }

    test('senha errada devolve erro de autenticação e permite nova tentativa',
        () async {
      var chamadas = 0;

      final api = clienteCom(
        MockClient((pedido) async {
          chamadas++;

          if (chamadas == 1) {
            return http.Response('{"detail":"Credenciais inválidas"}', 401);
          }

          return http.Response('{"token":"jwt"}', 200);
        }),
      );

      await expectLater(
        api.post('/api/usuarios/login', {'email': 'a@a.com', 'senha': 'x'}),
        throwsA(
          isA<AppException>().having(
            (e) => e.tipo,
            'tipo',
            TipoErro.autenticacao,
          ),
        ),
      );

      final segunda = await api.post('/api/usuarios/login', {
        'email': 'a@a.com',
        'senha': 'certa',
      });

      expect(segunda['token'], 'jwt');
    });

    test('servidor desligado vira erro de rede', () async {
      final api = clienteCom(
        MockClient((pedido) async {
          throw http.ClientException('sem conexão');
        }),
      );

      await expectLater(
        api.get('/api/talhoes'),
        throwsA(
          isA<AppException>().having((e) => e.tipo, 'tipo', TipoErro.rede),
        ),
      );
    });
  });
}
