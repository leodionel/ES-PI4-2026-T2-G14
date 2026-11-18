import 'dart:async';

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

  Map<String, dynamic>? _perfil;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    unawaited(_carregarPerfil());
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

      final resposta = await _api.get('/api/usuarios/me', token: token);
      if (resposta is! Map) {
        throw const FormatException('A API não retornou os dados do perfil.');
      }

      if (mounted) {
        setState(() => _perfil = Map<String, dynamic>.from(resposta));
      }
    } catch (erro) {
      if (mounted) {
        setState(() => _erro = erro.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Map<String, dynamic> get _usuario {
    final usuario = _perfil?['usuario'];
    if (usuario is Map) return Map<String, dynamic>.from(usuario);
    return _perfil ?? <String, dynamic>{};
  }

  Map<String, dynamic>? get _propriedade {
    final propriedade = _perfil?['propriedade'];
    return propriedade is Map
        ? Map<String, dynamic>.from(propriedade)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final nome = _usuario['nome']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        title: const Text('Perfil'),
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
                : ListView(
                    children: [
                      _cartaoPerfil(nome),
                      if (_propriedade != null) ...[
                        const SizedBox(height: 16),
                        _cartaoPropriedade(_propriedade!),
                      ] else ...[
                        const SizedBox(height: 16),
                        const Text('Nenhuma propriedade cadastrada.'),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _cartaoPerfil(String nome) {
    final criadoEm = DateTime.tryParse(_usuario['criadoEm']?.toString() ?? '');
    final dataFormatada = criadoEm == null
        ? '—'
        : '${criadoEm.day.toString().padLeft(2, '0')}/'
              '${criadoEm.month.toString().padLeft(2, '0')}/${criadoEm.year}';

    return Card(
      color: AppColors.painel,
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
                  nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase(),
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
                nome.isEmpty ? 'Meu perfil' : nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verdeEscuro,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _campo(Icons.email_outlined, 'E-mail', _usuario['email']),
            const Divider(height: 24),
            _campo(Icons.phone_outlined, 'Telefone', _usuario['telefone']),
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

  Widget _cartaoPropriedade(Map<String, dynamic> propriedade) {
    return Card(
      color: AppColors.painel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borda),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propriedade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.verdeEscuro,
              ),
            ),
            const SizedBox(height: 16),
            _campo(Icons.agriculture_outlined, 'Nome', propriedade['nome']),
            const Divider(height: 24),
            _campo(
              Icons.location_on_outlined,
              'Localização',
              propriedade['localizacao'],
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
