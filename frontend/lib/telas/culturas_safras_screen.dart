// FEITO POR (LUCAS KENDI) RA: (25014845)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatadores.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/campo_data.dart';
import '../data/repositories/simulacao_repository.dart';
import '../data/repositories/talhao_repository.dart';

// Culturas e safras de um talhão (RF10 e RF11): registro do plantio, da
// colheita e a lista em ordem cronológica.
class CulturasSafrasScreen extends StatefulWidget {
  const CulturasSafrasScreen({
    super.key,
    required this.talhaoId,
    required this.talhaoNome,
  });

  final String talhaoId;
  final String talhaoNome;

  @override
  State<CulturasSafrasScreen> createState() => _CulturasSafrasScreenState();
}

class _CulturasSafrasScreenState extends State<CulturasSafrasScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _culturaId;
  DateTime? _dataPlantio;
  int _geracaoFormulario = 0;

  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;
  String? _erroEnvio;
  List<CulturaOpcao> _culturas = const [];
  List<Map<String, dynamic>> _safras = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  String _mensagem(Object e) =>
      e is AppException ? e.mensagem : AppTextos.erroInesperado;

  Future<void> _carregar() async {
    final talhoes = context.read<TalhaoRepository>();
    final simulacao = context.read<SimulacaoRepository>();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final culturas = await simulacao.culturas();
      final safras = await talhoes.plantios(widget.talhaoId);

      if (!mounted) return;

      setState(() {
        _culturas = culturas;
        _safras = safras;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _registrarPlantio() async {
    if (_ocupado || !_formKey.currentState!.validate()) return;

    final repo = context.read<TalhaoRepository>();

    setState(() {
      _ocupado = true;
      _erroEnvio = null;
    });

    try {
      await repo.registrarPlantio(
        widget.talhaoId,
        _culturaId!,
        Formatadores.dataParaServidor(_dataPlantio!),
      );

      if (!mounted) return;

      setState(() {
        _culturaId = null;
        _dataPlantio = null;
        _geracaoFormulario++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cultura registrada.')),
      );

      await _carregar();
    } catch (e) {
      if (mounted) setState(() => _erroEnvio = _mensagem(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // Pede a data e registra a colheita (RF11). Não aceita data anterior ao
  // plantio nem futura.
  Future<void> _registrarColheita(Map<String, dynamic> safra) async {
    if (_ocupado) return;

    final plantio = DateTime.tryParse((safra['dataPlantio'] ?? '').toString());
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: plantio ?? DateTime(2000),
      lastDate: hoje,
      helpText: 'Data da colheita',
    );

    if (data == null || !mounted) return;

    final repo = context.read<TalhaoRepository>();

    setState(() => _ocupado = true);

    try {
      await repo.registrarColheita(
        widget.talhaoId,
        (safra['plantioId'] ?? '').toString(),
        Formatadores.dataParaServidor(data),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colheita registrada.')),
      );

      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mensagem(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Culturas e safras · ${widget.talhaoNome}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registre o que foi plantado e quando foi colhido. A simulação '
                  'de rotação considera as duas últimas safras do talhão.',
                  style: textos.bodySmall,
                ),
                const SizedBox(height: 20),
                _formulario(textos),
                const SizedBox(height: 24),
                Text('Safras', style: textos.titleLarge),
                const SizedBox(height: 12),
                _lista(textos),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(TextTheme textos) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar plantio', style: textos.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('cultura-$_geracaoFormulario'),
                initialValue: _culturaId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cultura'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                items: [
                  for (final c in _culturas)
                    DropdownMenuItem(value: c.id, child: Text(c.nome)),
                ],
                onChanged: _ocupado ? null : (id) => _culturaId = id,
                validator: (id) => id == null ? 'Escolha a cultura.' : null,
              ),
              const SizedBox(height: 16),
              CampoData(
                key: ValueKey('plantio-$_geracaoFormulario'),
                rotulo: 'Data do plantio',
                valor: _dataPlantio,
                ultima: DateTime.now(),
                mensagemObrigatorio: 'Informe a data do plantio.',
                enabled: !_ocupado,
                aoMudar: (d) => _dataPlantio = d,
              ),
              if (_erroEnvio != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _erroEnvio!,
                    style: textos.bodyMedium?.copyWith(
                      color: AppColors.terracota,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(
                texto: 'Registrar plantio',
                textoCarregando: 'Salvando...',
                carregando: _ocupado,
                onPressed: _registrarPlantio,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lista(TextTheme textos) {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_erro!, style: textos.bodyMedium?.copyWith(color: AppColors.terracota)),
          const SizedBox(height: 12),
          AppButton(texto: 'Tentar novamente', onPressed: _carregar),
        ],
      );
    }

    if (_safras.isEmpty) {
      return Text('Nenhuma safra registrada neste talhão.', style: textos.bodySmall);
    }

    return Column(
      children: [
        for (final safra in _safras)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (safra['culturaNome'] ?? '').toString(),
                          style: textos.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Plantio: ${Formatadores.dataDoServidor(safra['dataPlantio'])}'
                          '${safra['dataColheita'] == null ? '' : ' · Colheita: ${Formatadores.dataDoServidor(safra['dataColheita'])}'}',
                          style: textos.bodySmall?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (safra['dataColheita'] == null)
                    OutlinedButton(
                      onPressed: _ocupado ? null : () => _registrarColheita(safra),
                      child: const Text('Registrar colheita'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
