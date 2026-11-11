import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/validators.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/auth_layout.dart';
import 'login_view_model.dart';

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
    final vm = context.read<LoginViewModel>();

    if (vm.carregando) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    vm.entrar(_emailController.text.trim(), _senhaController.text);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return AuthLayout(
      titulo: AppTextos.loginTitulo,
      descricao: AppTextos.loginDescricao,
      icone: Icons.lock_person_outlined,
      etiqueta: 'BEM-VINDO DE VOLTA',
      conteudo: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // E-mail.
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

              const SizedBox(height: 18),

              // Senha.
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
                  if (!vm.carregando) {
                    _entrar();
                  }
                },
              ),

              const SizedBox(height: 4),

              // Recuperação de senha.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: vm.carregando ? null : widget.aoRecuperarSenha,
                  child: const Text(
                    AppTextos.esqueciSenha,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Erro vindo da ViewModel.
              if (vm.erro != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.terracota.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.terracota,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            vm.erro!,
                            style: const TextStyle(
                              color: AppColors.terracota,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão de login.
              AppButton(
                texto: AppTextos.entrar,
                textoCarregando: 'Entrando...',
                carregando: vm.carregando,
                onPressed: _entrar,
              ),

              // Só mostra cadastro quando a rota existir.
              if (widget.aoCriarConta != null) ...[
                const SizedBox(height: 28),

                const Divider(color: AppColors.borda),

                const SizedBox(height: 12),

                Text(
                  AppTextos.semConta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textoSecundario,
                  ),
                ),

                const SizedBox(height: 4),

                TextButton(
                  onPressed: vm.carregando ? null : widget.aoCriarConta,
                  child: const Text(
                    AppTextos.criarConta,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
