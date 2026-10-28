import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Visão geral da fazenda, baseada na tela de referência do Pay4.
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  void _informar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 640;
            return Row(
              children: [
                if (!compacto)
                  _BarraLateral(largura: constraints.maxWidth >= 1000 ? 218 : 158),
                Expanded(
                  child: _ConteudoDashboard(
                    compacto: compacto,
                    aoClicar: (mensagem) => _informar(context, mensagem),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 640
          ? const _NavegacaoInferior()
          : null,
    );
  }
}

class _BarraLateral extends StatelessWidget {
  const _BarraLateral({required this.largura});

  final double largura;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      color: const Color(0xFFF0E8D8),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.verdeEscuro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Prontuário Digital\ndo Talhão',
                  style: TextStyle(
                    color: AppColors.verdeEscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 10),
            child: Text(
              'GESTÃO DA FAZENDA',
              style: TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ),
          const _ItemNavegacao(
            icone: Icons.dashboard_outlined,
            titulo: 'Dashboard',
            selecionado: true,
          ),
          const _ItemNavegacao(
            icone: Icons.grid_view_outlined,
            titulo: 'Talhões',
          ),
          const _ItemNavegacao(
            icone: Icons.sync_alt,
            titulo: 'Simulação de Rotação',
          ),
          const _ItemNavegacao(icone: Icons.person_outline, titulo: 'Perfil'),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Área monitorada', style: TextStyle(fontSize: 11)),
                SizedBox(height: 3),
                Text(
                  '128,4 ha',
                  style: TextStyle(
                    color: AppColors.verdeEscuro,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('6 talhões cadastrados', style: TextStyle(fontSize: 10)),
                Text('• 3 alertas ativos', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    required this.icone,
    required this.titulo,
    this.selecionado = false,
  });

  final IconData icone;
  final String titulo;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selecionado ? const Color(0xFFE3EDE2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 20,
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(
          icone,
          size: 19,
          color: selecionado
              ? AppColors.verdeEscuro
              : AppColors.textoSecundario,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: selecionado ? AppColors.verdeEscuro : AppColors.texto,
            fontSize: 13,
            fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class _ConteudoDashboard extends StatelessWidget {
  const _ConteudoDashboard({required this.compacto, required this.aoClicar});

  final bool compacto;
  final ValueChanged<String> aoClicar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final duasColunas = largura >= 540;
        final padding = compacto ? 20.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding,
            compacto ? 20 : 24,
            padding,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Cabecalho(
                    compacto: compacto,
                    aoClicar: () => aoClicar('Cadastro de talhão em breve.'),
                  ),
                  const SizedBox(height: 26),
                  _ResumoCards(duasColunas: largura >= 520),
                  const SizedBox(height: 18),
                  if (duasColunas)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 7, child: _SaudeSolo()),
                        const SizedBox(width: 18),
                        const Expanded(flex: 4, child: _AtividadeRecente()),
                      ],
                    )
                  else ...[
                    const _SaudeSolo(),
                    const SizedBox(height: 16),
                    const _AtividadeRecente(),
                  ],
                  const SizedBox(height: 22),
                  _BannerRotacao(
                    compacto: compacto,
                    aoClicar: () => aoClicar('Simulação de rotação em breve.'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.compacto, required this.aoClicar});

  final bool compacto;
  final VoidCallback aoClicar;

  @override
  Widget build(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, Leonardo',
          style: TextStyle(
            color: AppColors.verdeEscuro,
            fontSize: compacto ? 27 : 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Aqui está o panorama geral da Fazenda Santa Clara hoje.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
        ),
      ],
    );
    final botao = FilledButton.icon(
      onPressed: aoClicar,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Novo Talhão'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 14), botao],
      );
    }
    return Row(
      children: [
        Expanded(child: titulo),
        botao,
      ],
    );
  }
}

class _ResumoCards extends StatelessWidget {
  const _ResumoCards({required this.duasColunas});

  final bool duasColunas;

