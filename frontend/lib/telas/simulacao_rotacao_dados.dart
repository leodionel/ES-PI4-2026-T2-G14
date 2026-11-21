import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';
import 'perfil_screen.dart';

class SimulacaoRotacao extends StatefulWidget {
  const SimulacaoRotacao({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  State<SimulacaoRotacao> createState() => _SimulacaoRotacaoState();
}

class _SimulacaoRotacaoState extends State<SimulacaoRotacao> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = ApiClient();
  final _tokenStorage = TokenStorage();

  List<Map<String, dynamic>> _talhoes = [];
  List<Map<String, dynamic>> _culturas = [];
  final Set<String> _culturasSelecionadas = {};
  String? _talhaoSelecionado;
  Map<String, dynamic>? _resultado;
  String? _erro;
  bool _carregando = true;
  bool _simulando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final token = await _tokenStorage.lerToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      final respostas = await Future.wait([
        _api.get('/api/talhoes', token: token),
        _api.get('/api/culturas', token: token),
      ]);
      final talhoes = _mapas(respostas[0]);
      final culturas = _mapas(respostas[1]);
      if (!mounted) return;
      setState(() {
        _talhoes = talhoes;
        _culturas = culturas;
        _talhaoSelecionado = talhoes.isEmpty ? null : _id(talhoes.first);
        _culturasSelecionadas
          ..clear()
          ..addAll(culturas.take(2).map(_id));
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = erro.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> _mapas(dynamic resposta) {
    if (resposta is! List) {
      throw const FormatException('O servidor retornou uma lista inválida.');
    }
    return resposta
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _id(Map<String, dynamic> item) => item['id']?.toString() ?? '';

  Future<void> _simular() async {
    final talhaoId = _talhaoSelecionado;
    if (talhaoId == null || talhaoId.isEmpty) return;
    if (_culturasSelecionadas.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione de 2 a 3 culturas para comparar.'),
        ),
      );
      return;
    }
    setState(() {
      _simulando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final token = await _tokenStorage.lerToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      final resposta = await _api.post('/api/talhoes/$talhaoId/simulacoes', {
        'culturaIds': _culturasSelecionadas.toList(),
      }, token: token);
      if (mounted) setState(() => _resultado = resposta);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro.toString());
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  void _alternarCultura(String id, bool selecionada) {
    setState(() {
      _resultado = null;
      if (selecionada) {
        if (_culturasSelecionadas.length < 3) {
          _culturasSelecionadas.add(id);
        }
      } else {
        _culturasSelecionadas.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: desktop
              ? null
              : AppBar(
                  backgroundColor: AppColors.painel,
                  foregroundColor: AppColors.verdeEscuro,
                  title: const Text('Simulação de Rotação'),
                ),
          drawer: desktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.painel,
                  child: SafeArea(child: _menuLateral()),
                ),
          body: SafeArea(
            top: desktop,
            child: Row(
              children: [
                if (desktop) _menuLateral(),
                Expanded(child: _conteudo()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuLateral() => Container(
    width: 180,
    color: AppColors.painel,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Prontuário Digital do Talhão',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.verdeEscuro,
          ),
        ),
        const SizedBox(height: 24),
        _itemMenu(Icons.grid_view_outlined, 'Dashboard'),
        _itemMenu(Icons.layers_outlined, 'Talhões'),
        _itemMenu(
          Icons.energy_savings_leaf_outlined,
          'Simulação de Rotação',
          selecionado: true,
        ),
        _itemMenu(
          Icons.person_outline,
          'Perfil',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const PerfilScreen())),
        ),
      ],
    ),
  );

  Widget _itemMenu(
    IconData icone,
    String texto, {
    bool selecionado = false,
    VoidCallback? onTap,
  }) => ListTile(
    dense: true,
    selected: selecionado,
    leading: Icon(icone, size: 18),
    title: Text(texto, style: const TextStyle(fontSize: 12)),
    onTap: () {
      _scaffoldKey.currentState?.closeDrawer();
      if (onTap != null) {
        onTap();
      } else if (!selecionado) {
        widget.onNavigate?.call(texto);
      }
    },
  );

  Widget _conteudo() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: EdgeInsets.all(constraints.maxWidth < 500 ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulação de Rotação',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.verdeEscuro,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Compare culturas usando o histórico e as análises reais do talhão.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 24),
              if (_carregando) const Center(child: CircularProgressIndicator()),
              if (_erro != null) _erroWidget(),
              if (!_carregando) ...[
                if (_talhoes.isEmpty)
                  _aviso('Nenhum talhão cadastrado para esta conta.')
                else ...[
                  _secao('1. Escolha o talhão'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _talhoes.map(_talhaoChip).toList(),
                  ),
                  const SizedBox(height: 18),
                  _resumoTalhao(),
                  const SizedBox(height: 24),
                  _secao('2. Escolha de 2 a 3 culturas'),
                  const SizedBox(height: 8),
                  if (_culturas.isEmpty)
                    _aviso('O catálogo de culturas não está disponível.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _culturas.map(_culturaChip).toList(),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _simulando || _culturasSelecionadas.length < 2
                        ? null
                        : _simular,
                    icon: _simulando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.compare_arrows),
                    label: Text(
                      _simulando ? 'Calculando...' : 'Comparar culturas',
                    ),
                  ),
                  if (_resultado != null) ...[
                    const SizedBox(height: 24),
                    _resultadoWidget(),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _secao(String texto) => Text(
    texto,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.verdeEscuro,
    ),
  );

  Widget _talhaoChip(Map<String, dynamic> talhao) {
    final id = _id(talhao);
    final nome = talhao['nome']?.toString() ?? 'Talhão';
    final area = talhao['areaHa']?.toString();
    return ChoiceChip(
      label: Text(area == null ? nome : '$nome · $area ha'),
      selected: id == _talhaoSelecionado,
      onSelected: (_) => setState(() {
        _talhaoSelecionado = id;
        _resultado = null;
      }),
    );
  }

  Widget _culturaChip(Map<String, dynamic> cultura) {
    final id = _id(cultura);
    final nome = cultura['nome']?.toString() ?? id;
    return FilterChip(
      label: Text(nome),
      selected: _culturasSelecionadas.contains(id),
      onSelected: (selecionada) {
        if (selecionada && _culturasSelecionadas.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você pode comparar até 3 culturas por vez.'),
            ),
          );
          return;
        }
        _alternarCultura(id, selecionada);
      },
    );
  }

  Widget _resumoTalhao() {
    final talhao = _talhoes
        .where((item) => _id(item) == _talhaoSelecionado)
        .firstOrNull;
    if (talhao == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.painel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        children: [
          _dado('Área', '${talhao['areaHa'] ?? '—'} ha'),
          _dado('Safras registradas', '${talhao['totalPlantios'] ?? 0}'),
          _dado('Análises de solo', '${talhao['totalAnalises'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _dado(String rotulo, String valor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        rotulo,
        style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
      ),
      Text(
        valor,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.texto,
        ),
      ),
    ],
  );

  Widget _resultadoWidget() {
    final resposta = _resultado!;
    final status = Map<String, dynamic>.from(
      resposta['statusSolo'] as Map? ?? {},
    );
    final historico = (resposta['historicoConsiderado'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final cenarios = _mapas(resposta['cenarios'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secao('Resultado da simulação'),
        const SizedBox(height: 10),
        if (resposta['opcoesEquivalentes'] == true)
          _aviso(
            resposta['mensagemEquivalencia']?.toString() ??
                'As opções são equivalentes.',
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.painel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status do solo: ${status['status'] ?? 'Sem análise'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (historico.isNotEmpty)
                Text('Histórico considerado: ${historico.join(' · ')}'),
              if (status['aviso'] != null) Text(status['aviso'].toString()),
              if (status['motivos'] is List &&
                  (status['motivos'] as List).isNotEmpty)
                Text(
                  'Pontos de atenção: ${(status['motivos'] as List).join(', ')}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...cenarios.map(_cenarioCard),
        if (resposta['aviso'] != null) ...[
          const SizedBox(height: 8),
          Text(
            resposta['aviso'].toString(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ],
    );
  }

  Widget _cenarioCard(Map<String, dynamic> cenario) {
    final regras = _mapas(cenario['regras'] ?? []);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${cenario['culturaNome'] ?? 'Cultura'} · ${_rotuloClassificacao(cenario['classificacao']?.toString())}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.verdeEscuro,
            ),
          ),
          if (regras.isEmpty)
            const Text('Nenhuma regra adicional foi acionada.'),
          ...regras.map(
            (regra) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${regra['efeito'] ?? 'Informação'}: ${regra['mensagem'] ?? ''}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloClassificacao(String? valor) => switch (valor) {
    'RECOMENDADO' => 'Recomendado',
    'ACEITAVEL' => 'Aceitável',
    'NAO_RECOMENDADO' => 'Não recomendado',
    _ => valor ?? 'Sem classificação',
  };

  Widget _erroWidget() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EA),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Não foi possível carregar a simulação: $_erro'),
        TextButton.icon(
          onPressed: _carregarDados,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );

  Widget _aviso(String texto) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.painel,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(texto),
  );
}
