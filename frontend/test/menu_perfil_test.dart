import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prontuario_talhao/core/widgets/app_shell.dart';
import 'package:prontuario_talhao/data/repositories/perfil_repository.dart';
import 'package:prontuario_talhao/data/repositories/talhao_repository.dart';
import 'package:prontuario_talhao/domain/models/talhao_resumo.dart';

class _Perfis extends Fake implements PerfilRepository {
  @override
  Future<PerfilCompleto> buscar() async =>
      const PerfilCompleto(nome: 'Ana', email: 'ana@example.org', telefone: '');
}

class _Talhoes extends Fake implements TalhaoRepository {
  @override
  Future<List<TalhaoResumo>> listar() async => [];
}

void main() {
  testWidgets('tocar em Perfil enquanto o menu fecha preserva a rota', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PerfilRepository>.value(value: _Perfis()),
          Provider<TalhaoRepository>.value(value: _Talhoes()),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final perfil = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Perfil'),
    );
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 10));
    perfil.onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Dados pessoais'), findsOneWidget);
    expect(find.text('ana@example.org'), findsOneWidget);
  });
}
