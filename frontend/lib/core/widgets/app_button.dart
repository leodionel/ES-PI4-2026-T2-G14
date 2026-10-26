import 'package:flutter/material.dart';

// Botão padrão dos formulários
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.textoCarregando,
    this.secundario = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final String? textoCarregando;
  final bool secundario;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    final conteudo = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        // Mostra o indicador enquanto a ação está em andamento
        if (carregando)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cores.onSurface,
            ),
          ),
        Text(
          carregando ? (textoCarregando ?? texto) : texto,
          textAlign: TextAlign.center,
        ),
      ],
    );

    // Bloqueia novos cliques durante o carregamento
    final acao = carregando ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: secundario
            ? OutlinedButton(onPressed: acao, child: conteudo)
            : ElevatedButton(onPressed: acao, child: conteudo),
      ),
    );
  }
}