  @override
  Widget build(BuildContext context) {
    const itens = [
      _ResumoItem(
        'Área total',
        '128,4 ha',
        '4 Talhões cadastrados',
        Icons.landscape_outlined,
      ),
      _ResumoItem(
        'Talhões saudáveis',
        '2',
        '50% da propriedade',
        Icons.eco_outlined,
        cor: AppColors.verde,
      ),
      _ResumoItem(
        'Em atenção',
        '1',
        'Nitrogênio baixo',
        Icons.warning_amber_rounded,
        cor: AppColors.ambar,
      ),
      _ResumoItem(
        'Em risco',
        '1',
        'pH fora da faixa',
        Icons.error_outline,
        cor: AppColors.terracota,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = duasColunas ? 4 : 2;
        const espaco = 12.0;
        final largura =
            (constraints.maxWidth - (colunas - 1) * espaco) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final item in itens)
              SizedBox(
                width: largura,
                child: _ResumoCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ResumoItem {
  const _ResumoItem(
    this.titulo,
    this.valor,
    this.detalhe,
    this.icone, {
    this.cor,
  });

  final String titulo;
  final String valor;
  final String detalhe;
  final IconData icone;
  final Color? cor;
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.item});

  final _ResumoItem item;

  @override
  Widget build(BuildContext context) {
    final cor = item.cor ?? AppColors.verdeEscuro;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDE1),
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
              Icon(item.icone, size: 17, color: cor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.valor,
            style: const TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.detalhe,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: cor),
          ),
        ],
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDE1),
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.verdeEscuro,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SaudeSolo extends StatelessWidget {
  const _SaudeSolo();

  @override
  Widget build(BuildContext context) {
    return _Painel(
      titulo: 'Saúde geral do solo',
      subtitulo: 'Distribuição de status entre os talhões da propriedade',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              height: 13,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ColoredBox(color: Color(0xFF83A64A)),
                  ),
                  Expanded(child: ColoredBox(color: Color(0xFFD5A64B))),
                  Expanded(child: ColoredBox(color: Color(0xFFB5533C))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legenda(cor: Color(0xFF83A64A), texto: 'Saudável · 2 talhões'),
              _Legenda(cor: Color(0xFFD5A64B), texto: 'Atenção · 1 talhão'),
              _Legenda(cor: Color(0xFFB5533C), texto: 'Em risco · 1 talhão'),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Talhões que precisam de atenção',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 8),
          const _AlertaTalhao(
            nome: 'Talhão 2 · Soja',
            detalhe: 'pH fora da faixa ideal · último laudo em 14 jan 2026',
            risco: true,
          ),
          const SizedBox(height: 7),
          const _AlertaTalhao(
            nome: 'Talhão 3 · Feijão',
            detalhe: 'Nitrogênio baixo · recomenda-se rotação na próxima safra',
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _AlertaTalhao extends StatelessWidget {
  const _AlertaTalhao({
    required this.nome,
    required this.detalhe,
    this.risco = false,
  });

  final String nome;
  final String detalhe;
  final bool risco;

  @override
  Widget build(BuildContext context) {
    final cor = risco ? AppColors.terracota : AppColors.ambar;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detalhe,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              risco ? 'Risco' : 'Atenção',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtividadeRecente extends StatelessWidget {
  const _AtividadeRecente();

  @override
  Widget build(BuildContext context) {
    return _Painel(
      titulo: 'Atividade recente',
      subtitulo: 'Últimos registros em todos os talhões',
      child: const Column(
        children: [
          _AtividadeItem(
            cor: AppColors.ambar,
            titulo: 'Análise de solo · Talhão 04',
            data: '10 jan 2026 · Leonardo D.',
          ),
          _AtividadeItem(
            cor: AppColors.terracota,
            titulo: 'Praga identificada · Talhão 02',
            data: '12 jan 2026 · Leonardo D.',
          ),
          _AtividadeItem(
            cor: AppColors.verde,
            titulo: 'Plantio de Batata · Talhão 04',
            data: '15 nov 2025 · Leonardo D.',
          ),
          _AtividadeItem(
            cor: Color(0xFF8D5BD1),
            titulo: 'Colheita do Milho · Talhão 01',
            data: '05 jan 2026 · Leonardo D.',
            ultimo: true,
          ),
        ],
      ),
    );
  }
}

class _AtividadeItem extends StatelessWidget {
  const _AtividadeItem({
    required this.cor,
    required this.titulo,
    required this.data,
    this.ultimo = false,
  });

  final Color cor;
  final String titulo;
  final String data;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: cor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textoSecundario,
                  ),
                ),
                if (!ultimo) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.borda),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerRotacao extends StatelessWidget {
  const _BannerRotacao({required this.compacto, required this.aoClicar});

  final bool compacto;
  final VoidCallback aoClicar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.verdeEscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: compacto
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_mensagem(), const SizedBox(height: 12), _botao()],
            )
          : Row(
              children: [
                Expanded(child: _mensagem()),
                _botao(),
              ],
            ),
    );
  }

  Widget _mensagem() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pronto para planejar a próxima safra?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 3),
      Text(
        'Compare cenários de rotação com base no histórico dos seus talhões',
        style: TextStyle(color: Color(0xFFDDE5D2), fontSize: 11),
      ),
    ],
  );

  Widget _botao() => FilledButton(
    onPressed: aoClicar,
    style: FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.verdeEscuro,
      minimumSize: const Size(144, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    child: const Text('Simular Rotação'),
  );
}

class _NavegacaoInferior extends StatelessWidget {
  const _NavegacaoInferior();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 68,
      selectedIndex: 0,
      backgroundColor: const Color(0xFFF0E8D8),
      indicatorColor: const Color(0xFFDDE8D7),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          label: 'Talhões',
        ),
        NavigationDestination(icon: Icon(Icons.sync_alt), label: 'Rotação'),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
