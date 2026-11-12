import 'package:flutter/material.dart';

import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';

// Prontuário de um talhão com dados da API Java
class ProntuarioScreen extends StatefulWidget {
  const ProntuarioScreen({super.key, this.talhaoId});

  // Opcional para manter compatibilidade com rotas antigas
  final String? talhaoId;

  @override
  State<ProntuarioScreen> createState() => _ProntuarioScreenState();
}

class _ProntuarioScreenState extends State<ProntuarioScreen> {
  static const corFundo = Color(0xFFF7F5EE);
  static const corCard = Color(0xFFF0EBE1);
  static const corVerdeEscuro = Color(0xFF4A5D23);
  static const corVerdeClaro = Color(0xFF8DA259);

  final ApiClient _api = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Map<String, dynamic>? _talhao;
  List<Map<String, dynamic>> _analises = [];

  bool _carregando = true;
  String? _erro;
  String? _erroAnalises;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // RECUPERAR TOKEN JWT
  Future<String> _obterToken() async {
    final token = await _tokenStorage.lerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return token;
  }

  // CARREGAR DETALHES REAIS DO TALHÃO
  Future<void> _carregarDados() async {
    final id = widget.talhaoId?.trim();

    if (id == null || id.isEmpty) {
      setState(() {
        _carregando = false;
        _erro = 'Selecione um talhão na lista para abrir o prontuário.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _erroAnalises = null;
    });

    try {
      final token = await _obterToken();

      // GET /api/talhoes/{id}
      final resposta = await _api.get(
        '/api/talhoes/${Uri.encodeComponent(id)}',
        token: token,
      );

      if (resposta is! Map) {
        throw const FormatException('A API não retornou os dados do talhão.');
      }

      final detalhe = Map<String, dynamic>.from(resposta);

      // Buscar análises de solo reais
      List<Map<String, dynamic>> analises = [];
      String? erroAnalises;

      try {
        final retorno = await _api.get('/api/analises-solo', token: token);

        if (retorno is! List) {
          throw const FormatException(
            'A API não retornou a lista de análises.',
          );
        }

        // Mostrar apenas análises deste talhão
        analises = retorno
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((item) => item['talhaoId']?.toString() == id)
            .toList();

        // Ordenar da análise mais recente para a antiga
        analises.sort(
          (a, b) => (b['dataColeta'] ?? '').toString().compareTo(
            (a['dataColeta'] ?? '').toString(),
          ),
        );
      } catch (e) {
        erroAnalises = e.toString().replaceFirst('Exception: ', '');
      }

      if (!mounted) return;

      setState(() {
        _talhao = detalhe;
        _analises = analises;
        _erroAnalises = erroAnalises;
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

  // FORMATAR TEXTO
  String _texto(dynamic valor, {String vazio = 'Não informado'}) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return vazio;
    }

    return valor.toString();
  }

  // FORMATAR NÚMERO
  String _numero(dynamic valor) {
    if (valor == null) {
      return 'Não informado';
    }

    if (valor is num) {
      final casas = valor == valor.roundToDouble() ? 0 : 2;

      return valor.toStringAsFixed(casas).replaceAll('.', ',');
    }

    return valor.toString().replaceAll('.', ',');
  }

  // FORMATAR DATA
  String _data(dynamic valor) {
    final texto = valor?.toString();

    if (texto == null || texto.isEmpty) {
      return 'Não informada';
    }

    final data = DateTime.tryParse(texto);

    if (data == null) {
      return texto;
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;

    return '$dia/$mes/$ano';
  }

  // RECUPERAR QUANTIDADE DA API
  int _quantidade(String campo) {
    final valor = _talhao?[campo];

    if (valor is int) {
      return valor;
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  // EXIBIR INFORMAÇÕES SOBRE PLANTIOS
  void _mostrarPlantios() {
    final total = _quantidade('totalPlantios');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plantios do talhão'),
        content: Text(
          total == 0
              ? 'Nenhum plantio registrado neste talhão. '
                    'O cadastro e o histórico de plantios '
                    'ainda precisam ser integrados à API.'
              : 'A API informa $total plantio(s) '
                    'neste talhão, mas ainda não disponibiliza '
                    'o histórico detalhado por este endpoint.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // EXIBIR ANÁLISES DE SOLO REAIS
  void _mostrarAnalises() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Análises de solo do talhão'),
        content: SizedBox(
          width: 540,
          height: 360,
          child: _erroAnalises != null
              ? Center(
                  child: Text(
                    'Falha ao carregar análises: '
                    '$_erroAnalises',
                  ),
                )
              : _analises.isEmpty
              ? const Center(child: Text('Nenhuma análise de solo cadastrada.'))
              : ListView.separated(
                  itemCount: _analises.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final analise = _analises[index];

                    return ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(
                        'Coleta: '
                        '${_data(analise['dataColeta'])}',
                      ),
                      subtitle: Text(
                        'pH: ${_numero(analise['ph'])} • '
                        'Fósforo: ${_numero(analise['fosforo'])}\n'
                        'Potássio: ${_numero(analise['potassio'])} • '
                        'Matéria orgânica: '
                        '${_numero(analise['materiaOrganica'])}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // CARD DE INFORMAÇÃO
  Widget _cartao(String titulo, String valor, IconData icone) {
    return SizedBox(
      width: 245,
      child: Card(
        color: corCard,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: corVerdeEscuro),
              const SizedBox(height: 12),
              Text(titulo, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  color: corVerdeEscuro,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LINHA DE INFORMAÇÕES
  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(rotulo)),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // INTERFACE PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,

      appBar: AppBar(
        backgroundColor: corCard,
        title: const Text('Prontuário do Talhão'),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarDados,
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_erro!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _carregarDados,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : _conteudo(),
    );
  }

  // CONTEÚDO DO PRONTUÁRIO
  Widget _conteudo() {
    final talhao = _talhao!;

    final nome = _texto(talhao['nome'], vazio: 'Talhão sem nome');

    final ultimaAnalise = _analises.isNotEmpty ? _analises.first : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.maybePop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar para Talhões'),
            ),

            const SizedBox(height: 12),

            Text(
              nome,
              style: const TextStyle(
                fontSize: 32,
                color: corVerdeEscuro,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_numero(talhao['areaHa'])} hectares • '
              'Cadastrado em '
              '${_data(talhao['criadoEm'])}',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            // CARDS COM DADOS REAIS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _cartao(
                  'Área cadastrada',
                  '${_numero(talhao['areaHa'])} ha',
                  Icons.landscape,
                ),
                _cartao(
                  'Plantios no prontuário',
                  '${_quantidade('totalPlantios')}',
                  Icons.grass,
                ),
                _cartao(
                  'Análises no prontuário',
                  '${_quantidade('totalAnalises')}',
                  Icons.analytics_outlined,
                ),
                _cartao(
                  'Laudos de solo',
                  _erroAnalises == null
                      ? '${_analises.length}'
                      : 'Indisponível',
                  Icons.science_outlined,
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Histórico e registros',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: corVerdeEscuro,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _mostrarPlantios,
                  icon: const Icon(Icons.grass),
                  label: const Text('Ver plantios'),
                ),
                FilledButton.icon(
                  onPressed: _mostrarAnalises,
                  style: FilledButton.styleFrom(backgroundColor: corVerdeClaro),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Ver análises de solo'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ÚLTIMA ANÁLISE DE SOLO
            Card(
              color: corCard,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Última análise de solo',
                      style: TextStyle(
                        color: corVerdeEscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (_erroAnalises != null)
                      Text(
                        'Não foi possível consultar '
                        'as análises: $_erroAnalises',
                      )
                    else if (ultimaAnalise == null)
                      const Text(
                        'Ainda não existe análise de solo '
                        'cadastrada para este talhão.',
                      )
                    else ...[
                      _linha(
                        'Data da coleta',
                        _data(ultimaAnalise['dataColeta']),
                      ),
                      _linha('pH', _numero(ultimaAnalise['ph'])),
                      _linha('Fósforo', _numero(ultimaAnalise['fosforo'])),
                      _linha('Potássio', _numero(ultimaAnalise['potassio'])),
                      _linha(
                        'Matéria orgânica',
                        _numero(ultimaAnalise['materiaOrganica']),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'O status agronômico não é exibido porque '
              'a resposta atual da API não fornece uma '
              'classificação calculada. Nenhuma recomendação '
              'ou indicador foi inventado.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
