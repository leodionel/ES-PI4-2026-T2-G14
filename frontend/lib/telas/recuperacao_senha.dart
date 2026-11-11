import 'package:flutter/material.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';

// Tela de recuperação de senha do produtor.
class RecuperacaoSenha extends StatefulWidget {
  const RecuperacaoSenha({
    super.key,
    this.aoSolicitarRecuperacao,
    this.aoVoltar,
  });

  // A ação real será fornecida pela integração com o backend.
  final Future<void> Function(String email)? aoSolicitarRecuperacao;
  final VoidCallback? aoVoltar;

  @override
  State<RecuperacaoSenha> createState() => _RecuperacaoSenhaState();
}

class _RecuperacaoSenhaState extends State<RecuperacaoSenha> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _carregando = false;
  bool _concluido = false;
  String? _erro;

  // Valida o e-mail e solicita a recuperação.
  Future<void> _enviarLink() async {
    if (_carregando || _concluido) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _erro = null;
    });

    final solicitar = widget.aoSolicitarRecuperacao;

    // Não informa envio realizado sem integração real.
    if (solicitar == null) {
      setState(() {
        _erro =
            'A recuperação de senha ainda não está '
            'conectada ao servidor.';
      });
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await solicitar(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _concluido = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro =
            'Não foi possível solicitar a recuperação. '
            'Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // Retorna para a tela anterior.
  void _voltar() {
    if (widget.aoVoltar != null) {
      widget.aoVoltar!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.painel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nome e ícone do aplicativo.
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

                          Text(
                            'Esqueceu sua senha?',
                            style: textos.headlineMedium,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Digite seu e-mail cadastrado '
                            'para solicitar a recuperação de senha.',
                            style: textos.bodySmall,
                          ),

                          const SizedBox(height: 32),

                          // Campo de e-mail.
                          AppTextField(
                            controller: _emailController,
                            rotulo: AppTextos.email,
                            dica: AppTextos.emailExemplo,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            enabled: !_carregando && !_concluido,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) {
                              _enviarLink();
                            },
                          ),

                          const SizedBox(height: 20),

                          // Mensagem de erro.
                          if (_erro != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _erro!,
                                style: textos.bodyMedium?.copyWith(
                                  color: AppColors.terracota,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Confirmação somente após resposta real.
                          if (_concluido) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.fundo,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.verde),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.verdeEscuro,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Solicitação recebida. '
                                      'Se houver uma conta para '
                                      'este e-mail, siga as '
                                      'instruções enviadas.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Botão com estado de carregamento.
                          AppButton(
                            texto: 'Enviar link de recuperação',
                            textoCarregando: 'Enviando...',
                            carregando: _carregando,
                            onPressed: _concluido ? null : _enviarLink,
                          ),

                          const SizedBox(height: 32),

                          // Voltar ao login.
                          TextButton.icon(
                            onPressed: _voltar,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar para o login'),
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
