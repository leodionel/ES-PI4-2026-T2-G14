import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';

class LinhaTempoScreen extends StatelessWidget {
  const LinhaTempoScreen({super.key, required this.talhaoId});
  final String talhaoId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Linha do tempo')),
    body: PaginaDados<DadosTalhao>(
      carregar: () => context.read<DadosRepository>().detalhe(talhaoId),
      construir: (dados, atualizar) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(dados.nome, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${numeroDado(dados.talhao['areaHa'])} ha • ${dados.culturaAtual}',
          ),
          if (dados.eventos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhum registro no histórico deste talhão.'),
            ),
          for (final e in dados.eventos)
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text('${e['titulo']}'),
                subtitle: Text('${dataDado(e['data'])}\n${e['descricao']}'),
              ),
            ),
        ],
      ),
    ),
  );
}
