// Contribuição: Matheus Rosini
// RA: 25015832

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:prontuario_talhao/data/repositories/talhao_repository.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/data/services/servidor_http.dart';
import 'package:prontuario_talhao/data/services/token_storage.dart';
import 'package:prontuario_talhao/domain/models/talhao_resumo.dart';

// Simula um usuario com token JWT salvo.
class TokenTeste extends TokenStorage {
  @override
  Future<String?> lerToken() async => 'token-teste';
}

void main() {
  group('TalhaoRepository', () {
    test('lista os talhoes com apenas uma requisicao', () async {
      final caminhos = <String>[];

      final cliente = MockClient((pedido) async {
        caminhos.add(pedido.url.path);

        expect(pedido.headers['Authorization'], 'Bearer token-teste');

        return http.Response(
          jsonEncode([
            {
              'id': 't1',
              'nome': 'Talhão Norte',
              'areaHa': 12.5,
              'totalPlantios': 1,
              'totalAnalises': 1,
              'statusSolo': 'ATENCAO',
              'dataAnalise': '2026-10-20',
              'motivos': ['pH (acidez alta)'],
              'culturaAtual': {'nome': 'Soja'},
            },
            {
              'id': 't2',
              'nome': 'Talhão Sul',
              'areaHa': 4.0,
              'totalPlantios': 0,
              'totalAnalises': 0,
              'statusSolo': 'SEM_ANALISE',
              'dataAnalise': null,
              'motivos': [],
              'culturaAtual': null,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = TalhaoRepository(
        ApiClient(
          servidor: ServidorHttp(
            enderecoBase: 'http://localhost:3001',
            cliente: cliente,
          ),
        ),
        TokenTeste(),
      );

      final lista = await repository.listar();

      // Uma chamada para toda a lista.
      expect(caminhos, ['/api/talhoes']);

      expect(lista.length, 2);

      // Dados do primeiro talhao.
      expect(lista[0].id, 't1');
      expect(lista[0].nome, 'Talhão Norte');
      expect(lista[0].areaHa, 12.5);
      expect(lista[0].totalPlantios, 1);
      expect(lista[0].totalAnalises, 1);
      expect(lista[0].status, StatusSolo.atencao);
      expect(lista[0].culturaAtual, 'Soja');

      expect(lista[0].motivos, ['pH (acidez alta)']);

      expect(lista[0].dataAnalise, DateTime(2026, 10, 20));

      // Dados do segundo talhao.
      expect(lista[1].id, 't2');
      expect(lista[1].status, StatusSolo.semAnalise);

      expect(lista[1].culturaAtual, isNull);
      expect(lista[1].dataAnalise, isNull);
      expect(lista[1].motivos, isEmpty);

      cliente.close();
    });

    test('aceita lista vazia sem requisicoes extras', () async {
      var chamadas = 0;

      final cliente = MockClient((pedido) async {
        chamadas++;

        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = TalhaoRepository(
        ApiClient(
          servidor: ServidorHttp(
            enderecoBase: 'http://localhost:3001',
            cliente: cliente,
          ),
        ),
        TokenTeste(),
      );

      final lista = await repository.listar();

      expect(lista, isEmpty);
      expect(chamadas, 1);

      cliente.close();
    });
  });
}
