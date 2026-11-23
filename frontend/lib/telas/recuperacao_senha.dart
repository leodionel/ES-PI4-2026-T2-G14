// Feito por Leonardo Dionel RA:25010092

import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';

// Tela de recuperação de senha do produtor (RF03).
//
// Funciona em duas etapas na mesma tela:
//   1. o produtor informa o e-mail e pede o código;
//   2. informa o código de 6 dígitos e a nova senha.
// Ao concluir, volta ao login devolvendo true (o app mostra a confirmação).
class RecuperacaoSenha extends StatefulWidget {
  const RecuperacaoSenha({
    super.key,
    this.aoSolicitarRecuperacao,
    this.aoRedefinirSenha,
    this.aoVoltar,
  });

  // As ações reais são fornecidas pelo AuthRepository (ver app.dart).
  // Devolve o código simulado, quando o backend o exibe.
  final Future<String?> Function(String email)? aoSolicitarRecuperacao;
  final Future<void> Function(String email, String codigo, String novaSenha)?
  aoRedefinirSenha;
  final VoidCallback? aoVoltar;

  @override
  State<RecuperacaoSenha> createState() => _RecuperacaoSenhaState();
}

class _RecuperacaoSenhaState extends State<RecuperacaoSenha> {
  static const _naoConectado =
      'A recuperação de senha ainda não está conectada ao servidor.';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _carregando = false;
  // false = etapa 1 (e-mail); true = etapa 2 (código e nova senha).
  bool _codigoSolicitado = false;
  String? _codigoSimulado;
  String? _erro;

  // Etapa 1: valida o e-mail e pede o código.
  Future<void> _solicitarCodigo() async {
    if (_carregando) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final solicitar = widget.aoSolicitarRecuperacao;

    // Não informa envio realizado sem integração real.
    if (solicitar == null) {
      setState(() {
        _erro = _naoConectado;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final codigo = await solicitar(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _codigoSimulado = codigo;
        _codigoSolicitado = true;
        _codigoController.clear();
      });
    } on AppException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
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

  // Etapa 2: valida código e senha e redefine.
  Future<void> _redefinirSenha() async {
    if (_carregando) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final redefinir = widget.aoRedefinirSenha;

    if (redefinir == null) {
      setState(() {
        _erro = _naoConectado;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await redefinir(
        _emailController.text.trim(),
        _codigoController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;

      // Volta ao login; o app mostra a confirmação.
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro =
            'Não foi possível redefinir a senha. '
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

  // Volta à etapa 1 para corrigir o e-mail ou pedir outro código.
  void _usarOutroEmail() {
    if (_carregando) return;

    setState(() {
      _codigoSolicitado = false;
      _codigoSimulado = null;
      _erro = null;
      _codigoController.clear();
      _senhaController.clear();
      _confirmarController.clear();
    });
  }

  String? _validarConfirmacao(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirme a nova senha.';
    }

    if (valor != _senhaController.text) {
      return 'As senhas não coincidem.';
    }

    return null;
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
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
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
                            _codigoSolicitado
                                ? 'Redefinir senha'
                                : 'Esqueceu sua senha?',
                            style: textos.headlineMedium,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _codigoSolicitado
                                ? 'Informe o código de 6 dígitos '
                                      '(válido por 15 minutos) e escolha '
                                      'a nova senha.'
                                : 'Digite seu e-mail cadastrado '
                                      'para receber um código de '
                                      'recuperação.',
                            style: textos.bodySmall,
                          ),

                          const SizedBox(height: 32),

                          // Campo de e-mail (etapa 1; fica bloqueado na 2).
                          AppTextField(
                            controller: _emailController,
                            rotulo: AppTextos.email,
                            dica: AppTextos.emailExemplo,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            enabled: !_carregando && !_codigoSolicitado,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) {
                              if (!_codigoSolicitado) _solicitarCodigo();
                            },
                          ),

                          if (_codigoSolicitado) ...[
                            const SizedBox(height: 16),

                            // Modo simulado: o backend devolve o código,
                            // que normalmente chegaria por e-mail.
                            if (_codigoSimulado != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.fundo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.verde),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.mark_email_read_outlined,
                                      color: AppColors.verdeEscuro,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Modo de demonstração: nenhum '
                                        'e-mail é enviado. '
                                        'Seu código é $_codigoSimulado.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              Text(
                                'Se existir uma conta para este e-mail, '
                                'um código foi gerado.',
                                style: textos.bodySmall,
                              ),
                              const SizedBox(height: 16),
                            ],

                            AppTextField(
                              controller: _codigoController,
                              rotulo: 'Código de recuperação',
                              dica: '123456',
                              validator: Validators.codigoRecuperacao,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              enabled: !_carregando,
                            ),

                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _senhaController,
                              rotulo: 'Nova senha',
                              validator: Validators.novaSenha,
                              senha: true,
                              textInputAction: TextInputAction.next,
                              enabled: !_carregando,
                              autofillHints: const [AutofillHints.newPassword],
                            ),

                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _confirmarController,
                              rotulo: 'Confirmar nova senha',
                              validator: _validarConfirmacao,
                              senha: true,
                              textInputAction: TextInputAction.done,
                              enabled: !_carregando,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) {
                                _redefinirSenha();
                              },
                            ),
                          ],

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

                          // Botão com estado de carregamento.
                          AppButton(
                            texto: _codigoSolicitado
                                ? 'Redefinir senha'
                                : 'Enviar código',
                            textoCarregando: _codigoSolicitado
                                ? 'Redefinindo...'
                                : 'Enviando...',
                            carregando: _carregando,
                            onPressed: _codigoSolicitado
                                ? _redefinirSenha
                                : _solicitarCodigo,
                          ),

                          if (_codigoSolicitado) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _carregando ? null : _usarOutroEmail,
                              child: const Text('Usar outro e-mail'),
                            ),
                          ],

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
