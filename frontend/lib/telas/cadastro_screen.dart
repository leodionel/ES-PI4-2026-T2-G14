
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/utils/validators.dart';
import '../data/services/api_client.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() =>
      _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _api.fechar();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    final nome = (valor ?? '').trim();

    if (nome.isEmpty) {
      return 'Informe seu nome.';
    }

    if (nome.length < 3 || nome.length > 120) {
      return 'O nome deve ter entre 3 e 120 caracteres.';
    }

    return null;
  }

  String _telefoneNumerico(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  String? _validarTelefone(String? valor) {
    final telefone = _telefoneNumerico(valor ?? '');

    if (telefone.isEmpty) {
      return 'Informe seu telefone.';
    }

    if (telefone.length != 10 && telefone.length != 11) {
      return 'Informe um telefone com DDD válido.';
    }

    return null;
  }

  String? _validarSenha(String? valor) {
    final senha = valor ?? '';

    if (senha.isEmpty) {
      return 'Informe sua senha.';
    }

    if (senha.length < 8 || senha.length > 128) {
      return 'A senha deve ter entre 8 e 128 caracteres.';
    }

    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirme sua senha.';
    }

    if (valor != _senhaController.text) {
      return 'As senhas não coincidem.';
    }

    return null;
  }

  Future<void> _cadastrar() async {
    if (_carregando) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Cadastro real na API Java Spring Boot.
      // O backend salva a senha protegida por BCrypt.
      await _api.post(
        '/api/usuarios/cadastro',
        {
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'telefone': _telefoneNumerico(
            _telefoneController.text,
          ),
          'senha': _senhaController.text,
        },
      );

      if (!mounted) return;

      // Retorna ao login informando que o cadastro funcionou.
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
            'Não foi possível realizar o cadastro. '
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

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.fundo,
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
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
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
                                    'Prontuário Digital do Talhão',
                                    style: textos.titleLarge,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            Text(
                              'Criar minha conta',
                              style: textos.headlineMedium,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Preencha seus dados para '
                              'começar a utilizar o sistema.',
                              style: textos.bodySmall,
                            ),

                            const SizedBox(height: 28),

                            AppTextField(
                              controller: _nomeController,
                              rotulo: 'Nome completo',
                              dica: 'Digite seu nome',
                              validator: _validarNome,
                              textInputAction:
                                  TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.name,
                              ],
                              enabled: !_carregando,
                            ),

                            const SizedBox(height: 18),

                            AppTextField(
                              controller: _emailController,
                              rotulo: 'E-mail',
                              dica: 'exemplo@email.com',
                              validator: Validators.email,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              enabled: !_carregando,
                            ),

                            const SizedBox(height: 18),

                            AppTextField(
                              controller: _telefoneController,
                              rotulo: 'Telefone com DDD',
                              dica: '11999999999',
                              validator: _validarTelefone,
                              keyboardType: TextInputType.phone,
                              textInputAction:
                                  TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              enabled: !_carregando,
                            ),

                            const SizedBox(height: 18),

                            AppTextField(
                              controller: _senhaController,
                              rotulo: 'Senha',
                              dica: 'Mínimo de 8 caracteres',
                              validator: _validarSenha,
                              senha: true,
                              textInputAction:
                                  TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              enabled: !_carregando,
                            ),

                            const SizedBox(height: 18),

                            AppTextField(
                              controller:
                                  _confirmarSenhaController,
                              rotulo: 'Confirmar senha',
                              dica: 'Digite a senha novamente',
                              validator: _validarConfirmacao,
                              senha: true,
                              textInputAction:
                                  TextInputAction.done,
                              enabled: !_carregando,
                              onFieldSubmitted: (_) {
                                _cadastrar();
                              },
                            ),

                            const SizedBox(height: 18),

                            if (_erro != null) ...[
                              Text(
                                _erro!,
                                style:
                                    textos.bodyMedium?.copyWith(
                                  color: AppColors.terracota,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            AppButton(
                              texto: 'Criar conta',
                              textoCarregando:
                                  'Cadastrando...',
                              carregando: _carregando,
                              onPressed: _cadastrar,
                            ),

                            const SizedBox(height: 24),

                            TextButton.icon(
                              onPressed: _carregando
                                  ? null
                                  : () {
                                      Navigator.of(context)
                                          .pop(false);
                                    },
                              icon: const Icon(
                                Icons.arrow_back,
                              ),
                              label: const Text(
                                'Voltar para o login',
                              ),
                            ),
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
}
