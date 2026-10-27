import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';
import 'login_view_model.dart';
import 'recuperacao_senha.dart';

// Tela de entrada do app
class Login extends StatefulWidget {
  const Login({super.key, this.aoCriarConta, this.aoRecuperarSenha});

  final VoidCallback? aoCriarConta;
  final VoidCallback? aoRecuperarSenha;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  void _entrar() {
    // Só envia quando os campos estão válidos
    if (_formKey.currentState!.validate()) {
      context.read<LoginViewModel>().entrar(
        _emailController.text,
        _senhaController.text,
      );
    }
  }

  @override
  void dispose() {
    // Libera os controles quando a tela é encerrada
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Atualiza a tela quando o estado do login muda
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Permite rolar a tela quando o teclado aparece
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
                      child: Form(key: _formKey, child: _conteudo(vm)),
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

  Widget _conteudo(LoginViewModel vm) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 32),
        Text(AppTextos.loginTitulo, style: textos.headlineMedium),
        const SizedBox(height: 8),
        Text(AppTextos.loginDescricao, style: textos.bodySmall),
        const SizedBox(height: 32),
        AppTextField(
          controller: _emailController,
          rotulo: AppTextos.email,
          dica: AppTextos.emailExemplo,
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          enabled: !vm.carregando,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _senhaController,
          rotulo: AppTextos.senha,
          dica: AppTextos.senhaDica,
          validator: Validators.senhaLogin,
          senha: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !vm.carregando,
          onFieldSubmitted: (_) {
            if (!vm.carregando) _entrar();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: vm.carregando
    ? null
    : () {
        if (widget.aoRecuperarSenha != null) {
          widget.aoRecuperarSenha!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const RecuperacaoSenha(),
            ),
          );
        }
      },
            child: const Text(AppTextos.esqueciSenha),
          ),
        ),
        const SizedBox(height: 12),

        // Exibe o erro sem apagar o que foi digitado
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
          texto: AppTextos.entrar,
          textoCarregando: AppTextos.entrando,
          carregando: vm.carregando,
          onPressed: _entrar,
        ),
        const SizedBox(height: 24),
        Text(
          AppTextos.semConta,
          textAlign: TextAlign.center,
          style: textos.bodySmall,
        ),
        TextButton(
          onPressed: vm.carregando ? null : widget.aoCriarConta,
          child: const Text(AppTextos.criarConta),
        ),
      ],
    );
  }
}
