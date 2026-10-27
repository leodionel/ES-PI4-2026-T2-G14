import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_textos.dart';
import '../core/base_view_model.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/validators.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import 'cadastro_view_model.dart';

//Tela de criacao da conta
class Cadastro extends StatefulWidget {
  const Cadastro({super.key, required this.aoVoltarLogin});

  final VoidCallback aoVoltarLogin;

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  Future<void> _cadastrar() async {
    final vm = context.read<CadastroViewModel>();

    if (vm.carregando) return;

    //Confere todos os campos antes de enviar
    if (!_formKey.currentState!.validate()) return;

    await vm.cadastrar(
      _nomeController.text,
      _emailController.text,
      _telefoneController.text,
      _senhaController.text,
    );
    // Evita usar a tela caso ela já tenha sido fechada
    if (!mounted) return;

    if (vm.status == UiStatus.sucesso) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppTextos.cadastroSucesso)));

      widget.aoVoltarLogin();
    }
  }

  @override
  void dispose() {
    // Libera os controles quando a tela é encerrada
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CadastroViewModel>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Permite rolar o formulário quando o teclado abre
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.painel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cabecalho(),
                            const SizedBox(height: 28),
                            ..._campos(vm),
                            const SizedBox(height: 24),
                            _acoes(vm),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.eco_outlined,
              color: AppColors.verdeEscuro,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(AppTextos.nomeApp, style: textos.titleLarge)),
          ],
        ),
        const SizedBox(height: 28),
        Text(AppTextos.cadastroTitulo, style: textos.headlineMedium),
        const SizedBox(height: 8),
        Text(AppTextos.cadastroDescricao, style: textos.bodySmall),
      ],
    );
  }

  List<Widget> _campos(CadastroViewModel vm) {
    return [
      AppTextField(
        controller: _nomeController,
        rotulo: AppTextos.nomeCompleto,
        dica: AppTextos.nomeDica,
        validator: Validators.nome,
        keyboardType: TextInputType.name,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        enabled: !vm.carregando,
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _emailController,
        rotulo: AppTextos.email,
        dica: AppTextos.emailExemplo,
        validator: Validators.email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        enabled: !vm.carregando,
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _telefoneController,
        rotulo: AppTextos.telefone,
        dica: AppTextos.telefoneDica,
        validator: Validators.telefone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        enabled: !vm.carregando,
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _senhaController,
        rotulo: AppTextos.senha,
        dica: AppTextos.senhaDica,
        validator: Validators.senhaCadastro,
        senha: true,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        enabled: !vm.carregando,
      ),
      const SizedBox(height: 20),
      AppTextField(
        controller: _confirmacaoController,
        rotulo: AppTextos.confirmarSenha,
        dica: AppTextos.confirmarSenhaDica,
        validator: (valor) {
          return Validators.confirmarSenha(valor, _senhaController.text);
        },
        senha: true,
        textInputAction: TextInputAction.done,
        enabled: !vm.carregando,
        onFieldSubmitted: (_) => _cadastrar(),
      ),
    ];
  }

  Widget _acoes(CadastroViewModel vm) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mantém os campos preenchidos se ocorrer um erro
        if (vm.erro != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              vm.erro!,
              style: textos.bodyMedium?.copyWith(color: AppColors.terracota),
            ),
          ),
          const SizedBox(height: 16),
        ],
        AppButton(
          texto: AppTextos.cadastrar,
          textoCarregando: AppTextos.cadastrando,
          carregando: vm.carregando,
          onPressed: _cadastrar,
        ),
        const SizedBox(height: 24),
        Text(
          AppTextos.jaTenhoConta,
          textAlign: TextAlign.center,
          style: textos.bodySmall,
        ),
        TextButton(
          onPressed: vm.carregando ? null : widget.aoVoltarLogin,
          child: const Text(AppTextos.voltarLogin),
        ),
      ],
    );
  }
}
