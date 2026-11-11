
import 'package:flutter/material.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';

class RecuperacaoSenha extends StatefulWidget {
  const RecuperacaoSenha({super.key});

  @override
  State<RecuperacaoSenha> createState() =>
      _RecuperacaoSenhaState();
}

class _RecuperacaoSenhaState extends State<RecuperacaoSenha> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  void _enviarLink() {
    // Valida o e-mail.
    // O envio será implementado quando houver backend.
    if (!_formKey.currentState!.validate()) {
      return;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                    constraints:
                        const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.painel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          // Nome e ícone do aplicativo
                          Row(
                            children: [
                              const Icon(
                                Icons.eco_outlined,
                                color: AppColors.verdeEscuro,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppTextos.nomeApp,
                                  style: textos.titleLarge,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Título
                          Text(
                            'Esqueceu sua senha?',
                            style: textos.headlineMedium,
                          ),

                          const SizedBox(height: 8),

                          // Descrição
                          Text(
                            'Digite o seu email cadastrado '
                            'para recuperar sua senha.',
                            style: textos.bodySmall,
                          ),

                          const SizedBox(height: 32),

                          // Campo de e-mail
                          AppTextField(
                            controller: _emailController,
                            rotulo: 'Seu E-mail',
                            dica: AppTextos.emailExemplo,
                            validator: Validators.email,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.email,
                            ],
                            onFieldSubmitted: (_) =>
                                _enviarLink(),
                          ),

                          const SizedBox(height: 32),

                          // Botão de recuperação
                          AppButton(
                            texto: 'Enviar link de recuperação',
                            onPressed: _enviarLink,
                          ),

                          const SizedBox(height: 48),

                          // Retornar ao login
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Voltar para o login',
                            ),
                          ),
                        ],
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
}
