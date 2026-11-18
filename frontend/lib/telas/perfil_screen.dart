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
  final _api = ApiClient();
  final _tokenStorage = TokenStorage();
  Map<String, dynamic>? _perfil;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final token = await _tokenStorage.lerToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      final perfil = await _api.get('/api/usuarios/me', token: token);
      if (perfil is! Map) {
        throw const FormatException('O servidor retornou um perfil inválido.');
      }
      if (mounted) setState(() => _perfil = Map<String, dynamic>.from(perfil));
    } catch (erro) {
      if (mounted) setState(() => _erro = erro.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = _perfil?['nome']?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: AppColors.painel,
        foregroundColor: AppColors.verdeEscuro,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? _mensagemErro()
                : _cartaoPerfil(nome),
          ),
        ),
      ),
    );
  }

  Widget _cartaoPerfil(String nome) {
    final criadoEm = DateTime.tryParse(_perfil?['criadoEm']?.toString() ?? '');
    final dataFormatada = criadoEm == null
        ? '—'
        : '${criadoEm.day.toString().padLeft(2, '0')}/'
              '${criadoEm.month.toString().padLeft(2, '0')}/${criadoEm.year}';
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borda),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFE2EEE4),
                child: Text(
                  nome.isEmpty ? '?' : nome.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppColors.verdeEscuro,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verdeEscuro,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _campo(Icons.email_outlined, 'E-mail', _perfil?['email']),
            const Divider(height: 24),
            _campo(Icons.phone_outlined, 'Telefone', _perfil?['telefone']),
            const Divider(height: 24),
            _campo(
              Icons.calendar_today_outlined,
              'Conta criada em',
              dataFormatada,
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(IconData icone, String rotulo, Object? valor) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icone, size: 20, color: AppColors.textoSecundario),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 3),
            Text(
              valor?.toString().trim().isNotEmpty == true
                  ? valor.toString()
                  : 'Não informado',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.texto,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _mensagemErro() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.cloud_off_outlined,
        size: 40,
        color: AppColors.textoSecundario,
      ),
      const SizedBox(height: 12),
      Text(
        'Não foi possível carregar o perfil. $_erro',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _carregarPerfil,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar novamente'),
      ),
    ],
  );
}
