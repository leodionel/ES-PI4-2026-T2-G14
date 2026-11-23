// FEITO POR (Demetrius Valverde) RA: (25015035)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../data/repositories/simulacao_repository.dart';
import '../data/repositories/talhao_repository.dart';
import '../domain/models/resultado_simulacao.dart';
import '../domain/models/talhao_resumo.dart';
import '../ui/simulacao/recomendacoes_view.dart';

// Simulação de rotação (RF17 a RF21). Primeiro o produtor escolhe o talhão e
// de 2 a 3 culturas; depois vê os cenários lado a lado com a justificativa.
class SimulacaoRotacao extends StatefulWidget {
  const SimulacaoRotacao({super.key});

  @override
  State<SimulacaoRotacao> createState() => _SimulacaoRotacaoState();
}

class _SimulacaoRotacaoState extends State<SimulacaoRotacao> {
  static const int _minimo = 2;
  static const int _maximo = 3;

  bool _carregando = true;
  bool _simulando = false;
  bool _mostrandoResultado = false;
  String? _erro;
  String? _erroSimulacao;

  List<TalhaoResumo> _talhoes = const [];
  List<CulturaOpcao> _culturas = const [];
  String? _talhaoId;
  final Set<String> _selecionadas = <String>{};
  ResultadoSimulacao? _resultado;

  TalhaoResumo? get _talhao {
    for (final t in _talhoes) {
      if (t.id == _talhaoId) return t;
    }
    return null;
  }

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
      final listaTalhoes = await talhoes.listar();
      final listaCulturas = await simulacao.culturas();

      if (!mounted) return;

      setState(() {
        _talhoes = listaTalhoes;
        _culturas = listaCulturas;
        _talhaoId ??= listaTalhoes.isEmpty ? null : listaTalhoes.first.id;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _alternar(String id, bool marcada) {
    setState(() {
      if (marcada) {
        if (_selecionadas.length < _maximo) _selecionadas.add(id);
      } else {
        _selecionadas.remove(id);
      }
    });
  }

  Future<void> _simular() async {
    final talhaoId = _talhaoId;

    if (_simulando || talhaoId == null || _selecionadas.length < _minimo) {
      return;
    }

    final repo = context.read<SimulacaoRepository>();

    setState(() {
      _simulando = true;
      _mostrandoResultado = true;
      _erroSimulacao = null;
      _resultado = null;
    });

    try {
      final resultado = await repo.simular(talhaoId, _selecionadas.toList());

      if (mounted) setState(() => _resultado = resultado);
    } catch (e) {
      if (mounted) setState(() => _erroSimulacao = _mensagem(e));
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  void _novaSimulacao() {
    setState(() {
      _mostrandoResultado = false;
      _resultado = null;
      _erroSimulacao = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrandoResultado) {
      return RecomendacoesView(
        nomeTalhao: _talhao?.nome ?? '',
        resultado: _resultado,
        carregando: _simulando,
        erro: _erroSimulacao,
        aoTentarNovamente: _simular,
        aoNovaSimulacao: _novaSimulacao,
      );
    }

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _Mensagem(
        texto: _erro!,
        botao: 'Tentar novamente',
        aoTocar: _carregar,
      );
    }

    if (_talhoes.isEmpty) {
      return const _Mensagem(
        texto:
            'Cadastre ao menos um talhão na aba Talhões para simular a rotação.',
      );
    }

    return _formulario(context);
  }

  Widget _formulario(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final faltam = _minimo - _selecionadas.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Simulação de rotação', style: textos.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Compare de 2 a 3 culturas para a próxima safra do talhão.',
                style: textos.bodySmall,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _talhaoId,
                decoration: const InputDecoration(labelText: 'Talhão'),
                items: [
                  for (final t in _talhoes)
                    DropdownMenuItem(value: t.id, child: Text(t.nome)),
                ],
                onChanged: (id) => setState(() => _talhaoId = id),
              ),
              const SizedBox(height: 24),
              Text('Culturas a comparar', style: textos.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${_selecionadas.length} de $_maximo escolhidas',
                style: textos.bodySmall?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cultura in _culturas)
                    FilterChip(
                      label: Text(cultura.nome),
                      selected: _selecionadas.contains(cultura.id),
                      selectedColor: AppColors.selecao,
                      checkmarkColor: AppColors.verdeEscuro,
                      // Com o limite atingido, só dá para desmarcar.
                      onSelected:
                          _selecionadas.contains(cultura.id) ||
                              _selecionadas.length < _maximo
                          ? (marcada) => _alternar(cultura.id, marcada)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (faltam > 0)
                Text(
                  'Escolha mais $faltam ${faltam == 1 ? 'cultura' : 'culturas'} para comparar.',
                  style: textos.bodySmall?.copyWith(fontSize: 14),
                ),
              const SizedBox(height: 24),
              AppButton(
                texto: 'Simular rotação',
                onPressed: _selecionadas.length >= _minimo ? _simular : null,
              ),
              const SizedBox(height: 16),
              Text(AppTextos.avisoRecomendacao, style: textos.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.botao, this.aoTocar});

  final String texto;
  final String? botao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (botao != null) ...[
                const SizedBox(height: 16),
                AppButton(texto: botao!, onPressed: aoTocar),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
