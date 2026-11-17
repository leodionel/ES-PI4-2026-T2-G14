import 'package:flutter/material.dart';

String numeroDado(dynamic valor) => valor is num
    ? valor.toStringAsFixed(2).replaceAll('.', ',')
    : 'Não informado';
String dataDado(dynamic valor) {
  final data = DateTime.tryParse(valor?.toString() ?? '');
  return data == null
      ? 'Não informada'
      : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

String statusDado(dynamic valor) =>
    const {
      'SAUDAVEL': 'Saudável',
      'ATENCAO': 'Atenção',
      'RISCO': 'Risco',
      'SEM_ANALISE': 'Sem análise',
    }[valor] ??
    'Indisponível';

class PaginaDados<T> extends StatefulWidget {
  const PaginaDados({
    super.key,
    required this.carregar,
    required this.construir,
  });
  final Future<T> Function() carregar;
  final Widget Function(T dados, VoidCallback atualizar) construir;
  @override
  State<PaginaDados<T>> createState() => _PaginaDadosState<T>();
}

class _PaginaDadosState<T> extends State<PaginaDados<T>> {
  late Future<T> _dados;
  @override
  void initState() {
    super.initState();
    _dados = widget.carregar();
  }

  void _atualizar() {
    if (mounted) setState(() => _dados = widget.carregar());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _dados,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Não foi possível carregar os dados.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _atualizar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        );
      }
      return widget.construir(snapshot.data as T, _atualizar);
    },
  );
}
