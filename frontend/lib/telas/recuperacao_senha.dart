import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/app_exception.dart';

import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';

// Tela de recuperação de senha do produtor.
class RecuperacaoSenha extends StatefulWidget {
  const RecuperacaoSenha({
    super.key,
    required this.aoSolicitarRecuperacao,
    required this.aoRedefinir,
    this.aoVoltar,
  });

  final Future<void> Function(String email) aoSolicitarRecuperacao;
  final Future<void> Function(String email, String codigo, String senha)
  aoRedefinir;
  final VoidCallback? aoVoltar;

  @override
  State<RecuperacaoSenha> createState() => _RecuperacaoSenhaState();
}

class _RecuperacaoSenhaState extends State<RecuperacaoSenha> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  bool _usarCodigo = false;

  bool _carregando = false;
  bool _concluido = false;
  String? _erro;

  // Valida o e-mail e solicita a recuperação.
  Future<void> _enviar() async {
    if (_carregando || _concluido) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _erro = null;
    });

    setState(() {
      _carregando = true;
    });

    try {
      final email = _emailController.text.trim();
      if (_usarCodigo) {
        await widget.aoRedefinir(email, _codigo.text.trim(), _senha.text);
      } else {
        await widget.aoSolicitarRecuperacao(email);
      }

      if (!mounted) return;

      setState(() {
        if (_usarCodigo) {
          _concluido = true;
          _senha.clear();
          _codigo.clear();
        } else {
          _usarCodigo = true;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e is AppException
            ? e.mensagem
            : 'Não foi possível concluir. Tente novamente.';
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
    _codigo.dispose();
    _senha.dispose();
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
                            _usarCodigo
                                ? 'Use o código enviado ao seu e-mail. Ele vale por 15 minutos.'
                                : 'Digite seu e-mail cadastrado '
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
                              if (!_usarCodigo) _enviar();
                            },
                          ),

                          const SizedBox(height: 20),

                          if (_usarCodigo && !_concluido) ...[
                            AppTextField(
                              controller: _codigo,
                              rotulo: 'Código recebido',
                              enabled: !_carregando,
                              validator: (v) =>
                                  RegExp(
                                    r'^[A-Za-z0-9_-]{32}$',
                                  ).hasMatch(v?.trim() ?? '')
                                  ? null
                                  : 'Cole o código completo enviado por e-mail.',
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _senha,
                              rotulo: 'Nova senha',
                              senha: true,
                              enabled: !_carregando,
                              validator: (v) =>
                                  v == null ||
                                      v.trim().isEmpty ||
                                      v.length < 8 ||
                                      utf8.encode(v).length > 72
                                  ? 'Use pelo menos 8 caracteres e no máximo 72 bytes.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

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
                                      'Senha alterada. Entre com a nova senha.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Botão com estado de carregamento.
                          if (!_concluido)
                            AppButton(
                              texto: _usarCodigo
                                  ? 'Alterar senha'
                                  : 'Enviar código',
                              textoCarregando: 'Enviando...',
                              carregando: _carregando,
                              onPressed: _enviar,
                            ),
                          if (!_concluido)
                            TextButton(
                              onPressed: _carregando
                                  ? null
                                  : () => setState(() {
                                      _usarCodigo = !_usarCodigo;
                                      _erro = null;
                                    }),
                              child: Text(
                                _usarCodigo
                                    ? 'Solicitar outro código'
                                    : 'Já tenho um código',
                              ),
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
