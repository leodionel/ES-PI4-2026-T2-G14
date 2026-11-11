import 'package:flutter/material.dart';

import '../app_textos.dart';
import '../theme/app_colors.dart';

/// Layout compartilhado pelas telas de autenticação.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.conteudo,
    this.etiqueta = 'ACESSO À PLATAFORMA',
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final Widget conteudo;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBFAF6), Color(0xFFF0EBDD)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              final margem = desktop ? 40.0 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: margem, vertical: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight > 56
                        ? constraints.maxHeight - 56
                        : 0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: _PainelMarca(compacto: false),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _cartao(context, desktop: true),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _PainelMarca(compacto: true),
                                const SizedBox(height: 20),
                                _cartao(context, desktop: false),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cartao(BuildContext context, {required bool desktop}) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 40 : 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borda.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.texto.withValues(alpha: 0.08),
            blurRadius: 38,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0DE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, size: 27, color: AppColors.verdeEscuro),
          ),

          const SizedBox(height: 24),

          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: AppColors.verde,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            titulo,
            style: textos.headlineMedium?.copyWith(
              fontSize: desktop ? 32 : 29,
              height: 1.16,
              fontWeight: FontWeight.w800,
              color: AppColors.verdeEscuro,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            descricao,
            style: textos.bodyMedium?.copyWith(
              color: AppColors.textoSecundario,
              height: 1.5,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 30),

          conteudo,
        ],
      ),
    );
  }
}

/// Área de identidade visual do projeto.
class _PainelMarca extends StatelessWidget {
  const _PainelMarca({required this.compacto});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compacto ? null : 540,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.verdeEscuro, Color(0xFF31451D)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -75,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 40,
                ),
              ),
            ),
          ),
          Positioned(
            left: -90,
            bottom: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compacto ? 22 : 38),
            child: compacto
                ? _cabecalho()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cabecalho(),
                      const Spacer(),
                      const Icon(
                        Icons.spa_outlined,
                        size: 65,
                        color: Color(0xFFDBE5C3),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Sua terra.\nSuas decisões.\nSeu futuro.',
                        style: TextStyle(
                          fontSize: 37,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Organize as informações do campo '
                        'e acompanhe cada etapa da sua produção.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const Spacer(),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Etiqueta(texto: 'Talhões'),
                          _Etiqueta(texto: 'Solo'),
                          _Etiqueta(texto: 'Safras'),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.eco_outlined, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Text(
            AppTextos.nomeApp,
            style: TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
