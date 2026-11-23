// FEITO POR (LUCAS KENDI) RA: (25014845) e FEITO POR (Demetrius Valverde) RA: (25015035)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/pdf_export_service.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/status_chip.dart';
import '../data/repositories/talhao_repository.dart';
import '../domain/models/talhao_resumo.dart';
import 'talhaodetalhe.dart';

// Lista de talhões (RF06 e RF07), com cadastro, edição e exclusão (RF08, RF09).
class TalhoesScreen extends StatefulWidget {
  const TalhoesScreen({super.key});

  @override
  State<TalhoesScreen> createState() => _TalhoesScreenState();
}

class _TalhoesScreenState extends State<TalhoesScreen> {
  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;
  List<TalhaoResumo> _talhoes = const [];

  TalhaoRepository get _repo => context.read<TalhaoRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  String _mensagem(Object e) =>
      e is AppException ? e.mensagem : AppTextos.erroInesperado;

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _repo.listar();

      if (!mounted) return;

      setState(() => _talhoes = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Executa uma ação de escrita sem permitir cliques repetidos.
  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    if (_ocupado) return;

    setState(() => _ocupado = true);

    try {
      await acao();

      if (!mounted) return;

      _aviso(sucesso);
      await _carregar();
    } catch (e) {
      if (mounted) _aviso(_mensagem(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cadastrar() async {
    if (_ocupado) return;

    try {
      // Cada produtor tem uma propriedade (RN11); ela é criada junto do
      // primeiro talhão.
      final existe = await _repo.temPropriedade();

      if (!mounted) return;

      if (!existe) {
        final dados = await showDialog<({String nome, String localizacao})>(
          context: context,
          builder: (_) => const _FormularioPropriedade(),
        );

        if (dados == null || !mounted) return;

        await _repo.criarPropriedade(dados.nome, dados.localizacao);
      }

      if (!mounted) return;

      final talhao = await showDialog<({String nome, double area})>(
        context: context,
        builder: (_) => const _FormularioTalhao(),
      );

      if (talhao == null) return;

      await _executar(
        () => _repo.criar(talhao.nome, talhao.area),
        'Talhão cadastrado.',
      );
    } catch (e) {
      if (mounted) _aviso(_mensagem(e));
    }
  }

  Future<void> _editar(TalhaoResumo talhao) async {
    final dados = await showDialog<({String nome, double area})>(
      context: context,
      builder: (_) => _FormularioTalhao(talhao: talhao),
    );

    if (dados == null) return;

    await _executar(
      () => _repo.atualizar(talhao.id, dados.nome, dados.area),
      'Talhão atualizado.',
    );
  }

  Future<void> _excluir(TalhaoResumo talhao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoExclusao(talhao: talhao),
    );

    if (confirmou != true) return;

    await _executar(
      () => _repo.excluir(talhao.id, talhao.nome),
      'Talhão excluído.',
    );
  }

  Future<void> _abrirDetalhes(TalhaoResumo talhao) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProntuarioScreen(talhaoId: talhao.id),
      ),
    );

    // O prontuário pode ter mudado o status ou a cultura.
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth >= 700 ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Text('Talhões', style: textos.headlineMedium),
                        ElevatedButton.icon(
                          onPressed: _ocupado ? null : _cadastrar,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo talhão'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _corpo(textos),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _corpo(TextTheme textos) {
    if (_carregando && _talhoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              _erro!,
              style: textos.bodyMedium?.copyWith(color: AppColors.terracota),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(texto: 'Tentar novamente', onPressed: _carregar),
        ],
      );
    }

    if (_talhoes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nenhum talhão cadastrado', style: textos.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Informe o nome e a área do primeiro talhão para começar o '
                'prontuário.',
                style: textos.bodySmall,
              ),
              const SizedBox(height: 16),
              AppButton(texto: 'Cadastrar talhão', onPressed: _cadastrar),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final talhao in _talhoes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartaoTalhao(
              talhao: talhao,
              aoAbrir: () => _abrirDetalhes(talhao),
              aoEditar: () => _editar(talhao),
              aoExcluir: () => _excluir(talhao),
            ),
          ),
      ],
    );
  }
}

