import 'package:flutter/material.dart';

import '../../core/app_textos.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../domain/models/resultado_simulacao.dart';
import 'widgets/cenario_card.dart';

// Tela de resultados da simulacao.
// Recebe dados do backend pela ViewModel.
// Nao calcula regras agronomicas.
class RecomendacoesView extends StatelessWidget {
  const RecomendacoesView({
    super.key,
    required this.nomeTalhao,
    this.resultado,
    this.carregando = false,
    this.erro,
    this.aoTentarNovamente,
    this.aoNovaSimulacao,
  });

  final String nomeTalhao;
  final ResultadoSimulacao? resultado;
  final bool carregando;
  final String? erro;
  final VoidCallback? aoTentarNovamente;
  final VoidCallback? aoNovaSimulacao;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(context),

              const SizedBox(height: 28),

              if (carregando)
                _carregamento()
              else if (erro != null && erro!.trim().isNotEmpty)
                _erro(context)
              else if (resultado == null ||
                  resultado!.cenarios.isEmpty)
                _vazio(context)
              else
                _resultados(context),

              const SizedBox(height: 20),

              _aviso(
                icone: Icons.info_outline,
                texto: AppTextos.avisoRecomendacao,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cabecalho da tela
  Widget _cabecalho(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.agriculture_outlined,
              color: AppColors.verdeEscuro,
              size: 30,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                AppTextos.recomendacoesTitulo,
                style: textos.headlineMedium?.copyWith(
                  color: AppColors.verdeEscuro,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          AppTextos.recomendacoesDescricao,
          style: textos.bodyMedium?.copyWith(
            color: AppColors.textoSecundario,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.painel,
            border: Border.all(color: AppColors.borda),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.landscape_outlined,
                color: AppColors.verdeEscuro,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  '${AppTextos.talhaoRecomendacao}: $nomeTalhao',
                  style: textos.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Estado de carregamento
  Widget _carregamento() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.verde,
            ),

            SizedBox(height: 18),

            Text(AppTextos.calculandoRecomendacoes),
          ],
        ),
      ),
    );
  }

  // Estado de erro
  Widget _erro(BuildContext context) {
    return _estado(
      context,
      icone: Icons.error_outline,
      titulo: AppTextos.erroRecomendacao,
      descricao: erro!,
      acao: aoTentarNovamente,
      textoAcao: AppTextos.tentarNovamente,
    );
  }

  // Estado sem resultados
  Widget _vazio(BuildContext context) {
    return _estado(
      context,
      icone: Icons.grass_outlined,
      titulo: AppTextos.semRecomendacoes,
      descricao: AppTextos.semRecomendacoesDescricao,
      acao: aoNovaSimulacao,
      textoAcao: AppTextos.novaSimulacao,
    );
  }

  // Widget reutilizado para erro e estado vazio
  Widget _estado(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required String textoAcao,
    VoidCallback? acao,
  }) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.painel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            size: 40,
            color: AppColors.verdeEscuro,
          ),

          const SizedBox(height: 12),

          Text(
            titulo,
            style: textos.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            descricao,
            textAlign: TextAlign.center,
          ),

          if (acao != null) ...[
            const SizedBox(height: 20),

            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 240,
              ),
              child: AppButton(
                texto: textoAcao,
                onPressed: acao,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Resultados da comparacao de culturas
  Widget _resultados(BuildContext context) {
    final dados = resultado!;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${dados.cenarios.length} '
          '${AppTextos.cenariosAnalisados}',
          style: textos.titleLarge,
        ),

        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, limits) {
            final larguraTotal = limits.maxWidth;

            final colunas = larguraTotal >= 850
                ? 3
                : larguraTotal >= 520
                    ? 2
                    : 1;

            const espaco = 16.0;

            final larguraCard =
                (larguraTotal - (colunas - 1) * espaco) /
                colunas;

            return Wrap(
              spacing: espaco,
              runSpacing: espaco,
              children: dados.cenarios.map((cenario) {
                return CenarioCard(
                  cenario: cenario,
                  largura: larguraCard,
                );
              }).toList(),
            );
          },
        ),

        // Mensagem quando os cenarios sao equivalentes
        if (dados.equivalentes) ...[
          const SizedBox(height: 20),

          _aviso(
            icone: Icons.balance_outlined,
            texto: AppTextos.opcoesEquivalentes,
          ),
        ],

        const SizedBox(height: 24),

        _explicacao(context),

        // Permite realizar outra simulacao
        if (aoNovaSimulacao != null) ...[
          const SizedBox(height: 24),

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 280,
            ),
            child: AppButton(
              texto: AppTextos.novaSimulacao,
              onPressed: aoNovaSimulacao,
              secundario: true,
            ),
          ),
        ],
      ],
    );
  }

  // Explica a origem das recomendacoes
  Widget _explicacao(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.painel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTextos.comoRecomendacaoCalculada,
            style: textos.titleLarge,
          ),

          const SizedBox(height: 10),

          Text(
            AppTextos.explicacaoRecomendacao,
            style: textos.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Avisos apresentados ao produtor
  Widget _aviso({
    required IconData icone,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundo,
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            color: AppColors.verdeEscuro,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(texto),
          ),
        ],
      ),
    );
  }
}