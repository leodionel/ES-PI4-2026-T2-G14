// Contribuição de Matheus Azevedo Teixeira RA: 25014927

// FEITO POR (Demetrius Valverde) RA: (25015035)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../data/repositories/perfil_repository.dart';

// Perfil do produtor e dados da propriedade (RF05). O e-mail é o login e não
// pode ser alterado. Para sair do app, use o menu.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;
  PerfilCompleto? _perfil;

  PerfilRepository get _repo => context.read<PerfilRepository>();

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
      final perfil = await _repo.buscar();

      if (mounted) setState(() => _perfil = perfil);
    } catch (e) {
      if (mounted) setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar(Future<void> Function() acao, String sucesso) async {
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

  Future<void> _editarUsuario() async {
    final perfil = _perfil!;

    final dados = await showDialog<({String nome, String telefone})>(
      context: context,
      builder: (_) =>
          _FormularioUsuario(nome: perfil.nome, telefone: perfil.telefone),
    );

    if (dados == null) return;

    await _salvar(
      () => _repo.atualizarUsuario(dados.nome, dados.telefone),
      'Dados atualizados.',
    );
  }

  Future<void> _editarPropriedade() async {
    final atual = _perfil!.propriedade;

    final dados = await showDialog<({String nome, String localizacao})>(
      context: context,
      builder: (_) => _FormularioPropriedadePerfil(propriedade: atual),
    );

    if (dados == null) return;

    await _salvar(
      () => _repo.salvarPropriedade(
        id: atual?.id,
        nome: dados.nome,
        localizacao: dados.localizacao,
      ),
      atual == null ? 'Propriedade cadastrada.' : 'Propriedade atualizada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando && _perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_perfil == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _erro ?? AppTextos.erroInesperado,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(texto: 'Tentar novamente', onPressed: _carregar),
              ],
            ),
          ),
        ),
      );
    }

    final perfil = _perfil!;
    final propriedade = perfil.propriedade;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Secao(
                  titulo: 'Dados pessoais',
                  rotuloAcao: 'Editar',
                  aoEditar: _ocupado ? null : _editarUsuario,
                  linhas: [
                    ('Nome', perfil.nome),
                    ('E-mail', perfil.email),
                    ('Telefone', _formatarTelefone(perfil.telefone)),
                  ],
                  rodape: 'O e-mail é o seu login e não pode ser alterado.',
                ),
                const SizedBox(height: 20),
                _Secao(
                  titulo: 'Propriedade',
                  rotuloAcao: propriedade == null ? 'Cadastrar' : 'Editar',
                  aoEditar: _ocupado ? null : _editarPropriedade,
                  linhas: propriedade == null
                      ? const []
                      : [
                          ('Nome', propriedade.nome),
                          ('Localização', propriedade.localizacao),
                        ],
                  vazio: 'Nenhuma propriedade cadastrada.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatarTelefone(String digitos) {
    if (digitos.length == 11) {
      return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 7)}-${digitos.substring(7)}';
    }
    if (digitos.length == 10) {
      return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 6)}-${digitos.substring(6)}';
    }
    return digitos;
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.rotuloAcao,
    required this.aoEditar,
    required this.linhas,
    this.rodape,
    this.vazio,
  });

  final String titulo;
  final String rotuloAcao;
  final VoidCallback? aoEditar;
  final List<(String, String)> linhas;
  final String? rodape;
  final String? vazio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(titulo, style: textos.titleLarge)),
                TextButton(onPressed: aoEditar, child: Text(rotuloAcao)),
              ],
            ),
            const SizedBox(height: 8),
            if (linhas.isEmpty && vazio != null)
              Text(vazio!, style: textos.bodySmall),
            for (final (rotulo, valor) in linhas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo,
                      style: textos.bodySmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(valor.isEmpty ? 'Não informado' : valor),
                  ],
                ),
              ),
            if (rodape != null)
              Text(rodape!, style: textos.bodySmall?.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Edição de nome e telefone (RF05). As regras são as mesmas do cadastro.
class _FormularioUsuario extends StatefulWidget {
  const _FormularioUsuario({required this.nome, required this.telefone});

  final String nome;
  final String telefone;

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _telefone;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.nome);
    _telefone = TextEditingController(text: widget.telefone);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  String _soDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop((nome: _nome.text.trim(), telefone: _soDigitos(_telefone.text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dados pessoais'),
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
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (valor) {
                    final nome = (valor ?? '').trim();
                    if (nome.length < 3 || nome.length > 120) {
                      return 'O nome deve ter entre 3 e 120 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _salvar(),
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(11) 99999-9999',
                  ),
                  validator: (valor) {
                    final digitos = _soDigitos(valor ?? '');
                    if (digitos.length != 10 && digitos.length != 11) {
                      return 'Informe o telefone com DDD.';
                    }
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

// Cadastro ou edição da propriedade (nome e localização).
class _FormularioPropriedadePerfil extends StatefulWidget {
  const _FormularioPropriedadePerfil({this.propriedade});

  final PropriedadePerfil? propriedade;

  @override
  State<_FormularioPropriedadePerfil> createState() =>
      _FormularioPropriedadePerfilState();
}

class _FormularioPropriedadePerfilState
    extends State<_FormularioPropriedadePerfil> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _localizacao;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.propriedade?.nome ?? '');
    _localizacao = TextEditingController(
      text: widget.propriedade?.localizacao ?? '',
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop((nome: _nome.text.trim(), localizacao: _localizacao.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.propriedade == null
            ? 'Cadastrar propriedade'
            : 'Editar propriedade',
      ),
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
                  decoration: const InputDecoration(
                    labelText: 'Nome da propriedade',
                  ),
                  validator: (valor) {
                    final nome = (valor ?? '').trim();
                    if (nome.isEmpty) return 'Informe o nome da propriedade.';
                    if (nome.length > 150) return 'Use no máximo 150 caracteres.';
                    return null;
                  },
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
                  validator: (valor) {
                    final texto = (valor ?? '').trim();
                    if (texto.isEmpty) return 'Informe a localização.';
                    if (texto.length > 255) return 'Use no máximo 255 caracteres.';
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
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.verdeEscuro),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
