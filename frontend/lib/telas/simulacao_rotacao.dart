import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SimulacaoRotacao extends StatefulWidget {
  const SimulacaoRotacao({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  State<SimulacaoRotacao> createState() => _SimulacaoRotacaoState();
}

class _SimulacaoRotacaoState extends State<SimulacaoRotacao> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _talhaoSelecionado = 0;
  final Set<String> _culturasSelecionadas = {'Feijão', 'Milho', 'Pousio'};

  static const _talhoes = [
    _Talhao(
      nome: 'Talhão 01',
      area: '42,3 ha',
      culturaAtual: 'Soja',
      culturaAnterior: 'Milho',
      ph: '6,2 - Ideal',
      nitrogenio: 'Baixo',
    ),
    _Talhao(
      nome: 'Talhão 02',
      area: '26,1 ha',
      culturaAtual: 'Milho',
      culturaAnterior: 'Soja',
      ph: '5,8 - Adequado',
      nitrogenio: 'Médio',
    ),
    _Talhao(
      nome: 'Talhão 03',
      area: '20 ha',
      culturaAtual: 'Feijão',
      culturaAnterior: 'Trigo',
      ph: '6,0 - Ideal',
      nitrogenio: 'Baixo',
    ),
    _Talhao(
      nome: 'Talhão 04',
      area: '40 ha',
      culturaAtual: 'Soja',
      culturaAnterior: 'Milho',
      ph: '5,5 - Adequado',
      nitrogenio: 'Médio',
    ),
  ];

  static const _culturas = [
    _Cultura(
      nome: 'Feijão',
      fixacaoNitrogenio: 0.86,
      impactoSolo: 0.76,
      repeticaoFamilia: 0.18,
      cor: AppColors.verde,
      descricao:
          'Fixa nitrogênio no solo, compensando o desgaste causado pela soja. Boa opção para recompor a fertilidade antes da próxima safra.',
    ),
    _Cultura(
      nome: 'Milho',
      fixacaoNitrogenio: 0.14,
      impactoSolo: 0.48,
      repeticaoFamilia: 0.52,
      cor: AppColors.ambar,
      descricao:
          'Mantém boa produtividade, mas não recompõe o nitrogênio consumido pela soja. Exige atenção à adubação nitrogenada.',
    ),
    _Cultura(
      nome: 'Pousio',
      fixacaoNitrogenio: 0.24,
      impactoSolo: 0.84,
      repeticaoFamilia: 0.16,
      cor: AppColors.terracota,
      descricao:
          'Permite descanso do solo, mas não gera produtividade na safra. Indicado apenas se o talhão estiver muito desgastado.',
    ),
    _Cultura(
      nome: 'Trigo',
      fixacaoNitrogenio: 0.18,
      impactoSolo: 0.57,
      repeticaoFamilia: 0.42,
      cor: AppColors.ambar,
      descricao:
          'Pode diversificar a sequência de culturas. Considere o clima e a necessidade de nutrientes antes do plantio.',
    ),
    _Cultura(
      nome: 'Sorgo',
      fixacaoNitrogenio: 0.20,
      impactoSolo: 0.60,
      repeticaoFamilia: 0.34,
      cor: AppColors.ambar,
      descricao:
          'É uma alternativa rústica para a rotação e cobertura do solo. Planeje a adubação conforme o histórico do talhão.',
    ),
  ];

  _Talhao get _talhao => _talhoes[_talhaoSelecionado];

  String get _culturaRecomendada =>
      _talhao.culturaAtual == 'Feijão' ? 'Milho' : 'Feijão';

  void _alternarCultura(String nome, bool selecionada) {
    if (selecionada && _culturasSelecionadas.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você pode comparar até 3 culturas por vez.'),
        ),
      );
      return;
    }

    setState(() {
      if (selecionada) {
        _culturasSelecionadas.add(nome);
      } else {
        _culturasSelecionadas.remove(nome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: desktop
              ? null
              : AppBar(
                  backgroundColor: AppColors.painel,
                  foregroundColor: AppColors.verdeEscuro,
                  title: const _Marca(),
                  titleSpacing: 0,
                ),
          drawer: desktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.painel,
                  child: SafeArea(child: _menuLateral()),
                ),
          body: SafeArea(
            top: desktop,
            child: Row(
              children: [
                if (desktop) _menuLateral(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _conteudo(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuLateral() {
    return Container(
      width: 146,
      decoration: const BoxDecoration(
        color: AppColors.painel,
        border: Border(right: BorderSide(color: AppColors.borda)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Marca(),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'GESTÃO DA FAZENDA',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 0.2,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _itemMenu(Icons.grid_view_outlined, 'Dashboard'),
          _itemMenu(Icons.layers_outlined, 'Talhões'),
          _itemMenu(
            Icons.energy_savings_leaf_outlined,
            'Simulação de Rotação',
            selecionado: true,
          ),
          _itemMenu(Icons.person_outline, 'Perfil'),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5EF),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(9),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Área monitorada',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texto,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '128,4 ha',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.verdeEscuro,
                  ),
                ),
                Text(
                  '6 talhões cadastrados\n• 3 alertas ativos',
                  style: TextStyle(
                    fontSize: 7,
                    height: 1.3,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu(IconData icone, String texto, {bool selecionado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selecionado ? const Color(0xFFE2EEE4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (texto == 'Simulação de Rotação') {
              _scaffoldKey.currentState?.closeDrawer();
            } else {
              widget.onNavigate?.call(texto);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
            child: Row(
              children: [
                Icon(
                  icone,
                  size: 12,
                  color: selecionado
                      ? AppColors.verdeEscuro
                      : AppColors.textoSecundario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight:
                          selecionado ? FontWeight.w600 : FontWeight.normal,
                      color: selecionado
                          ? AppColors.verdeEscuro
                          : AppColors.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 500 ? 16 : 20,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulação de Rotação',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: constraints.maxWidth < 500 ? 25 : 28,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: AppColors.verdeEscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Compare cenários de próxima cultura com base no histórico do talhão',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _tituloEtapa(1, 'Escolha o talhão'),
                  const SizedBox(height: 10),
                  _seletorTalhoes(),
                  const SizedBox(height: 26),
                  _resumoTalhao(),
                  const SizedBox(height: 26),
                  _tituloEtapa(2, 'Escolha até 3 culturas para comparar'),
                  const SizedBox(height: 10),
                  _seletorCulturas(),
                  const SizedBox(height: 14),
                  _cartoesCulturas(
                    constraints.maxWidth -
                        (constraints.maxWidth < 500 ? 32 : 40),
                  ),
                  const SizedBox(height: 14),
                  _criteriosRecomendacao(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tituloEtapa(int numero, String texto) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.verdeEscuro,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$numero',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.verdeEscuro,
          ),
        ),
      ],
    );
  }

  Widget _seletorTalhoes() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: List.generate(_talhoes.length, (index) {
        final talhao = _talhoes[index];
        final selecionado = index == _talhaoSelecionado;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _talhaoSelecionado = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: selecionado ? const Color(0xFFF1EBDD) : Colors.white,
              border: Border.all(
                color: selecionado ? AppColors.ambar : AppColors.borda,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talhao.nome,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texto,
                  ),
                ),
                Text(
                  '${talhao.area} • ${talhao.culturaAtual}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _resumoTalhao() {
    final itens = [
      ('Cultura atual', _talhao.culturaAtual),
      ('Cultura anterior', _talhao.culturaAnterior),
      ('pH do solo', _talhao.ph),
      ('Nitrogênio', _talhao.nitrogenio),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.painel,
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Wrap(
        spacing: 28,
        runSpacing: 8,
        children: itens
            .map(
              (item) => SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.texto,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _seletorCulturas() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _culturas.map((cultura) {
        final selecionada = _culturasSelecionadas.contains(cultura.nome);
        return SizedBox(
          width: 76,
          height: 28,
          child: ChoiceChip(
            label: Text(cultura.nome),
            selected: selecionada,
            onSelected: (valor) => _alternarCultura(cultura.nome, valor),
            labelStyle: TextStyle(
              fontSize: 10,
              color: AppColors.texto,
            ),
            backgroundColor: AppColors.painel.withValues(alpha: 0.7),
            selectedColor: const Color(0xFFE2EEE4),
            side: const BorderSide(color: AppColors.borda),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }).toList(),
    );
  }

  Widget _cartoesCulturas(double larguraConteudo) {
    final selecionadas = _culturas
        .where((cultura) => _culturasSelecionadas.contains(cultura.nome))
        .toList();

    if (selecionadas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.painel.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Selecione pelo menos uma cultura para visualizar a comparação.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
        ),
      );
    }

    final larguraCartao = larguraConteudo >= 620
        ? (larguraConteudo - 28) / 3
        : larguraConteudo >= 440
        ? (larguraConteudo - 12) / 2
        : larguraConteudo;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: selecionadas
          .map(
            (cultura) => SizedBox(
              width: larguraCartao,
              child: _cartaoCultura(
                cultura,
                recomendada: cultura.nome == _culturaRecomendada,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _cartaoCultura(_Cultura cultura, {required bool recomendada}) {
    final borderColor = recomendada ? AppColors.verde : AppColors.borda;

    return Container(
      constraints: const BoxConstraints(minHeight: 162),
      decoration: BoxDecoration(
        color: recomendada ? const Color(0xFFF0F0E3) : AppColors.painel,
        border: Border.all(color: borderColor, width: recomendada ? 1.2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cultura.nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.verdeEscuro,
                  ),
                ),
                const SizedBox(height: 10),
                _indicador(
                  'Fixação de nitrogênio',
                  cultura.fixacaoNitrogenio,
                  cultura.cor,
                ),
                const SizedBox(height: 5),
                _indicador(
                  'Impacto no solo',
                  cultura.impactoSolo,
                  cultura.cor,
                ),
                const SizedBox(height: 5),
                _indicador(
                  'Repetição da família',
                  cultura.repeticaoFamilia,
                  cultura.cor,
                ),
                const SizedBox(height: 12),
                Text(
                  cultura.descricao,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.22,
                    color: AppColors.verdeEscuro,
                  ),
                ),
              ],
            ),
          ),
          if (recomendada)
            Positioned(
              top: -10,
              left: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.verdeEscuro,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 3,
                ),
                child: const Text(
                  'Recomendado',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _indicador(String rotulo, double valor, Color cor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor,
              minHeight: 2,
              backgroundColor: const Color(0xFFD8D3C6),
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _criteriosRecomendacao() {
    const criterios = [
      'Evita repetir a mesma cultura ou família botânica em sequência',
      'Prioriza culturas fixadoras de nitrogênio após culturas que mais consomem esse nutriente, como a soja.',
      'Considera o histórico de solo já cadastrado para o talhão (pH, matéria orgânica, nutrientes).',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.painel,
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como a recomendação é calculada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.verdeEscuro,
            ),
          ),
          const SizedBox(height: 7),
          ...criterios.map(
            (criterio) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.texto,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      criterio,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.25,
                        color: AppColors.texto,
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

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.verdeEscuro,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.agriculture_outlined,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'Prontuário Digital\ndo Talhão',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.verdeEscuro,
            ),
          ),
        ),
      ],
    );
  }
}

class _Talhao {
  const _Talhao({
    required this.nome,
    required this.area,
    required this.culturaAtual,
    required this.culturaAnterior,
    required this.ph,
    required this.nitrogenio,
  });

  final String nome;
  final String area;
  final String culturaAtual;
  final String culturaAnterior;
  final String ph;
  final String nitrogenio;
}

class _Cultura {
  const _Cultura({
    required this.nome,
    required this.fixacaoNitrogenio,
    required this.impactoSolo,
    required this.repeticaoFamilia,
    required this.cor,
    required this.descricao,
  });

  final String nome;
  final double fixacaoNitrogenio;
  final double impactoSolo;
  final double repeticaoFamilia;
  final Color cor;
  final String descricao;
}
