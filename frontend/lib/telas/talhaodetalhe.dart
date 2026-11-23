// Contribuição de Matheus Azevedo Teixeira RA: 25014927

// FEITO POR (LUCAS KENDI) RA: (25014845)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatadores.dart';
import '../core/utils/pdf_export_service.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/status_chip.dart';
import '../data/repositories/talhao_repository.dart';
import '../domain/models/talhao_resumo.dart';
import 'analise_solo_screen.dart';
import 'culturas_safras_screen.dart';

// Prontuário de um talhão (RF13): status do solo, ações de registro e o
// histórico de culturas, colheitas e análises em ordem cronológica.
class ProntuarioScreen extends StatefulWidget {
  const ProntuarioScreen({super.key, required this.talhaoId});

  final String talhaoId;

  @override
  State<ProntuarioScreen> createState() => _ProntuarioScreenState();
}

// Um acontecimento do histórico.
class _Evento {
  const _Evento(this.data, this.tipo, this.descricao);

  final String data; // yyyy-MM-dd, usado para ordenar
  final String tipo;
  final String descricao;
}

class _ProntuarioScreenState extends State<ProntuarioScreen> {
  bool _carregando = true;
  bool _exportando = false;
  String? _erro;

  Map<String, dynamic> _talhao = const {};
  Map<String, dynamic> _status = const {};
  List<Map<String, dynamic>> _plantios = const [];
  List<Map<String, dynamic>> _analises = const [];

  TalhaoRepository get _repo => context.read<TalhaoRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  String _mensagem(Object e) =>
      e is AppException ? e.mensagem : AppTextos.erroInesperado;

  Future<void> _carregar() async {
    final repo = _repo;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final talhao = await repo.detalhe(widget.talhaoId);
      final status = await repo.statusSolo(widget.talhaoId);
      final plantios = await repo.plantios(widget.talhaoId);
      final analises = await repo.analises(widget.talhaoId);

      if (!mounted) return;

      setState(() {
        _talhao = talhao;
        _status = status;
        _plantios = plantios;
        _analises = analises;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _exportarPdf() async {
    if (_exportando) return;

    setState(() => _exportando = true);

    try {
      await PdfExportService.exportarProntuarioTalhao(
        talhao: _talhao,
        analises: _analises,
        plantios: _plantios,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));

    // O registro pode ter mudado o status e o histórico.
    if (mounted) await _carregar();
  }

  List<_Evento> _eventos() {
    final eventos = <_Evento>[];

    for (final p in _plantios) {
      final cultura = (p['culturaNome'] ?? '').toString();
      final plantio = (p['dataPlantio'] ?? '').toString();
      final colheita = p['dataColheita']?.toString();

      if (plantio.isNotEmpty) {
        eventos.add(_Evento(plantio, 'Plantio', cultura));
      }
      if (colheita != null && colheita.isNotEmpty) {
        eventos.add(_Evento(colheita, 'Colheita', cultura));
      }
    }

    String n(dynamic v) => v is num ? Formatadores.decimal(v.toDouble()) : '-';

    for (final a in _analises) {
      eventos.add(
        _Evento(
          (a['dataColeta'] ?? '').toString(),
          'Análise de solo',
          'pH ${n(a['ph'])} · P ${n(a['fosforo'])} mg/dm³ · '
              'K ${n(a['potassio'])} mmolc/dm³ · V ${n(a['saturacaoBases'])}%',
        ),
      );
    }

    eventos.sort((a, b) => b.data.compareTo(a.data));

    return eventos;
  }

  @override
  Widget build(BuildContext context) {
    final nome = (_talhao['nome'] ?? 'Prontuário').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(nome),
        actions: [
          IconButton(
            tooltip: 'Exportar prontuário em PDF',
            onPressed: _carregando || _erro != null || _exportando
                ? null
                : _exportarPdf,
            icon: _exportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando && _talhao.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erro!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(texto: 'Tentar novamente', onPressed: _carregar),
              ],
            ),
          ),
        ),
      );
    }

    final textos = Theme.of(context).textTheme;
    final status = StatusSolo.doServidor(_status['status']);
    final motivos = ((_status['motivos'] as List?) ?? const [])
        .map((m) => m.toString())
        .toList();
    final aviso = (_status['aviso'] ?? '').toString();
    final area = (_talhao['areaHa'] as num?)?.toDouble();
    final eventos = _eventos();
    final emAndamento = _plantios.where((p) => p['dataColheita'] == null).toList();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              area == null ? 'Área não informada' : '${Formatadores.decimal(area)} ha',
                              style: textos.titleLarge,
                            ),
                            StatusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emAndamento.isEmpty
                              ? 'Sem cultura em andamento.'
                              : 'Cultura atual: ${emAndamento.first['culturaNome']}',
                          style: textos.bodyMedium,
                        ),
                        if (_status['dataAnalise'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Última análise em ${Formatadores.dataDoServidor(_status['dataAnalise'])}.',
                            style: textos.bodySmall?.copyWith(fontSize: 14),
                          ),
                        ],
                        if (motivos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Pontos de atenção', style: textos.titleMedium),
                          const SizedBox(height: 4),
                          for (final m in motivos) Text('• $m', style: textos.bodyMedium),
                        ],
                        if (aviso.isNotEmpty && aviso != 'null') ...[
                          const SizedBox(height: 12),
                          Text(aviso, style: textos.bodySmall?.copyWith(fontSize: 14)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          '"Saudável" quer dizer apenas que nenhum indicador '
                          'avaliado acendeu alerta. Não substitui um agrônomo.',
                          style: textos.bodySmall?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _abrir(
                        CulturasSafrasScreen(
                          talhaoId: widget.talhaoId,
                          talhaoNome: (_talhao['nome'] ?? '').toString(),
                        ),
                      ),
                      icon: const Icon(Icons.grass),
                      label: const Text('Culturas e safras'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _abrir(
                        AnaliseSoloScreen(
                          talhaoId: widget.talhaoId,
                          talhaoNome: (_talhao['nome'] ?? '').toString(),
                        ),
                      ),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Análise de solo'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Histórico', style: textos.titleLarge),
                const SizedBox(height: 12),
                if (eventos.isEmpty)
                  Text(
                    'Ainda não há registros. Use os botões acima para anotar '
                    'a primeira cultura ou análise de solo.',
                    style: textos.bodySmall,
                  )
                else
                  for (final e in eventos) _LinhaHistorico(evento: e),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinhaHistorico extends StatelessWidget {
  const _LinhaHistorico({required this.evento});

  final _Evento evento;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              Formatadores.dataDoServidor(evento.data),
              style: textos.bodySmall?.copyWith(fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.verde, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.tipo, style: textos.titleMedium),
                  Text(evento.descricao, style: textos.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
