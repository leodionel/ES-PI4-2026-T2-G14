import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prontuario_talhao/telas/simulacao_rotacao.dart';

void main() {
  testWidgets('exibe cenário inicial e atualiza dados ao trocar de talhão', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SimulacaoRotacao()));

    expect(find.text('Simulação de Rotação'), findsWidgets);
    expect(find.text('42,3 ha • Soja'), findsOneWidget);
    expect(find.text('Recomendado'), findsOneWidget);

    await tester.tap(find.text('Talhão 03'));
    await tester.pumpAndSettle();

    expect(find.text('20 ha • Feijão'), findsOneWidget);
    expect(find.text('Milho'), findsWidgets);
  });

  testWidgets('limita comparação a três culturas e permite removê-las', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SimulacaoRotacao()));

    await tester.tap(find.text('Trigo'));
    await tester.pump();

    expect(
      find.text('Você pode comparar até 3 culturas por vez.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Pousio').first);
    await tester.pumpAndSettle();

    expect(find.text('Pousio'), findsOneWidget);
  });
}
