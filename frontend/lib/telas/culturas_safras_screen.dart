import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';

class CulturasSafrasScreen extends StatefulWidget {
  const CulturasSafrasScreen({super.key, required this.talhaoId});
  final String talhaoId;
  @override
  State<CulturasSafrasScreen> createState() => _CulturasSafrasScreenState();
}

class _CulturasSafrasScreenState extends State<CulturasSafrasScreen> {
  final _form = GlobalKey<FormState>();
  final _data = TextEditingController();
  DateTime? _plantio;
  String? _culturaId;
  bool _salvando = false;
  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<(DadosTalhao, List<Registro>)> _carregar() async {
    final repo = context.read<DadosRepository>();
    return (await repo.detalhe(widget.talhaoId), await repo.culturas());
  }

  Future<void> _salvar(VoidCallback atualizar) async {
    if (_salvando || !_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await context.read<DadosRepository>().salvar(
        '/api/talhoes/${Uri.encodeComponent(widget.talhaoId)}/plantios',
        {
          'culturaId': _culturaId,
          'dataPlantio': _plantio!.toIso8601String().substring(0, 10),
        },
      );
      if (!mounted) return;
      setState(() {
        _culturaId = null;
        _plantio = null;
        _data.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantio salvo com sucesso.')),
      );
      atualizar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _colher(Registro plantio, VoidCallback atualizar) async {
    if (_salvando) return;
    final inicio = DateTime.parse(plantio['dataPlantio'] as String);
    final hoje = DateTime.now();
    if (inicio.isAfter(hoje)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data do plantio ainda não chegou.')),
      );
      return;
    }
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: inicio,
      lastDate: hoje,
    );
    if (data == null || !mounted) return;
    setState(() => _salvando = true);
    try {
      await context.read<DadosRepository>().atualizar(
        '/api/talhoes/${Uri.encodeComponent(widget.talhaoId)}/plantios/${Uri.encodeComponent(plantio['plantioId'] as String)}/colheita',
        {'dataColheita': data.toIso8601String().substring(0, 10)},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Colheita registrada.')));
      atualizar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível registrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Culturas e safras')),
    body: PaginaDados<(DadosTalhao, List<Registro>)>(
      carregar: _carregar,
      construir: (resultado, atualizar) {
        final (dados, culturas) = resultado;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(dados.nome, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${numeroDado(dados.talhao['areaHa'])} ha • ${dados.culturaAtual}',
            ),
            const SizedBox(height: 24),
            if (culturas.isEmpty)
              const Text('Nenhuma cultura disponível no catálogo.'),
            Form(
              key: _form,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_culturaId),
                    initialValue: _culturaId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Cultura'),
                    items: culturas
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text('${c['nome']}'),
                          ),
                        )
                        .toList(),
                    onChanged: _salvando
                        ? null
                        : (id) => setState(() => _culturaId = id),
                    validator: (id) =>
                        id == null ? 'Selecione uma cultura.' : null,
                  ),
                  TextFormField(
                    controller: _data,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data do plantio',
                    ),
                    validator: (_) =>
                        _plantio == null ? 'Selecione uma data.' : null,
                    onTap: _salvando
                        ? null
                        : () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: _plantio ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (data != null && mounted) {
                              setState(() {
                                _plantio = data;
                                _data.text = dataDado(data.toIso8601String());
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _salvando || culturas.isEmpty
                        ? null
                        : () => _salvar(atualizar),
                    child: Text(
                      _salvando ? 'Salvando...' : 'Registrar plantio',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Histórico de safras',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (dados.plantios.isEmpty)
              const Text('Nenhum plantio cadastrado.'),
            for (final p in dados.plantios.reversed)
              Card(
                child: ListTile(
                  title: Text('${p['culturaNome']}'),
                  subtitle: Text(
                    'Plantio: ${dataDado(p['dataPlantio'])}\nColheita: ${p['dataColheita'] == null ? 'Em aberto' : dataDado(p['dataColheita'])}',
                  ),
                  trailing: p['dataColheita'] == null
                      ? TextButton(
                          onPressed: _salvando
                              ? null
                              : () => _colher(p, atualizar),
                          child: const Text('Registrar colheita'),
                        )
                      : null,
                ),
              ),
          ],
        );
      },
    ),
  );
}
