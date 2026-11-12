import 'package:flutter/material.dart';

import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';
import 'talhaodetalhe.dart';

// Tela de listagem e cadastro de talhões
class TalhoesScreen extends StatefulWidget {
  const TalhoesScreen({super.key, this.abrirCadastroAoEntrar = false});

  final bool abrirCadastroAoEntrar;

  @override
  State<TalhoesScreen> createState() => _TalhoesScreenState();
}

class _TalhoesScreenState extends State<TalhoesScreen> {
  final ApiClient _api = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  List<Map<String, dynamic>> _talhoes = [];

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _carregarTalhoes();

    if (widget.abrirCadastroAoEntrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _abrirCadastro();
        }
      });
    }
  }

  // RECUPERAR JWT
  Future<String> _obterToken() async {
    final token = await _tokenStorage.lerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return token;
  }

  // LISTAR TALHÕES DO MONGODB
  Future<void> _carregarTalhoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = await _obterToken();

      final resposta = await _api.get('/api/talhoes', token: token);

      if (resposta is! List) {
        throw const FormatException('A API não retornou uma lista de talhões.');
      }

      final talhoes = resposta
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _talhoes = talhoes;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ABRIR OS DETALHES DO TALHÃO SELECIONADO
  Future<void> _abrirDetalhes(Map<String, dynamic> talhao) async {
    final id = talhao['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este talhão não possui um ID válido.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProntuarioScreen(talhaoId: id)),
    );

    // Atualizar listagem ao voltar dos detalhes
    if (mounted) {
      await _carregarTalhoes();
    }
  }

  // FORMULÁRIO PARA RECEBER DADOS
  Future<Map<String, String>?> _pedirDados({
    required String titulo,
    required String primeiroCampo,
    required String segundoCampo,
    required String primeiraChave,
    required String segundaChave,
    bool segundoNumerico = false,
  }) async {
    final formKey = GlobalKey<FormState>();

    final primeiro = TextEditingController();
    final segundo = TextEditingController();

    final resposta = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: primeiro,
                  decoration: InputDecoration(labelText: primeiroCampo),
                  validator: (valor) {
                    if ((valor ?? '').trim().isEmpty) {
                      return 'Este campo é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: segundo,
                  decoration: InputDecoration(labelText: segundoCampo),
                  keyboardType: segundoNumerico
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  validator: (valor) {
                    final texto = (valor ?? '').trim();

                    if (texto.isEmpty) {
                      return 'Este campo é obrigatório';
                    }

                    if (segundoNumerico) {
                      final numero = double.tryParse(
                        texto.replaceAll(',', '.'),
                      );

                      if (numero == null || !numero.isFinite || numero <= 0) {
                        return 'Informe uma área válida maior que zero';
                      }
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              Navigator.pop(dialogContext, {
                primeiraChave: primeiro.text.trim(),
                segundaChave: segundo.text.trim(),
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      primeiro.dispose();
      segundo.dispose();
    });

    return resposta;
  }

  // CADASTRAR TALHÃO NO MONGODB
  Future<void> _abrirCadastro() async {
    if (_salvando) return;

    setState(() {
      _salvando = true;
    });

    try {
      final token = await _obterToken();

      // Verificar se existe uma propriedade
      final propriedades = await _api.get('/api/propriedades', token: token);

      if (propriedades is! List) {
        throw const FormatException(
          'A API não retornou uma lista de propriedades.',
        );
      }

      if (!mounted) return;

      // Cadastrar propriedade, caso não exista
      if (propriedades.isEmpty) {
        final propriedade = await _pedirDados(
          titulo: 'Cadastre sua propriedade primeiro',
          primeiroCampo: 'Nome da propriedade',
          segundoCampo: 'Localização',
          primeiraChave: 'nome',
          segundaChave: 'localizacao',
        );

        if (propriedade == null) return;

        await _api.post('/api/propriedades', {
          'nome': propriedade['nome']!,
          'localizacao': propriedade['localizacao']!,
        }, token: token);
      }

      if (!mounted) return;

      // Solicitar dados do novo talhão
      final talhao = await _pedirDados(
        titulo: 'Novo Talhão',
        primeiroCampo: 'Nome do talhão',
        segundoCampo: 'Área (hectares)',
        primeiraChave: 'nome',
        segundaChave: 'areaHa',
        segundoNumerico: true,
      );

      if (talhao == null) return;

      // Enviar dados reais para API Java
      await _api.post('/api/talhoes', {
        'nome': talhao['nome']!,
        'areaHa': double.parse(talhao['areaHa']!.replaceAll(',', '.')),
      }, token: token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talhão cadastrado com sucesso!')),
      );

      await _carregarTalhoes();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível cadastrar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // INTERFACE
  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF4A5D23);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),

      appBar: AppBar(
        title: const Text('Meus Talhões'),
        backgroundColor: const Color(0xFFF0EBE1),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarTalhoes,
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _carregarTalhoes,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _talhoes.isEmpty
          ? const Center(
              child: Text('Nenhum talhão cadastrado nesta propriedade.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _talhoes.length,
              itemBuilder: (context, index) {
                final talhao = _talhoes[index];

                final nome = talhao['nome']?.toString() ?? 'Sem nome';

                final area = talhao['areaHa']?.toString() ?? '—';

                final plantios = talhao['totalPlantios']?.toString() ?? '0';

                final analises = talhao['totalAnalises']?.toString() ?? '0';

                return Card(
                  color: const Color(0xFFF0EBE1),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.grass, color: verde),
                    title: Text(nome),
                    subtitle: Text(
                      '$area ha • $plantios plantio(s) • '
                      '$analises análise(s)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _abrirDetalhes(talhao);
                    },
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvando ? null : _abrirCadastro,
        backgroundColor: const Color(0xFF8DA259),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_salvando ? 'Processando...' : 'Novo Talhão'),
      ),
    );
  }
}
