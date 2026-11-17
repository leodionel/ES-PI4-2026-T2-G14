import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';
import '../core/utils/pdf_export_service.dart';
import 'talhaoespecifico.dart';
import 'analise_solo_screen.dart';
import 'culturas_safras_screen.dart';
import 'simulacao_rotacao.dart';

class ProntuarioScreen extends StatelessWidget {
  const ProntuarioScreen({super.key, required this.talhaoId});
  final String talhaoId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prontuário do talhão')),
    body: PaginaDados<DadosTalhao>(
      carregar: () => context.read<DadosRepository>().detalhe(talhaoId),
      construir: (dados, atualizar) {
        Future<void> abrir(Widget tela) async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => tela));
          if (context.mounted) atualizar();
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(dados.nome, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              '${numeroDado(dados.talhao['areaHa'])} ha • ${dados.culturaAtual}',
            ),
            Text(
              'Propriedade: ${dados.propriedade?['nome'] ?? 'Não informada'}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      abrir(CulturasSafrasScreen(talhaoId: talhaoId)),
                  child: const Text('Culturas e safras'),
                ),
                FilledButton(
                  onPressed: () => abrir(AnaliseSoloScreen(talhaoId: talhaoId)),
                  child: const Text('Análises de solo'),
                ),
                OutlinedButton(
                  onPressed: () => abrir(LinhaTempoScreen(talhaoId: talhaoId)),
                  child: const Text('Linha do tempo'),
                ),
                OutlinedButton(
                  onPressed: () => abrir(SimulacaoRotacao(talhaoId: talhaoId)),
                  child: const Text('Simular rotação'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await PdfExportService.exportarProntuarioTalhao(dados);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Não foi possível exportar o PDF.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                ),
                IconButton(
                  onPressed: atualizar,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar dados',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Status do solo: ${statusDado(dados.status['status'])}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final motivo in dados.status['motivos'] as List? ?? [])
              Text('$motivo'),
            if (dados.status['aviso'] != null) Text('${dados.status['aviso']}'),
            Text(
              'Safras registradas: ${dados.plantios.length} • Análises: ${dados.analises.length}',
            ),
            const SizedBox(height: 24),
            Text(
              'Última análise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (dados.analises.isEmpty)
              const Text('Nenhuma análise cadastrada.')
            else ...[
              Text('Coleta: ${dataDado(dados.analises.first['dataColeta'])}'),
              for (final campo in {
                'ph': 'pH (CaCl₂)',
                'fosforo': 'Fósforo (mg/dm³)',
                'potassio': 'Potássio (mmolc/dm³)',
                'saturacaoBases': 'Saturação por bases (%)',
              }.entries)
                ListTile(
                  title: Text(campo.value),
                  trailing: Text(numeroDado(dados.analises.first[campo.key])),
                ),
            ],
          ],
        );
      },
    ),
  );
}
