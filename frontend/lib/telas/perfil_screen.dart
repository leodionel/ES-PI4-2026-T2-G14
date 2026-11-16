import 'package:flutter/material.dart';

import '../core/app_exception.dart';
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

  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  // BUSCA OS DADOS REAIS DO USUARIO
  Future<void> _carregarPerfil() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Recupera o JWT salvo durante o login.
      final token = await _tokenStorage.lerToken();

      if (token == null || token.isEmpty) {
        throw const AppException(
          tipo: TipoErro.autenticacao,
          mensagem: 'Sessão não encontrada. Faça login novamente.',
        );
      }

      // Consulta o endpoint protegido do Spring Boot.
      final resposta = await _api.get('/api/usuarios/me', token: token);

      if (resposta is! Map<String, dynamic>) {
        throw const AppException(
          tipo: TipoErro.servidor,
          mensagem: 'O servidor retornou dados inválidos.',
        );
      }

      if (!mounted) return;

      setState(() {
        _usuario = resposta;
      });
    } on AppException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
        _usuario = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o perfil.';
        _usuario = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  String _valor(dynamic dado) {
    if (dado is String && dado.trim().isNotEmpty) {
      return dado;
    }

    return 'Não informado';
  }

  @override
  void dispose() {
    _api.fechar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.painel,
        title: const Text('Meu perfil'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
              ? _conteudoErro()
              : _conteudoPerfil(context),
        ),
      ),
    );
  }

  // EXIBE ERROS DA API
  Widget _conteudoErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.terracota,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _carregarPerfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // EXIBE OS DADOS REAIS DO MONGODB
  Widget _conteudoPerfil(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),

        Text(
          'Perfil do produtor',
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(height: 8),

        const Text(
          'Informações da sua conta cadastrada.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 15),
        ),

        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.painel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borda),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.verde,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Minha conta',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.verdeEscuro,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _campo(
                icone: Icons.badge_outlined,
                titulo: 'Nome completo',
                valor: _valor(_usuario?['nome']),
              ),

              const Divider(height: 28),

              _campo(
                icone: Icons.email_outlined,
                titulo: 'E-mail',
                valor: _valor(_usuario?['email']),
              ),

              const Divider(height: 28),

              _campo(
                icone: Icons.phone_outlined,
                titulo: 'Telefone',
                valor: _valor(_usuario?['telefone']),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar dados'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Os dados são carregados diretamente '
          'da sua conta no servidor. '
          'A edição do perfil será habilitada '
          'após implementarmos essa funcionalidade.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
        ),

        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar ao Dashboard'),
          ),
        ),
      ],
    );
  }

  Widget _campo({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: AppColors.verdeEscuro, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.texto,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
