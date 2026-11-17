import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';
import 'talhoes_screen.dart';
import 'talhaodetalhe.dart';
import 'simulacao_rotacao.dart';
import 'perfil_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F5EE),
    body: PaginaDados<PainelDados>(
      carregar: context.read<DadosRepository>().painel,
      construir: (dados, atualizar) {
        Future<void> abrir(Widget tela) async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => tela));
          if (context.mounted) atualizar();
        }

        final usuario = context.watch<AuthRepository>().usuario;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              usuario == null ? 'Olá' : 'Olá, ${usuario.nome}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              dados.propriedade == null
                  ? 'Cadastre sua propriedade para começar.'
                  : 'Panorama de ${dados.propriedade!['nome']}',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      abrir(const TalhoesScreen(abrirCadastroAoEntrar: true)),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo talhão'),
                ),
                OutlinedButton(
                  onPressed: () => abrir(const TalhoesScreen()),
                  child: const Text('Talhões'),
                ),
                OutlinedButton(
                  onPressed: () => abrir(const SimulacaoRotacao()),
                  child: const Text('Simulação de rotação'),
                ),
                OutlinedButton(
                  onPressed: () => abrir(const PerfilScreen()),
                  child: const Text('Perfil'),
                ),
                IconButton(
                  onPressed: atualizar,
                  tooltip: 'Atualizar dados',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _indicador('Área total', '${numeroDado(dados.area)} ha'),
                _indicador('Talhões cadastrados', '${dados.talhoes.length}'),
                for (final status in [
                  'SAUDAVEL',
                  'ATENCAO',
                  'RISCO',
                  'SEM_ANALISE',
                ])
                  _indicador(statusDado(status), '${dados.quantidade(status)}'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Saúde do solo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Saudável significa que nenhum indicador avaliado apresentou alerta.',
            ),
            if (dados.talhoes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum talhão cadastrado.'),
              ),
            for (final t in dados.talhoes)
              Card(
                child: ListTile(
                  title: Text(t.nome),
                  subtitle: Text(
                    '${t.culturaAtual}\n${(t.status['motivos'] as List? ?? []).join(' • ')}',
                  ),
                  trailing: Text(statusDado(t.status['status'])),
                  onTap: () => abrir(ProntuarioScreen(talhaoId: t.id)),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Atividade recente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (dados.eventos.isEmpty)
              const Text('Nenhum plantio, colheita ou análise registrado.'),
            for (final e in dados.eventos.take(10))
              ListTile(
                title: Text('${e['titulo']} - ${e['talhao']}'),
                subtitle: Text(dataDado(e['data'])),
              ),
          ],
        );
      },
    ),
  );
  Widget _indicador(String titulo, String valor) => SizedBox(
    width: 190,
    child: Card(
      color: const Color(0xFFF0EBE1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, color: Color(0xFF4A5D23)),
            ),
          ],
        ),
      ),
    ),
  );
}
