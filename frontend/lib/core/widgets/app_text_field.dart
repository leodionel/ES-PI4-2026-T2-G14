import 'package:flutter/material.dart';

import '../app_textos.dart';

// Campo padrão dos formulários
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.rotulo,
    this.dica,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.senha = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String rotulo;
  final String? dica;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool senha;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _ocultarSenha = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,

      // Esconde o conteúdo quando o campo é de senha
      obscureText: widget.senha && _ocultarSenha,
      autocorrect: false,
      enableSuggestions: !widget.senha,

      // Mostra a validação depois que o usuário interage
      autovalidateMode: AutovalidateMode.onUserInteraction,

      // As cores e bordas vêm do tema
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: widget.dica,
        suffixIcon: widget.senha
            ? IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: _ocultarSenha
                    ? AppTextos.mostrarSenha
                    : AppTextos.ocultarSenha,
                icon: Icon(
                  _ocultarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: widget.enabled
                    ? () {
                        setState(() {
                          _ocultarSenha = !_ocultarSenha;
                        });
                      }
                    : null,
              )
            : null,
      ),
    );
  }
}
