import 'package:flutter/material.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/validators.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/auth_layout.dart';

class RecuperacaoSenha extends StatefulWidget {
  const RecuperacaoSenha({
    super.key,
    this.aoSolicitarRecuperacao,
    this.aoVoltar,
  });

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

  Future<void> _enviarLink() async {
    if (_carregando || _concluido) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _erro = null;
    });

    final solicitar = widget.aoSolicitarRecuperacao;

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
    return AuthLayout(
      titulo: 'Recupere seu acesso',
      descricao:
          'Esqueceu a senha? Informe o e-mail da sua '
          'conta para solicitar a recuperação.',
      icone: Icons.mark_email_read_outlined,
      etiqueta: 'RECUPERAÇÃO DE SENHA',
      conteudo: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo de e-mail.
            AppTextField(
              controller: _emailController,
              rotulo: AppTextos.email,
              dica: AppTextos.emailExemplo,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              enabled: !_carregando && !_concluido,
              onFieldSubmitted: (_) {
                _enviarLink();
              },
            ),

            const SizedBox(height: 24),

            // Mensagem de erro.
            if (_erro != null) ...[
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
                    const Icon(Icons.error_outline, color: AppColors.terracota),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _erro!,
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
              const SizedBox(height: 18),
            ],

            // Confirmação após resposta bem-sucedida.
            if (_concluido) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF4E6),
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
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solicitação recebida. '
                        'Se houver uma conta para '
                        'este e-mail, siga as '
                        'instruções enviadas.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.verdeEscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Enviar solicitação.
            AppButton(
              texto: 'Enviar link de recuperação',
              textoCarregando: 'Enviando...',
              carregando: _carregando,
              onPressed: _concluido ? null : _enviarLink,
            ),

            const SizedBox(height: 20),

            // Retornar ao login.
            OutlinedButton.icon(
              onPressed: _voltar,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Voltar para o login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verdeEscuro,
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.borda),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'Prontuário Digital do Talhão',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
