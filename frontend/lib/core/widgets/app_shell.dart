import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../telas/dashboard_screen.dart';
import '../../telas/perfil_screen.dart';
import '../../telas/simulacao_rotacao_dados.dart';
import '../../telas/talhoes_screen.dart';
import '../app_textos.dart';
import '../theme/app_colors.dart';

// Seções do aplicativo, na ordem do menu.
enum SecaoApp {
  dashboard('Dashboard', Icons.space_dashboard_outlined),
  talhoes('Talhões', Icons.layers_outlined),
  simulacao('Simulação de Rotação', Icons.event_repeat_outlined),
  perfil('Perfil', Icons.person_outline);

  const SecaoApp(this.titulo, this.icone);

  final String titulo;
  final IconData icone;
}

// Estrutura única do app depois do login: menu lateral no tablet/desktop e
// gaveta no celular. É aqui que ficam a navegação e o botão Sair.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _larguraMinimaMenu = 900;

  SecaoApp _secao = SecaoApp.dashboard;

  void _ir(SecaoApp secao) {
    if (secao != _secao) {
      setState(() => _secao = secao);
    }
  }

  Future<void> _sair() async {
    final auth = context.read<AuthRepository>();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do aplicativo?'),
        content: const Text('Você precisará entrar novamente para acessar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      await auth.sair();
    }
  }

  Widget _pagina() {
    // A chave faz a tela recarregar os dados toda vez que a seção é aberta.
    switch (_secao) {
      case SecaoApp.dashboard:
        return DashboardScreen(
          key: const ValueKey('dashboard'),
          aoAbrirTalhoes: () => _ir(SecaoApp.talhoes),
          aoAbrirSimulacao: () => _ir(SecaoApp.simulacao),
        );
      case SecaoApp.talhoes:
        return const TalhoesScreen(key: ValueKey('talhoes'));
      case SecaoApp.simulacao:
        return const SimulacaoRotacao(key: ValueKey('simulacao'));
      case SecaoApp.perfil:
        return const PerfilScreen(key: ValueKey('perfil'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fixo = constraints.maxWidth >= _larguraMinimaMenu;

        if (fixo) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 248, child: _Menu(secao: _secao, aoIr: _ir, aoSair: _sair)),
                const VerticalDivider(width: 1),
                Expanded(child: _pagina()),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_secao.titulo)),
          drawer: Drawer(
            backgroundColor: AppColors.painel,
            child: Builder(builder: (drawerContext) => _Menu(
              secao: _secao,
              aoIr: (secao) {
                Scaffold.of(drawerContext).closeDrawer();
                _ir(secao);
              },
              aoSair: () {
                Scaffold.of(drawerContext).closeDrawer();
                _sair();
              },
            )),
          ),
          body: _pagina(),
        );
      },
    );
  }
}

// Menu de navegação.
class _Menu extends StatelessWidget {
  const _Menu({required this.secao, required this.aoIr, required this.aoSair});

  final SecaoApp secao;
  final ValueChanged<SecaoApp> aoIr;
  final VoidCallback aoSair;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Material(
      color: AppColors.painel,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.verdeEscuro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      color: AppColors.fundo,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppTextos.nomeApp,
                      style: textos.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            for (final item in SecaoApp.values)
              _ItemMenu(
                item: item,
                selecionado: item == secao,
                aoTocar: () => aoIr(item),
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textoSecundario),
              title: const Text('Sair'),
              onTap: aoSair,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.item,
    required this.selecionado,
    required this.aoTocar,
  });

  final SecaoApp item;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        selected: selecionado,
        button: true,
        child: ListTile(
          selected: selecionado,
          selectedTileColor: AppColors.selecao,
          selectedColor: AppColors.verdeEscuro,
          iconColor: AppColors.textoSecundario,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(item.icone),
          title: Text(
            item.titulo,
            style: TextStyle(
              fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: aoTocar,
        ),
      ),
    );
  }
}
