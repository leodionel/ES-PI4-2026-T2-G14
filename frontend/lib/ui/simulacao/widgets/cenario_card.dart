import 'package:flutter/material.dart';

import '../../../core/app_textos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cenario_resultado.dart';
import '../../../domain/models/classificacao.dart';

// Card de um cenario: classificacao, justificativas e fontes.
class CenarioCard extends StatelessWidget {
  const CenarioCard({
    super.key,
    required this.cenario,
    required this.largura,
  });

  final CenarioResultado cenario;
  final double largura;

  bool get _recomendado =>
      cenario.classificacao == Classificacao.recomendado;

  String get _rotulo {
    switch (cenario.classificacao) {
      case Classificacao.recomendado:
        return AppTextos.classificacaoRecomendado;

      case Classificacao.aceitavel:
        return cenario.temAlerta
            ? AppTextos.classificacaoAceitavelAlerta
            : AppTextos.classificacaoAceitavel;

      case Classificacao.naoRecomendado:
        return AppTextos.classificacaoNaoRecomendado;
    }
  }

  IconData get _icone {
    switch (cenario.classificacao) {
      case Classificacao.recomendado:
        return Icons.check_circle_outline;

      case Classificacao.aceitavel:
        return cenario.temAlerta
            ? Icons.warning_amber_rounded
            : Icons.info_outline;

      case Classificacao.naoRecomendado:
        return Icons.block_outlined;
    }
  }

  Color get _cor {
    switch (cenario.classificacao) {
      case Classificacao.recomendado:
        return AppColors.verdeEscuro;

      case Classificacao.aceitavel:
        return AppColors.ambar;

      case Classificacao.naoRecomendado:
        return AppColors.terracota;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textoTema = Theme.of(context).textTheme;

    return Container(
      width: largura,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.painel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _recomendado
              ? AppColors.verde
              : AppColors.borda,
          width: _recomendado ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                cenario.cultura,
                style: textoTema.titleLarge?.copyWith(
                  color: AppColors.verdeEscuro,
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: _recomendado
                      ? AppColors.verdeEscuro
                      : AppColors.fundo,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _cor),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icone,
                      size: 17,
                      color: _recomendado
                          ? AppColors.fundo
                          : _cor,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _rotulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _recomendado
                            ? AppColors.fundo
                            : _cor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            AppTextos.justificativasRecomendacao,
            style: textoTema.titleMedium?.copyWith(
              color: AppColors.texto,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          if (cenario.mensagens.isEmpty)
            Text(
              AppTextos.semJustificativaRecomendacao,
              style: textoTema.bodyMedium,
            )
          else
            ...cenario.mensagens.map(
              (mensagem) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 19,
                          color: _cor,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            mensagem.texto,
                            style: textoTema.bodyMedium?.copyWith(
                              color: AppColors.texto,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (mensagem.fonte.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 27,
                          top: 6,
                        ),
                        child: Text(
                          '${AppTextos.fonteRecomendacao}: '
                          '${mensagem.fonte}',
                          style: textoTema.bodySmall?.copyWith(
                            color: AppColors.textoSecundario,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}