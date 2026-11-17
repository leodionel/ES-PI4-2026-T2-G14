import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';

class SimulacaoRotacao extends StatefulWidget {
  const SimulacaoRotacao({super.key, this.talhaoId, this.onNavigate});
  final String? talhaoId;
  final ValueChanged<String>? onNavigate;
  @override
  State<SimulacaoRotacao> createState() => _SimulacaoRotacaoState();
}

class _SimulacaoRotacaoState extends State<SimulacaoRotacao> {
  String? _talhaoId;
  final Set<String> _selecionadas = {};
  Registro? _resultado;
  bool _calculando = false;
  String? _erro;
  @override
  void initState() {
    super.initState();
    _talhaoId = widget.talhaoId;
  }

  Future<(List<Registro>, List<Registro>)> _carregar() async {
    final repo = context.read<DadosRepository>();
    return (await repo.talhoes(), await repo.culturas());
  }

  Future<void> _simular() async {
    if (_calculando || _talhaoId == null || _selecionadas.length < 2) return;
    setState(() {
      _calculando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final resposta = await context.read<DadosRepository>().salvar(
        '/api/talhoes/${Uri.encodeComponent(_talhaoId!)}/simulacoes',
        {'culturaIds': _selecionadas.toList()},
      );
      if (mounted) setState(() => _resultado = resposta);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simulação de rotação')),
    body: PaginaDados<(List<Registro>, List<Registro>)>(
      carregar: _carregar,
      construir: (dados, atualizar) {
        final (talhoes, culturas) = dados;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Escolha um talhão e de 2 a 3 culturas para comparar.'),
            if (talhoes.isEmpty) const Text('Cadastre um talhão para simular.'),
            DropdownButtonFormField<String>(
              initialValue: talhoes.any((t) => t['id'] == _talhaoId)
                  ? _talhaoId
                  : null,
              decoration: const InputDecoration(labelText: 'Talhão'),
              items: talhoes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['nome']}'),
                    ),
                  )
                  .toList(),
              onChanged: _calculando
                  ? null
                  : (id) => setState(() {
                      _talhaoId = id;
                      _resultado = null;
                      _erro = null;
                    }),
            ),
            const SizedBox(height: 16),
            if (culturas.isEmpty)
              const Text('Nenhuma cultura disponível no catálogo.'),
            Wrap(
              spacing: 8,
              children: [
                for (final c in culturas)
                  FilterChip(
                    label: Text('${c['nome']}'),
                    selected: _selecionadas.contains(c['id']),
                    onSelected: _calculando
                        ? null
                        : (selecionar) {
                            if (selecionar && _selecionadas.length == 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Compare no máximo três culturas.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              selecionar
                                  ? _selecionadas.add(c['id'] as String)
                                  : _selecionadas.remove(c['id']);
                              _resultado = null;
                              _erro = null;
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _calculando || _talhaoId == null || _selecionadas.length < 2
                  ? null
                  : _simular,
              child: Text(_calculando ? 'Calculando...' : 'Comparar culturas'),
            ),
            if (_erro != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(_erro!)),
            if (_resultado != null) ...[
              const SizedBox(height: 24),
              Text(
                'Solo: ${statusDado((_resultado!['statusSolo'] as Map)['status'])}',
              ),
              Text(
                'Histórico considerado: ${(_resultado!['historicoConsiderado'] as List).isEmpty ? 'Sem safras anteriores' : (_resultado!['historicoConsiderado'] as List).join(', ')}',
              ),
              if (_resultado!['opcoesEquivalentes'] == true)
                Text(
                  '${_resultado!['mensagemEquivalencia'] ?? 'As opções são equivalentes.'}',
                ),
              for (final c in _resultado!['cenarios'] as List)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c['culturaNome']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          const {
                                'RECOMENDADO': 'Recomendado',
                                'ACEITAVEL': 'Aceitável',
                                'NAO_RECOMENDADO': 'Não recomendado',
                              }[c['classificacao']] ??
                              '${c['classificacao']}',
                        ),
                        for (final regra in c['regras'] as List)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${regra['regraId']}: ${regra['mensagem']}',
                                ),
                                for (final fonte in regra['fontes'] as List)
                                  SelectableText(
                                    'Fonte: ${fonte['titulo']} ${fonte['url'] ?? ''}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            Text(
              _resultado?['aviso'] as String? ??
                  'A recomendação é apoio à decisão e não substitui o acompanhamento de um engenheiro agrônomo.',
            ),
          ],
        );
      },
    ),
  );
}
