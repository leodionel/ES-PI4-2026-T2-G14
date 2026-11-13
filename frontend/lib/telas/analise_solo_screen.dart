import 'package:flutter/material.dart';

import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';

class AnaliseSoloScreen extends StatefulWidget {
  const AnaliseSoloScreen({
    super.key,
    this.talhaoId,
    this.talhaoNome,
    this.talhaoArea,
  });

  final String? talhaoId;
  final String? talhaoNome;
  final String? talhaoArea;

  @override
  State<AnaliseSoloScreen> createState() => _AnaliseSoloScreenState();
}

class _AnaliseSoloScreenState extends State<AnaliseSoloScreen> {
  // CORES DO PROJETO
  static const Color corFundo = Color(0xFFF7F5EE);
  static const Color corCard = Color(0xFFF0EBE1);
  static const Color corVerdeEscuro = Color(0xFF4A5D23);
  static const Color corVerdeClaro = Color(0xFF8DA259);

  // SERVIÇOS
  final ApiClient _api = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  // FORMULÁRIO
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dataAnaliseController = TextEditingController();

  final TextEditingController _phController = TextEditingController();

  final TextEditingController _fosforoController = TextEditingController();

  final TextEditingController _potassioController = TextEditingController();

  final TextEditingController _materiaOrganicaController =
      TextEditingController();

  final TextEditingController _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;

  // DADOS REAIS DA API
  Map<String, dynamic>? _talhao;
  String? _propriedadeId;

  List<Map<String, dynamic>> _laudosCadastrados = [];

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _dataAnaliseController.dispose();
    _phController.dispose();
    _fosforoController.dispose();
    _potassioController.dispose();
    _materiaOrganicaController.dispose();
    _observacoesController.dispose();

