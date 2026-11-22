// #Matheus Azevedo Teixeira, RA:25014927

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatadores.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/campo_data.dart';
import '../data/repositories/perfil_repository.dart';
import '../data/repositories/talhao_repository.dart';

// Registro e consulta de análises de solo de um talhão (RF12). Todos os
// campos do laudo são obrigatórios. O status do solo é calculado no servidor.
class AnaliseSoloScreen extends StatefulWidget {
  const AnaliseSoloScreen({
    super.key,
    required this.talhaoId,
    required this.talhaoNome,
  });

  final String talhaoId;
  final String talhaoNome;

  @override
  State<AnaliseSoloScreen> createState() => _AnaliseSoloScreenState();
}

class _AnaliseSoloScreenState extends State<AnaliseSoloScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ph = TextEditingController();
  final _fosforo = TextEditingController();
  final _potassio = TextEditingController();
  final _saturacao = TextEditingController();

  DateTime? _data;
  // Muda a chave do campo de data para limpá-lo depois de salvar.
  int _geracaoFormulario = 0;

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  String? _erroEnvio;
  List<Map<String, dynamic>> _analises = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _ph.dispose();
    _fosforo.dispose();
    _potassio.dispose();
    _saturacao.dispose();
    super.dispose();
  }

  String _mensagem(Object e) =>
      e is AppException ? e.mensagem : AppTextos.erroInesperado;

  Future<void> _carregar() async {
    final repo = context.read<TalhaoRepository>();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await repo.analises(widget.talhaoId);

      if (mounted) setState(() => _analises = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _registrar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    final talhoes = context.read<TalhaoRepository>();
    final perfis = context.read<PerfilRepository>();

    setState(() {
      _salvando = true;
      _erroEnvio = null;
    });

    try {
      final propriedade = (await perfis.buscar()).propriedade;

      if (propriedade == null) {
        throw const AppException(
          tipo: TipoErro.validacao,
          mensagem: 'Cadastre a propriedade antes de registrar uma análise.',
        );
      }

      await talhoes.registrarAnalise(
        propriedadeId: propriedade.id,
        talhaoId: widget.talhaoId,
        dataColeta: Formatadores.dataParaServidor(_data!),
        ph: Formatadores.numero(_ph.text)!,
        fosforo: Formatadores.numero(_fosforo.text)!,
        potassio: Formatadores.numero(_potassio.text)!,
        saturacaoBases: Formatadores.numero(_saturacao.text)!,
      );

      if (!mounted) return;

      _ph.clear();
      _fosforo.clear();
      _potassio.clear();
      _saturacao.clear();

      setState(() {
        _data = null;
        _geracaoFormulario++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análise de solo registrada.')),
      );

      await _carregar();
    } catch (e) {
      if (mounted) setState(() => _erroEnvio = _mensagem(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Valida um número obrigatório dentro de um intervalo.
  String? Function(String?) _numeroEntre(String nome, double minimo, [double? maximo]) {
    return (texto) {
      final valor = Formatadores.numero(texto);

      if (valor == null) return 'Informe $nome.';
      if (valor < minimo) return '$nome não pode ser menor que ${Formatadores.decimal(minimo, casas: 0)}.';
      if (maximo != null && valor > maximo) {
        return '$nome não pode ser maior que ${Formatadores.decimal(maximo, casas: 0)}.';
      }

      return null;
    };
  }

  Widget _campoNumero(
    TextEditingController controller,
    String rotulo,
    String? Function(String?) validar, {
    String? dica,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_salvando,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(labelText: rotulo, hintText: dica),
      validator: validar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Análise de solo · ${widget.talhaoNome}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informe os valores do laudo de laboratório. Os parâmetros '
                  'seguem as classes do Boletim Técnico 100 do IAC. O status do '
                  'solo é calculado a partir da análise mais recente.',
                  style: textos.bodySmall,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nova análise', style: textos.titleLarge),
                          const SizedBox(height: 16),
                          CampoData(
                            key: ValueKey('data-$_geracaoFormulario'),
                            rotulo: 'Data da coleta',
                            valor: _data,
                            ultima: DateTime.now(),
                            mensagemObrigatorio: 'Informe a data da coleta.',
                            enabled: !_salvando,
                            aoMudar: (d) => _data = d,
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, c) {
                              final duas = c.maxWidth >= 480;
                              final largura = duas
                                  ? (c.maxWidth - 16) / 2
                                  : c.maxWidth;

                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: largura,
                                    child: _campoNumero(
                                      _ph,
                                      'pH (CaCl₂)',
                                      _numeroEntre('o pH', 0, 14),
                                      dica: 'Ex.: 5,2',
                                    ),
                                  ),
                                  SizedBox(
                                    width: largura,
                                    child: _campoNumero(
                                      _fosforo,
                                      'Fósforo - P resina (mg/dm³)',
                                      _numeroEntre('o fósforo', 0),
                                      dica: 'Ex.: 18',
                                    ),
                                  ),
                                  SizedBox(
                                    width: largura,
                                    child: _campoNumero(
                                      _potassio,
                                      'Potássio - K (mmolc/dm³)',
                                      _numeroEntre('o potássio', 0),
                                      dica: 'Ex.: 2,4',
                                    ),
                                  ),
                                  SizedBox(
                                    width: largura,
                                    child: _campoNumero(
                                      _saturacao,
                                      'Saturação por bases - V (%)',
                                      _numeroEntre('a saturação por bases', 0, 100),
                                      dica: 'Ex.: 58',
                                    ),
                                  ),
                                ],
                              );
                            },
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
                            texto: 'Registrar análise',
                            textoCarregando: 'Salvando...',
                            carregando: _salvando,
                            onPressed: _registrar,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Análises registradas', style: textos.titleLarge),
                const SizedBox(height: 12),
                _lista(textos),
              ],
            ),
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

    if (_analises.isEmpty) {
      return Text(
        'Nenhuma análise registrada para este talhão.',
        style: textos.bodySmall,
      );
    }

    String valor(dynamic v) => v is num ? Formatadores.decimal(v.toDouble(), casas: 1) : '-';

    return Column(
      children: [
        for (final a in _analises)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatadores.dataDoServidor(a['dataColeta']),
                    style: textos.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'pH ${valor(a['ph'])} · P ${valor(a['fosforo'])} mg/dm³ · '
                    'K ${valor(a['potassio'])} mmolc/dm³ · V ${valor(a['saturacaoBases'])}%',
                    style: textos.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
