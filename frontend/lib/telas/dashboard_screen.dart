// #Matheus Azevedo Teixeira, RA:25014927

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/app_textos.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/status_chip.dart';
import '../data/repositories/perfil_repository.dart';
import '../data/repositories/talhao_repository.dart';
import '../domain/models/talhao_resumo.dart';

// Painel da propriedade (RF14, RF15 e RF16). Todos os números vêm do backend.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.aoAbrirTalhoes,
    required this.aoAbrirSimulacao,
  });

  final VoidCallback aoAbrirTalhoes;
  final VoidCallback aoAbrirSimulacao;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _carregando = true;
  String? _erro;
  PerfilCompleto? _perfil;
  List<TalhaoResumo> _talhoes = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final perfis = context.read<PerfilRepository>();
    final talhoes = context.read<TalhaoRepository>();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final perfil = await perfis.buscar();
      final lista = await talhoes.listar();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _talhoes = lista;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = AppTextos.erroInesperado);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  int _quantos(StatusSolo status) =>
      _talhoes.where((t) => t.status == status).length;

  String _primeiroNome(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));

    return partes.first.isEmpty ? '' : partes.first;
  }

  String _hectares(double valor) =>
      '${valor.toStringAsFixed(1).replaceAll('.', ',')} ha';

  @override
  Widget build(BuildContext context) {
    if (_carregando && _perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null && _perfil == null) {
      return _EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar);
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: largura >= 700 ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _conteudo(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _conteudo() {
    final textos = Theme.of(context).textTheme;
    final nome = _primeiroNome(_perfil?.nome ?? '');
    final propriedade = _perfil?.propriedade?.nome;

    final areaTotal = _talhoes.fold<double>(0, (soma, t) => soma + t.areaHa);
    final total = _talhoes.length;
    final precisamAtencao = _talhoes
        .where((t) => t.status == StatusSolo.risco || t.status == StatusSolo.atencao)
        .toList()
      ..sort((a, b) => b.status.index.compareTo(a.status.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nome.isEmpty ? 'Olá!' : 'Olá, $nome',
                  style: textos.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  propriedade == null || propriedade.isEmpty
                      ? 'Cadastre sua propriedade ao criar o primeiro talhão.'
                      : 'Panorama geral da $propriedade.',
                  style: textos.bodySmall,
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.aoAbrirTalhoes,
              icon: const Icon(Icons.add),
              label: const Text('Novo talhão'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_erro != null) ...[
          _AvisoErro(mensagem: _erro!),
          const SizedBox(height: 16),
        ],
        if (total == 0)
          _SemTalhoes(aoCadastrar: widget.aoAbrirTalhoes)
        else ...[
          _Indicadores(
            itens: [
              _Indicador('Área total', _hectares(areaTotal), '$total ${total == 1 ? 'talhão cadastrado' : 'talhões cadastrados'}'),
              _Indicador('Saudáveis', '${_quantos(StatusSolo.saudavel)}', _percentual(_quantos(StatusSolo.saudavel), total)),
              _Indicador('Em atenção', '${_quantos(StatusSolo.atencao)}', _percentual(_quantos(StatusSolo.atencao), total)),
              _Indicador('Em risco', '${_quantos(StatusSolo.risco)}', _percentual(_quantos(StatusSolo.risco), total)),
            ],
          ),
          const SizedBox(height: 24),
          _SaudeDoSolo(
            talhoes: _talhoes,
            precisamAtencao: precisamAtencao,
            quantos: _quantos,
          ),
        ],
        const SizedBox(height: 24),
        _ChamadaSimulacao(aoSimular: widget.aoAbrirSimulacao),
      ],
    );
  }

  String _percentual(int parte, int total) {
    if (total == 0) return '';
    return '${(parte * 100 / total).round()}% da propriedade';
  }
}

class _Indicador {
  const _Indicador(this.rotulo, this.valor, this.detalhe);

  final String rotulo;
  final String valor;
  final String detalhe;
}

// Quatro números principais, em grade que se ajusta à largura.
class _Indicadores extends StatelessWidget {
  const _Indicadores({required this.itens});

  final List<_Indicador> itens;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    // Usa a largura realmente disponível para decidir quantas colunas cabem.
    return LayoutBuilder(
      builder: (context, constraints) {
        final disponivel = constraints.maxWidth;
        final colunas = disponivel >= 800 ? 4 : (disponivel >= 440 ? 2 : 1);
        const espaco = 16.0;
        final larguraItem = (disponivel - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final item in itens)
              SizedBox(
                width: larguraItem,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.rotulo, style: textos.bodySmall),
                        const SizedBox(height: 6),
                        Text(
                          item.valor,
                          style: textos.headlineMedium?.copyWith(
                            color: AppColors.texto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.detalhe,
                          style: textos.bodySmall?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Distribuição por status (RF15) e talhões que pedem atenção (RF16).
class _SaudeDoSolo extends StatelessWidget {
  const _SaudeDoSolo({
    required this.talhoes,
    required this.precisamAtencao,
    required this.quantos,
  });

  final List<TalhaoResumo> talhoes;
  final List<TalhaoResumo> precisamAtencao;
  final int Function(StatusSolo) quantos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saúde geral do solo', style: textos.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Distribuição dos talhões pelo resultado da última análise.',
              style: textos.bodySmall,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final status in StatusSolo.values)
                      if (quantos(status) > 0)
                        Expanded(
                          flex: quantos(status),
                          child: ColoredBox(
                            color: StatusChip.corDo(status),
                            child: const SizedBox.expand(),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final status in StatusSolo.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: StatusChip.corDo(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${status.rotulo}: ${quantos(status)}',
                        style: textos.bodySmall?.copyWith(
                          color: AppColors.texto,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Explica o que "Saudável" significa (RN02).
            Text(
              '"Saudável" quer dizer apenas que nenhum indicador avaliado '
              'acendeu alerta. Não substitui a avaliação de um agrônomo.',
              style: textos.bodySmall?.copyWith(fontSize: 14),
            ),
            const Divider(height: 32),
            Text('Talhões que precisam de atenção', style: textos.titleMedium),
            const SizedBox(height: 12),
            if (precisamAtencao.isEmpty)
              Text(
                'Nenhum talhão com alerta no momento.',
                style: textos.bodySmall,
              )
            else
              for (final t in precisamAtencao) _LinhaAtencao(talhao: t),
          ],
        ),
      ),
    );
  }
}

class _LinhaAtencao extends StatelessWidget {
  const _LinhaAtencao({required this.talhao});

  final TalhaoResumo talhao;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final motivo = talhao.motivos.isEmpty
        ? 'Sem detalhes do indicador.'
        : talhao.motivos.join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talhao.culturaAtual == null
                      ? talhao.nome
                      : '${talhao.nome} · ${talhao.culturaAtual}',
                  style: textos.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(motivo, style: textos.bodySmall?.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusChip(talhao.status),
        ],
      ),
    );
  }
}

class _ChamadaSimulacao extends StatelessWidget {
  const _ChamadaSimulacao({required this.aoSimular});

  final VoidCallback aoSimular;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.verdeEscuro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pronto para planejar a próxima safra?',
                style: textos.titleLarge?.copyWith(color: AppColors.fundo),
              ),
              const SizedBox(height: 4),
              Text(
                'Compare cenários de rotação com base no histórico dos seus talhões.',
                style: textos.bodyMedium?.copyWith(color: AppColors.fundo),
              ),
            ],
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.fundo,
              foregroundColor: AppColors.verdeEscuro,
              minimumSize: const Size(48, 48),
            ),
            onPressed: aoSimular,
            child: const Text('Simular rotação'),
          ),
        ],
      ),
    );
  }
}

class _SemTalhoes extends StatelessWidget {
  const _SemTalhoes({required this.aoCadastrar});

  final VoidCallback aoCadastrar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nenhum talhão cadastrado', style: textos.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Cadastre o primeiro talhão para acompanhar a área, o histórico '
              'de plantio e o status do solo.',
              style: textos.bodySmall,
            ),
            const SizedBox(height: 16),
            AppButton(texto: 'Cadastrar talhão', onPressed: aoCadastrar),
          ],
        ),
      ),
    );
  }
}

class _AvisoErro extends StatelessWidget {
  const _AvisoErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        mensagem,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppButton(texto: 'Tentar novamente', onPressed: aoTentarNovamente),
            ],
          ),
        ),
      ),
    );
  }
}