    super.dispose();
  }

  // ============================================
  // AUTENTICAÇÃO JWT
  // ============================================

  Future<String> _obterToken() async {
    final token = await _tokenStorage.lerToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return token;
  }

  // ============================================
  // CARREGAR DADOS REAIS DO BACKEND
  // ============================================

  Future<void> _carregarDados() async {
    final talhaoId = widget.talhaoId?.trim();

    if (talhaoId == null || talhaoId.isEmpty) {
      setState(() {
        _carregando = false;
        _erro =
            'Nenhum talhão foi selecionado. '
            'Volte à lista de talhões e escolha um talhão.';
      });

      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = await _obterToken();

      // BUSCAR DADOS DO TALHÃO
      final retornoTalhao = await _api.get(
        '/api/talhoes/${Uri.encodeComponent(talhaoId)}',
        token: token,
      );

      if (retornoTalhao is! Map) {
        throw const FormatException('A API não retornou os dados do talhão.');
      }

      final talhao = Map<String, dynamic>.from(retornoTalhao);

      // BUSCAR PROPRIEDADES DO USUÁRIO
      final retornoPropriedades = await _api.get(
        '/api/propriedades',
        token: token,
      );

      if (retornoPropriedades is! List || retornoPropriedades.isEmpty) {
        throw Exception('Nenhuma propriedade cadastrada foi encontrada.');
      }

      final propriedade = Map<String, dynamic>.from(
        retornoPropriedades.first as Map,
      );

      final propriedadeId = propriedade['id']?.toString();

      if (propriedadeId == null || propriedadeId.isEmpty) {
        throw const FormatException('A propriedade não possui um ID válido.');
      }

      // BUSCAR ANÁLISES SALVAS NO MONGODB
      final retornoAnalises = await _api.get(
        '/api/analises-solo',
        token: token,
      );

      if (retornoAnalises is! List) {
        throw const FormatException('A API não retornou a lista de análises.');
      }

      // FILTRAR ANÁLISES DO TALHÃO ATUAL
      final analises = retornoAnalises
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where(
            (item) =>
                item['talhaoId']?.toString() == talhaoId &&
                item['propriedadeId']?.toString() == propriedadeId,
          )
          .toList();

      // ORDENAR PELA DATA DA COLETA
      analises.sort(
        (a, b) => (b['dataColeta'] ?? '').toString().compareTo(
          (a['dataColeta'] ?? '').toString(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _talhao = talhao;
        _propriedadeId = propriedadeId;
        _laudosCadastrados = analises;
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

  // ============================================
  // CALENDÁRIO EM PORTUGUÊS BRASILEIRO
  // ============================================

  Future<void> _selecionarData() async {
    final DateTime? selecionada = await showDatePicker(
      context: context,

      // IDIOMA PORTUGUÊS DO BRASIL
      locale: const Locale('pt', 'BR'),

      initialDate: _dataSelecionada ?? DateTime.now(),

      firstDate: DateTime(2015),
      lastDate: DateTime.now(),

      // TEXTOS DO CALENDÁRIO EM PORTUGUÊS
      helpText: 'SELECIONE A DATA DA ANÁLISE',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: corVerdeEscuro,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selecionada != null && mounted) {
      setState(() {
        _dataSelecionada = selecionada;

        // DATA VISÍVEL: DD/MM/AAAA
        _dataAnaliseController.text = _formatarDataSelecionada(selecionada);
      });
    }
  }

  // ============================================
  // FORMATAÇÃO DA DATA BRASILEIRA
  // ============================================

  String _formatarDataSelecionada(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');

    final mes = data.month.toString().padLeft(2, '0');

    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // FORMATO UTILIZADO INTERNAMENTE PELA API JAVA
  String _dataParaApi(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');

    final dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }

  // CONVERTER DATA DO BACKEND PARA PT-BR
  String _formatarData(dynamic valor) {
    final texto = valor?.toString() ?? '';

    if (texto.isEmpty) {
      return 'Não informada';
    }

    final data = DateTime.tryParse(texto);

    if (data == null) {
      return texto;
    }

    return _formatarDataSelecionada(data);
  }

  // ============================================
  // FORMATAÇÃO DE NÚMEROS
  // ============================================

  String _formatarNumero(dynamic valor) {
    if (valor == null) {
      return 'Não informado';
    }

    if (valor is num) {
      final casasDecimais = valor == valor.roundToDouble() ? 0 : 2;

      return valor.toStringAsFixed(casasDecimais).replaceAll('.', ',');
    }

    return valor.toString().replaceAll('.', ',');
  }

  // ============================================
  // VALIDAÇÃO DO FORMULÁRIO
  // ============================================

  String? _validarNumero(
    String? valor,
    String nomeCampo, {
    bool obrigatorio = true,
    double? min,
    double? max,
  }) {
    final texto = (valor ?? '').trim();

    if (texto.isEmpty) {
      return obrigatorio ? 'O campo $nomeCampo é obrigatório.' : null;
    }

    final numero = double.tryParse(texto.replaceAll(',', '.'));

    if (numero == null || !numero.isFinite) {
      return 'Informe um valor numérico válido.';
    }

    if (min != null && numero < min) {
      return 'Valor mínimo permitido: $min';
    }

    if (max != null && numero > max) {
      return 'Valor máximo permitido: $max';
    }

    return null;
  }

  double _converterNumero(String texto) {
    return double.parse(texto.trim().replaceAll(',', '.'));
  }

  // ============================================
  // CADASTRAR ANÁLISE NA API JAVA
  // ============================================

  Future<void> _registrarLaudo() async {
    if (_salvando || _carregando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final talhaoId = widget.talhaoId;
    final propriedadeId = _propriedadeId;
    final dataColeta = _dataSelecionada;

    if (talhaoId == null ||
        talhaoId.isEmpty ||
        propriedadeId == null ||
        dataColeta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o talhão, '
            'a propriedade ou a data da análise.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final token = await _obterToken();

      final materiaOrganicaTexto = _materiaOrganicaController.text.trim();

      final observacoesTexto = _observacoesController.text.trim();

      // ENVIO DE DADOS REAIS AO BACKEND
      await _api.post('/api/analises-solo', {
        'propriedadeId': propriedadeId,
        'talhaoId': talhaoId,

        // API RECEBE AAAA-MM-DD
        'dataColeta': _dataParaApi(dataColeta),

        'ph': _converterNumero(_phController.text),

        'fosforo': _converterNumero(_fosforoController.text),

        'potassio': _converterNumero(_potassioController.text),

        'materiaOrganica': materiaOrganicaTexto.isEmpty
            ? null
            : _converterNumero(materiaOrganicaTexto),

        'observacoes': observacoesTexto.isEmpty ? null : observacoesTexto,
      }, token: token);

      if (!mounted) return;

      // LIMPAR FORMULÁRIO APÓS SALVAR
      _dataSelecionada = null;

      _dataAnaliseController.clear();
      _phController.clear();
      _fosforoController.clear();
      _potassioController.clear();
      _materiaOrganicaController.clear();
      _observacoesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: corVerdeEscuro,
          content: Text('Análise de solo salva com sucesso!'),
        ),
      );

      // ATUALIZAR HISTÓRICO REAL
      await _carregarDados();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Não foi possível salvar a análise: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // ============================================
  // COMPONENTES DO FORMULÁRIO
  // ============================================

  Widget _buildLabel(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _campoNumerico({
    required String titulo,
    required String subtitulo,
    required String hint,
    required TextEditingController controller,
    required String nomeValidacao,
    String? unidade,
    bool obrigatorio = true,
    double? minimo,
    double? maximo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(titulo, subtitulo),
        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _buildInputDecoration(hint: hint, suffixText: unidade),
          validator: (valor) => _validarNumero(
            valor,
            nomeValidacao,
            obrigatorio: obrigatorio,
            min: minimo,
            max: maximo,
          ),
        ),
      ],
    );
  }

  Widget _buildParametroRow(String nome, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),

          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // FORMULÁRIO DE CADASTRO
  // ============================================

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inserir Novo Laudo Químico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: corVerdeEscuro,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Preencha os dados da análise '
              'para salvá-la no MongoDB Atlas.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // DATA DA ANÁLISE
            _buildLabel(
              'Data da análise *',
              'Identificação da coleta no histórico',
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _dataAnaliseController,
              readOnly: true,
              onTap: _selecionarData,
              decoration: _buildInputDecoration(
                hint: 'DD/MM/AAAA',
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: corVerdeEscuro,
                ),
              ),
              validator: (valor) {
                if (_dataSelecionada == null) {
                  return 'A data da análise é obrigatória.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // PH E FÓSFORO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campoNumerico(
                    titulo: 'pH (CaCl₂) *',
                    subtitulo: 'Sem unidade',
                    hint: 'Ex: 5,6',
                    controller: _phController,
                    nomeValidacao: 'pH',
                    minimo: 0,
                    maximo: 14,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _campoNumerico(
                    titulo: 'Fósforo (P resina) *',
                    subtitulo: 'Unidade: mg/dm³',
                    hint: 'Ex: 18,0',
                    controller: _fosforoController,
                    nomeValidacao: 'Fósforo',
                    unidade: 'mg/dm³',
                    minimo: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // POTÁSSIO E MATÉRIA ORGÂNICA
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campoNumerico(
                    titulo: 'Potássio (K) *',
                    subtitulo: 'Unidade: mmolc/dm³',
                    hint: 'Ex: 2,4',
                    controller: _potassioController,
                    nomeValidacao: 'Potássio',
                    unidade: 'mmolc/dm³',
                    minimo: 0,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _campoNumerico(
                    titulo: 'Matéria orgânica',
                    subtitulo: 'Opcional',
                    hint: 'Informe o valor',
                    controller: _materiaOrganicaController,
                    nomeValidacao: 'Matéria orgânica',
                    obrigatorio: false,
                    minimo: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // OBSERVAÇÕES
            _buildLabel('Observações', 'Informações complementares (opcional)'),

            const SizedBox(height: 8),

            TextFormField(
              controller: _observacoesController,
              maxLines: 3,
              maxLength: 1000,
              decoration: _buildInputDecoration(
                hint: 'Observações sobre a coleta ou laudo',
              ),
            ),

            const SizedBox(height: 12),

            // AVISO SOBRE SATURAÇÃO POR BASES
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'A saturação por bases (V%) '
                'ainda não faz parte do cadastro '
                'da API Java. '
                'Ela não será solicitada nem '
                'simulada nesta versão.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 24),

            // BOTÃO DE CADASTRO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _registrarLaudo,

                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.science),

                label: Text(
                  _salvando
                      ? 'Salvando análise...'
                      : 'Registrar Análise de Solo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: corVerdeEscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HISTÓRICO REAL DE ANÁLISES
  // ============================================

  Widget _buildHistorico() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laudos Registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: corVerdeEscuro,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Histórico real das análises '
            'vinculadas a este talhão.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          TextButton.icon(
            onPressed: _salvando ? null : _carregarDados,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar histórico'),
          ),

          const SizedBox(height: 12),

          // NENHUMA ANÁLISE ENCONTRADA
          if (_laudosCadastrados.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Nenhuma análise de solo '
                'cadastrada para este talhão.',
              ),
            )
          else
            ...List.generate(_laudosCadastrados.length, (index) {
              final laudo = _laudosCadastrados[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == 0 ? corVerdeClaro : Colors.grey.shade300,
                    width: index == 0 ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATA DO LAUDO EM PORTUGUÊS
                    Text(
                      'Laudo de '
                      '${_formatarData(laudo['dataColeta'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: corVerdeEscuro,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (index == 0)
                      const Text(
                        'Análise mais recente',
                        style: TextStyle(
                          fontSize: 12,
                          color: corVerdeClaro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const Divider(height: 24),

                    _buildParametroRow(
                      'pH (CaCl₂)',
                      _formatarNumero(laudo['ph']),
                    ),

                    _buildParametroRow(
                      'Fósforo (P resina)',
                      _formatarNumero(laudo['fosforo']),
                    ),

                    _buildParametroRow(
                      'Potássio (K)',
                      _formatarNumero(laudo['potassio']),
                    ),

                    _buildParametroRow(
                      'Matéria orgânica',
                      _formatarNumero(laudo['materiaOrganica']),
                    ),

                    if (laudo['observacoes'] != null &&
                        laudo['observacoes'].toString().trim().isNotEmpty) ...[
                      const Divider(height: 24),

                      const Text(
                        'Observações:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),

                      Text(laudo['observacoes'].toString()),
                    ],
                  ],
                ),
              );
            }),

          const SizedBox(height: 8),

          const Text(
            'A API atual não retorna um status '
            'agronômico calculado. '
            'Os valores exibidos são os registrados.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MENU LATERAL
  // ============================================

  Widget _buildSidebar() {
    final nome = _talhao?['nome']?.toString() ?? widget.talhaoNome ?? 'Talhão';

    final area = _talhao == null
        ? (widget.talhaoArea ?? 'Não informada')
        : '${_formatarNumero(_talhao!['areaHa'])} ha';

    return Container(
      width: 250,
      color: corCard,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prontuário Digital\ndo Talhão',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: corVerdeEscuro,
              fontFamily: 'Serif',
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            'GESTÃO DA FAZENDA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Voltar ao talhão'),
            onTap: () {
              Navigator.maybePop(context);
            },
          ),

          const ListTile(
            leading: Icon(Icons.science, color: corVerdeEscuro),
            title: Text(
              'Análise de Solo',
              style: TextStyle(
                color: corVerdeEscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),

                Text(
                  area,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                ),

                const Text(
                  'Área do talhão selecionado',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CONTEÚDO PRINCIPAL
  // ============================================

  Widget _buildConteudo() {
    final nome = _talhao?['nome']?.toString() ?? widget.talhaoNome ?? 'Talhão';

    final area = _talhao == null
        ? (widget.talhaoArea ?? 'Não informada')
        : '${_formatarNumero(_talhao!['areaHa'])} ha';

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        // VOLTAR
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: Text('Voltar para $nome'),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Talhões / $nome / Análise de Solo',
          style: const TextStyle(color: Colors.black45, fontSize: 12),
        ),

        const SizedBox(height: 8),

        const Text(
          'Registro de Análise de Solo',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: corVerdeEscuro,
            fontFamily: 'Serif',
          ),
        ),

        const SizedBox(height: 4),

        Text(
          '$nome ($area) • Análises químicas '
          'registradas no sistema.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),

        const SizedBox(height: 24),

        // INFORMAÇÕES SOBRE A ANÁLISE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: corVerdeClaro),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: corVerdeEscuro),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Esta tela registra e consulta '
                  'dados reais de análises de solo. '
                  'A interpretação agronômica deve '
                  'ser realizada pelo backend. '
                  'O sistema é um apoio à decisão '
                  'e não substitui um engenheiro '
                  'agrônomo.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // FORMULÁRIO E HISTÓRICO
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  _buildFormulario(),

                  const SizedBox(height: 24),

                  _buildHistorico(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildFormulario()),

                const SizedBox(width: 24),

                Expanded(flex: 5, child: _buildHistorico()),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================
  // CONSTRUÇÃO DA TELA
  // ============================================

  @override
  Widget build(BuildContext context) {
    final mostrarSidebar = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: corFundo,
      body: Row(
        children: [
          if (mostrarSidebar) _buildSidebar(),

          Expanded(
            child: _carregando
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

                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                            child: const Text('Voltar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildConteudo(),
          ),
        ],
      ),
    );
  }
}
