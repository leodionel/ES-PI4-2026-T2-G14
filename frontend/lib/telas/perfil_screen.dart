import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiClient _api = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();
  late Future<Map<String, dynamic>> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _carregarPerfil();
  }

  Future<Map<String, dynamic>> _carregarPerfil() async {
    final token = await _tokenStorage.lerToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    final resposta = await _api.get('/api/usuarios/me', token: token);
    if (resposta is! Map) {
      throw const FormatException('A API não retornou os dados do perfil.');
    }
    return Map<String, dynamic>.from(resposta);
  }

  void _tentarNovamente() {
    setState(() => _perfil = _carregarPerfil());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.painel,
        foregroundColor: AppColors.verdeEscuro,
        title: const Text('Perfil'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfil,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _tentarNovamente,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final perfil = snapshot.data!;
          final usuario = perfil['usuario'] is Map
              ? Map<String, dynamic>.from(perfil['usuario'] as Map)
              : <String, dynamic>{};
          final propriedade = perfil['propriedade'] is Map
              ? Map<String, dynamic>.from(perfil['propriedade'] as Map)
              : null;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _secao('Dados pessoais', [
                _dado('Nome', usuario['nome']),
                _dado('E-mail', usuario['email']),
                _dado('Telefone', usuario['telefone']),
              ]),
              const SizedBox(height: 20),
              _secao('Propriedade', [
                if (propriedade == null)
                  const Text('Nenhuma propriedade cadastrada.')
                else ...[
                  _dado('Nome', propriedade['nome']),
                  _dado('Localização', propriedade['localizacao']),
                ],
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> conteudo) {
    return Card(
      color: AppColors.painel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.verdeEscuro,
              ),
            ),
            const SizedBox(height: 16),
            ...conteudo,
          ],
        ),
      ),
    );
  }

  Widget _dado(String rotulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: const TextStyle(color: AppColors.textoSecundario)),
          const SizedBox(height: 3),
          Text(valor?.toString().trim().isNotEmpty == true
              ? valor.toString()
              : 'Não informado'),
        ],
      ),
    );
  }
}