class _CartaoTalhao extends StatelessWidget {
  const _CartaoTalhao({
    required this.talhao,
    required this.aoAbrir,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final TalhaoResumo talhao;
  final VoidCallback aoAbrir;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final area = talhao.areaHa.toStringAsFixed(1).replaceAll('.', ',');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(talhao.nome, style: textos.titleMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$area ha · ${talhao.culturaAtual == null ? 'Sem cultura em andamento' : 'Cultura atual: ${talhao.culturaAtual}'}',
                      style: textos.bodySmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(talhao.status),
                        Text(
                          '${talhao.totalPlantios} safras · ${talhao.totalAnalises} análises',
                          style: textos.bodySmall?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações do talhão ${talhao.nome}',
                onSelected: (acao) {
                  if (acao == 'editar') aoEditar();
                  if (acao == 'excluir') aoExcluir();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Formulário de novo talhão ou de edição (nome e área em hectares).
class _FormularioTalhao extends StatefulWidget {
  const _FormularioTalhao({this.talhao});

  final TalhaoResumo? talhao;

  @override
  State<_FormularioTalhao> createState() => _FormularioTalhaoState();
}

class _FormularioTalhaoState extends State<_FormularioTalhao> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _area;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.talhao?.nome ?? '');
    _area = TextEditingController(
      text: widget.talhao == null
          ? ''
          : widget.talhao!.areaHa.toString().replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _area.dispose();
    super.dispose();
  }

  double? _lerArea(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop((nome: _nome.text.trim(), area: _lerArea(_area.text)!));
  }

  @override
  Widget build(BuildContext context) {
    final edicao = widget.talhao != null;

    return AlertDialog(
      title: Text(edicao ? 'Editar talhão' : 'Novo talhão'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nome,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome do talhão'),
                  validator: (valor) {
                    final nome = (valor ?? '').trim();
                    if (nome.isEmpty) return 'Informe o nome do talhão.';
                    if (nome.length > 100) return 'Use no máximo 100 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _area,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _salvar(),
                  decoration: const InputDecoration(
                    labelText: 'Área (hectares)',
                    hintText: 'Ex.: 12,5',
                  ),
                  validator: (valor) {
                    final area = _lerArea(valor);
                    if (area == null) return 'Informe a área em hectares.';
                    if (area <= 0) return 'A área deve ser maior que zero.';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

// Cadastro da propriedade, pedido antes do primeiro talhão (RN11).
class _FormularioPropriedade extends StatefulWidget {
  const _FormularioPropriedade();

  @override
  State<_FormularioPropriedade> createState() => _FormularioPropriedadeState();
}

class _FormularioPropriedadeState extends State<_FormularioPropriedade> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _localizacao = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor, String mensagem) =>
      (valor ?? '').trim().isEmpty ? mensagem : null;

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop((nome: _nome.text.trim(), localizacao: _localizacao.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cadastre sua propriedade'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Os talhões ficam dentro da sua propriedade. Informe o nome e onde ela fica.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome da propriedade',
                  ),
                  validator: (v) =>
                      _obrigatorio(v, 'Informe o nome da propriedade.'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _localizacao,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _salvar(),
                  decoration: const InputDecoration(
                    labelText: 'Localização',
                    hintText: 'Cidade e estado',
                  ),
                  validator: (v) => _obrigatorio(v, 'Informe a localização.'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Continuar')),
      ],
    );
  }
}

// Confirmação de exclusão (RF08 e RF09): mostra o que será removido, oferece
// o PDF e só libera o botão quando o nome é digitado.
class _DialogoExclusao extends StatefulWidget {
  const _DialogoExclusao({required this.talhao});

  final TalhaoResumo talhao;

  @override
  State<_DialogoExclusao> createState() => _DialogoExclusaoState();
}

class _DialogoExclusaoState extends State<_DialogoExclusao> {
  final _confirmacao = TextEditingController();
  bool _exportando = false;
  String? _erroPdf;

  @override
  void dispose() {
    _confirmacao.dispose();
    super.dispose();
  }

  // Ignora maiúsculas e espaços nas pontas, como o servidor.
  bool get _nomeConfere =>
      _confirmacao.text.trim().toLowerCase() ==
      widget.talhao.nome.trim().toLowerCase();

  Future<void> _exportarPdf() async {
    if (_exportando) return;

    setState(() {
      _exportando = true;
      _erroPdf = null;
    });

    try {
      final dados = await context.read<TalhaoRepository>().carregarProntuario(
        widget.talhao.id,
      );

      await PdfExportService.exportarProntuarioTalhao(
        talhao: dados.talhao,
        analises: dados.analises,
        plantios: dados.plantios,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _erroPdf = 'Não foi possível gerar o PDF.');
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.talhao;
    final textos = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Excluir ${t.nome}?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Serão removidas definitivamente ${t.totalPlantios} '
                '${t.totalPlantios == 1 ? 'safra' : 'safras'} e '
                '${t.totalAnalises} ${t.totalAnalises == 1 ? 'análise' : 'análises'} '
                'deste talhão. Não é possível desfazer.',
                style: textos.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _exportando ? null : _exportarPdf,
                icon: _exportando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_exportando ? 'Gerando PDF...' : 'Exportar prontuário em PDF'),
              ),
              if (_erroPdf != null) ...[
                const SizedBox(height: 6),
                Text(
                  _erroPdf!,
                  style: textos.bodySmall?.copyWith(color: AppColors.terracota),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _confirmacao,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Digite "${t.nome}" para confirmar',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.terracota),
          onPressed: _nomeConfere ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir talhão'),
        ),
      ],
    );
  }
}
