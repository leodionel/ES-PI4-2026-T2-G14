import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:prontuario_talhao/core/utils/pdf_export_service.dart';
import 'package:prontuario_talhao/data/repositories/dados_repository.dart';
import 'package:prontuario_talhao/data/services/api_client.dart';
import 'package:prontuario_talhao/telas/analise_solo_screen.dart';
import 'package:prontuario_talhao/telas/simulacao_rotacao.dart';
import 'dados_usuario_test.dart' show TokensMemoria, jsonResposta;

const talhao = {'id': 't1', 'nome': 'Área das Águas', 'areaHa': 8.5};
const propriedade = {
  'id': 'p1',
  'nome': 'Sítio Horizonte',
  'localizacao': 'Campinas',
};
const status = {'status': 'SEM_ANALISE', 'motivos': <String>[]};

void main() {
  testWidgets(
    'simulação envia escolhas e exibe somente o resultado do servidor',
    (tester) async {
      var enviado = false;
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer conta');
          if (r.method == 'POST') {
            expect(r.url.path, '/api/talhoes/t1/simulacoes');
            expect(jsonDecode(r.body), {
              'culturaIds': ['milho', 'soja'],
            });
            enviado = true;
            return jsonResposta({
              'statusSolo': status,
              'historicoConsiderado': [],
              'opcoesEquivalentes': true,
              'mensagemEquivalencia': 'Resultado calculado no servidor',
              'cenarios': [],
              'aviso': 'Apoio à decisão',
            });
          }
          return jsonResposta(
            r.url.path == '/api/talhoes'
                ? [talhao]
                : [
                    {'id': 'milho', 'nome': 'Milho'},
                    {'id': 'soja', 'nome': 'Soja'},
                  ],
          );
        }),
      );
      await tester.pumpWidget(
        Provider<DadosRepository>(
          create: (_) => DadosRepository(
            api: api,
            tokens: TokensMemoria()..valor = 'conta',
          ),
          child: const MaterialApp(home: SimulacaoRotacao(talhaoId: 't1')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milho'));
      await tester.tap(find.text('Soja'));
      await tester.pump();
      await tester.tap(find.text('Comparar culturas'));
      await tester.pumpAndSettle();
      expect(enviado, isTrue);
      expect(find.text('Resultado calculado no servidor'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.fechar();
    },
  );

  testWidgets(
    'análise salva valores, propriedade e talhão consultados na API',
    (tester) async {
      Map<String, dynamic>? salva;
      final api = ApiClient(
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer conta');
          if (r.method == 'POST') {
            expect(r.url.path, '/api/analises-solo');
            salva = jsonDecode(r.body) as Map<String, dynamic>;
            return jsonResposta({'id': 'a1', ...salva!}, 201);
          }
          return switch (r.url.path) {
            '/api/talhoes/t1' => jsonResposta(talhao),
            '/api/propriedades' => jsonResposta([propriedade]),
            '/api/talhoes/t1/status-solo' => jsonResposta(status),
            '/api/analises-solo' => jsonResposta(
              salva == null
                  ? []
                  : [
                      {'id': 'a1', ...salva!},
                    ],
            ),
            _ => jsonResposta([]),
          };
        }),
      );
      await tester.pumpWidget(
        Provider<DadosRepository>(
          create: (_) => DadosRepository(
            api: api,
            tokens: TokensMemoria()..valor = 'conta',
          ),
          child: const MaterialApp(home: AnaliseSoloScreen(talhaoId: 't1')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextFormField, 'Data da coleta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      for (final campo in {
        'pH (CaCl₂)': '5,8',
        'Fósforo (P resina, mg/dm³)': '12',
        'Potássio (mmolc/dm³)': '3',
        'Saturação por bases (%)': '60',
      }.entries) {
        final finder = find.widgetWithText(TextFormField, campo.key);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, campo.value);
      }
      await tester.ensureVisible(find.text('Registrar análise'));
      await tester.tap(find.text('Registrar análise'));
      await tester.pumpAndSettle();
      expect(salva, containsPair('ph', 5.8));
      expect(salva, containsPair('propriedadeId', 'p1'));
      expect(salva, containsPair('talhaoId', 't1'));
      expect(find.text('Análise salva com sucesso.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.fechar();
    },
  );

  test('PDF suporta prontuário vazio e histórico extenso', () async {
    for (final quantidade in [0, 120]) {
      final dados = DadosTalhao(
        talhao,
        propriedade,
        [],
        List.generate(
          quantidade,
          (i) => {
            'dataColeta': '2026-10-01',
            'ph': 5.8,
            'fosforo': 12,
            'potassio': 3,
            'saturacaoBases': 60,
            'observacoes': 'Coleta número $i após a colheita.',
          },
        ),
        status,
      );
      final bytes = await PdfExportService.gerar(dados);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      if (const bool.fromEnvironment('GERAR_PREVIEW')) {
        Directory('build/qa').createSync(recursive: true);
        File('build/qa/prontuario-$quantidade.pdf').writeAsBytesSync(bytes);
      }
    }
  });
}
