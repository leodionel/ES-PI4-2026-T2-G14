import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/dados_repository.dart';
import '../core/widgets/pagina_dados.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthRepository>().usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: PaginaDados<List<Registro>>(
        carregar: context.read<DadosRepository>().propriedades,
        construir: (propriedades, atualizar) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              title: const Text('Nome'),
              subtitle: Text(usuario?.nome ?? 'Não informado'),
            ),
            ListTile(
              title: const Text('E-mail'),
              subtitle: Text(usuario?.email ?? 'Não informado'),
            ),
            ListTile(
              title: const Text('Telefone'),
              subtitle: Text(usuario?.telefone ?? 'Não informado'),
            ),
            const Divider(),
            if (propriedades.isEmpty)
              const Text('Nenhuma propriedade cadastrada.'),
            for (final p in propriedades)
              ListTile(
                title: Text('${p['nome']}'),
                subtitle: Text('${p['localizacao']}'),
              ),
            TextButton.icon(
              onPressed: () => context.read<AuthRepository>().sair(),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}
