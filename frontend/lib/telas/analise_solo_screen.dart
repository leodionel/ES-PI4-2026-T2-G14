import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';

class AnaliseSoloScreen extends StatefulWidget {
  const AnaliseSoloScreen({super.key, required this.talhaoId});
  final String talhaoId;
  @override
  State<AnaliseSoloScreen> createState() => _AnaliseSoloScreenState();
}

class _AnaliseSoloScreenState extends State<AnaliseSoloScreen> {
  final _form = GlobalKey<FormState>();
  final _data = TextEditingController();
  final _observacoes = TextEditingController();
  final _campos = {
    for (final chave in ['ph', 'fosforo', 'potassio', 'saturacaoBases'])
      chave: TextEditingController(),
  };
  bool _salvando = false;
  DateTime? _coleta;
  @override
  void dispose() {
    _data.dispose();
    _observacoes.dispose();
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar(DadosTalhao dados, VoidCallback atualizar) async {
    if (_salvando || !_form.currentState!.validate()) return;
    if (dados.propriedade == null) return;
    setState(() => _salvando = true);
    try {
      await context.read<DadosRepository>().salvar('/api/analises-solo', {
        'talhaoId': dados.id,
        'propriedadeId': dados.propriedade!['id'],
        'dataColeta': _coleta!.toIso8601String().substring(0, 10),
        for (final c in _campos.entries)
          c.key: double.parse(c.value.text.replaceAll(',', '.')),
        'observacoes': _observacoes.text.trim(),
      });
      if (!mounted) return;
      _data.clear();
      _coleta = null;
      _observacoes.clear();
      for (final c in _campos.values) {
        c.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análise salva com sucesso.')),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Análises de solo')),
    body: PaginaDados<DadosTalhao>(
      carregar: () => context.read<DadosRepository>().detalhe(widget.talhaoId),
      construir: (dados, atualizar) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(dados.nome, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${numeroDado(dados.talhao['areaHa'])} ha • Status atual: ${statusDado(dados.status['status'])}',
          ),
          const Text(
            'O status é calculado a partir da última análise. Saudável significa ausência de alertas nos indicadores avaliados.',
          ),
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _data,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data da coleta',
                  ),
                  validator: (_) =>
                      _coleta == null ? 'Selecione uma data.' : null,
                  onTap: _salvando
                      ? null
                      : () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: _coleta ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (data != null && mounted) {
                            setState(() {
                              _coleta = data;
                              _data.text = dataDado(data.toIso8601String());
                            });
                          }
                        },
                ),
                for (final c in {
                  'ph': 'pH (CaCl₂)',
                  'fosforo': 'Fósforo (P resina, mg/dm³)',
                  'potassio': 'Potássio (mmolc/dm³)',
                  'saturacaoBases': 'Saturação por bases (%)',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: _campos[c.key],
                      enabled: !_salvando,
                      decoration: InputDecoration(labelText: c.value),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (texto) {
                        final valor = double.tryParse(
                          (texto ?? '').replaceAll(',', '.'),
                        );
                        final maximo = c.key == 'ph'
                            ? 14
                            : c.key == 'saturacaoBases'
                            ? 100
                            : double.infinity;
                        return valor == null ||
                                !valor.isFinite ||
                                valor < 0 ||
                                valor > maximo
                            ? 'Informe um valor válido entre 0 e ${maximo.isInfinite ? 'um número positivo' : maximo}.'
                            : null;
                      },
                    ),
                  ),
                TextFormField(
                  controller: _observacoes,
                  enabled: !_salvando,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _salvando || dados.propriedade == null
                      ? null
                      : () => _salvar(dados, atualizar),
                  child: Text(_salvando ? 'Salvando...' : 'Registrar análise'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Histórico de análises',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (dados.analises.isEmpty) const Text('Nenhuma análise cadastrada.'),
          for (final a in dados.analises)
            Card(
              child: ListTile(
                title: Text(dataDado(a['dataColeta'])),
                subtitle: Text(
                  'pH: ${numeroDado(a['ph'])} • P: ${numeroDado(a['fosforo'])} mg/dm³\nK: ${numeroDado(a['potassio'])} mmolc/dm³ • V: ${numeroDado(a['saturacaoBases'])}%\n${a['observacoes'] ?? ''}',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
