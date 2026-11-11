import 'package:flutter/material.dart';

class AnaliseSoloScreen extends StatefulWidget {
  final String talhaoNome;
  final String talhaoArea;

  const AnaliseSoloScreen({
    super.key,
    this.talhaoNome = 'Talhão 04',
    this.talhaoArea = '42,8 ha',
  });

  @override
  State<AnaliseSoloScreen> createState() => _AnaliseSoloScreenState();
}

class _AnaliseSoloScreenState extends State<AnaliseSoloScreen> {
  // Paleta de cores oficial do projeto
  final Color corFundo = const Color(0xFFF7F5EE);
  final Color corCard = const Color(0xFFF0EBE1);
  final Color corVerdeEscuro = const Color(0xFF4A5D23);
  final Color corVerdeClaro = const Color(0xFF8DA259);

  final _formKey = GlobalKey<FormState>();

  // Controladores para os 5 campos estritamente obrigatórios (Seção 4 do MVP)
  final TextEditingController _dataAnaliseController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _fosforoController = TextEditingController();
  final TextEditingController _potassioController = TextEditingController();
  final TextEditingController _saturacaoBasesController =
      TextEditingController();

  // Histórico de laudos exibido na tela (O status vem calculado pelo Backend - Seção 2 / RN02)
  final List> _laudosCadastrados = [
    {
      'data': '10/01/2026',
      'ph': '5,6',
      'fosforo': '18,0',
      'potassio': '2,4',
      'saturacaoV': '65',
      'statusBackend': 'Saudável',
    },
  ];

  @override
  void dispose() {
    _dataAnaliseController.dispose();
    _phController.dispose();
    _fosforoController.dispose();
    _potassioController.dispose();
    _saturacaoBasesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: corVerdeEscuro,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selecionada != null) {
      final dia = selecionada.day.toString().padLeft(2, '0');
      final mes = selecionada.month.toString().padLeft(2, '0');
      final ano = selecionada.year.toString();
      setState(() {
        _dataAnaliseController.text = '$dia/$mes/$ano';
      });
    }
  }

  String? _validarNumeroObrigatorio(
    String? valor,
    String nomeCampo, {
    double? min,
    double? max,
  }) {
    if (valor == null || valor.trim().isEmpty) {
      return 'O campo $nomeCampo é obrigatório.';
    }
    final normalizado = valor.replaceAll(',', '.');
    final numero = double.tryParse(normalizado);
    if (numero == null) {
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

  void _registrarLaudo() {
    if (_formKey.currentState!.validate()) {
      // O aplicativo apenas envia os dados brutos via socket/API;
      // o status do solo é calculado exclusivamente pelo Backend (Seção 2).
      setState(() {
        _laudosCadastrados.insert(0, {
          'data': _dataAnaliseController.text.trim(),
          'ph': _phController.text.trim(),
          'fosforo': _fosforoController.text.trim(),
          'potassio': _potassioController.text.trim(),
          'saturacaoV': _saturacaoBasesController.text.trim(),
          'statusBackend': 'Aguardando cálculo do servidor',
        });

        _dataAnaliseController.clear();
        _phController.clear();
        _fosforoController.clear();
        _potassioController.clear();
        _saturacaoBasesController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: corVerdeEscuro,
          content: const Text(
            'Análise de solo registrada! Dados prontos para envio ao servidor.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                children: [
                  // CABEÇALHO E NAVEGAÇÃO
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Voltar para ${widget.talhaoNome}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Talhões / ${widget.talhaoNome} / Análise de Solo',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
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
                    '${widget.talhaoNome} (${widget.talhaoArea}) • Parâmetros químicos de rotina conforme Boletim Técnico 100 do IAC.',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // TEXTO DE AJUDA OBRIGATÓRIO NA INTERFACE (RN02 e Seção 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corVerdeClaro),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: corVerdeEscuro),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Como funciona a interpretação do solo (RN02)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'O status do solo (Saudável, Atenção ou Risco) é calculado pelo servidor a partir da última análise cadastrada. '
                                '"Saudável" significa apenas que nenhum indicador avaliado acendeu alerta. Talhão sem laudo recebe o status "Sem análise". '
                                'Este sistema é um apoio à decisão: não prescreve doses de calcário ou fertilizantes e não substitui um engenheiro agrônomo.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CONTEÚDO PRINCIPAL: FORMULÁRIO (RF12) + ÚLTIMO LAUDO
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUNA ESQUERDA: FORMULÁRIO DE CADASTRO DO LAUDO
                      Expanded(
                        flex: 6,
                        child: Container(
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
                                Text(
                                  'Inserir Novo Laudo Químico',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: corVerdeEscuro,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Todos os campos abaixo são de preenchimento manual e obrigatório (RN07).',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 1. DATA DA ANÁLISE
                                _buildLabel(
                                  'Data da análise *',
                                  'Identificação do laudo na linha do tempo',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _dataAnaliseController,
                                  readOnly: true,
                                  onTap: () => _selecionarData(context),
                                  decoration: _buildInputDecoration(
                                    hint: 'DD/MM/AAAA',
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      color: corVerdeEscuro,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'A data da análise é obrigatória.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // LINHA 1 DE INDICADORES: pH (CaCl2) e Fósforo (P resina)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel(
                                            'pH (CaCl₂) *',
                                            'Sem unidade (Ex: 5,5)',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _phController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: _buildInputDecoration(
                                              hint: 'Ex: 5,6',
                                            ),
                                            validator: (v) =>
                                                _validarNumeroObrigatorio(
                                                  v,
                                                  'pH (CaCl₂)',
                                                  min: 0,
                                                  max: 14,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel(
                                            'Fósforo (P resina) *',
                                            'Unidade: mg/dm³',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _fosforoController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: _buildInputDecoration(
                                              hint: 'Ex: 18,0',
                                              suffixText: 'mg/dm³',
                                            ),
                                            validator: (v) =>
                                                _validarNumeroObrigatorio(
                                                  v,
                                                  'Fósforo (P)',
                                                  min: 0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // LINHA 2 DE INDICADORES: Potássio (K) e Saturação por bases (V)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel(
                                            'Potássio (K) *',
                                            'Unidade: mmolc/dm³',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _potassioController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: _buildInputDecoration(
                                              hint: 'Ex: 2,4',
                                              suffixText: 'mmolc/dm³',
                                            ),
                                            validator: (v) =>
                                                _validarNumeroObrigatorio(
                                                  v,
                                                  'Potássio (K)',
                                                  min: 0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel(
                                            'Saturação por bases (V) *',
                                            'Unidade: % (0 a 100)',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller:
                                                _saturacaoBasesController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: _buildInputDecoration(
                                              hint: 'Ex: 65',
                                              suffixText: '%',
                                            ),
                                            validator: (v) =>
                                                _validarNumeroObrigatorio(
                                                  v,
                                                  'Saturação (V%)',
                                                  min: 0,
                                                  max: 100,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // BOTÃO DE SUBMISSÃO GRANDE (RNF01)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _registrarLaudo,
                                    icon: const Icon(Icons.science),
                                    label: const Text(
                                      'Registrar Análise de Solo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: corVerdeEscuro,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // COLUNA DIREITA: RESUMO DOS LAUDOS REGISTRADOS
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laudos Registrados',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: corVerdeEscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Histórico de análises químicas vinculadas a este talhão.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (_laudosCadastrados.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Status: Sem análise (Nenhum laudo cadastrado para este talhão).',
                                  ),
                                )
                              else
                                ...List.generate(_laudosCadastrados.length, (
                                  index,
                                ) {
                                  final laudo = _laudosCadastrados[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: index == 0
                                            ? corVerdeClaro
                                            : Colors.grey.shade300,
                                        width: index == 0 ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Laudo de ${laudo['data']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: corVerdeEscuro,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: corVerdeClaro
                                                    .withOpacity(0.25),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                index == 0
                                                    ? 'Último laudo (${laudo['statusBackend']})'
                                                    : laudo['statusBackend']!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: corVerdeEscuro,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        _buildParametroRow(
                                          'pH (CaCl₂)',
                                          laudo['ph']!,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildParametroRow(
                                          'Fósforo (P resina)',
                                          '${laudo['fosforo']} mg/dm³',
                                        ),
                                        const SizedBox(height: 8),
                                        _buildParametroRow(
                                          'Potássio (K)',
                                          '${laudo['potassio']} mmolc/dm³',
                                        ),
                                        const SizedBox(height: 8),
                                        _buildParametroRow(
                                          'Saturação por bases (V)',
                                          '${laudo['saturacaoV']} %',
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildParametroRow(String nome, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nome, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // --- SIDEBAR PADRÃO ---
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: corCard,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
          _buildMenuItem(Icons.dashboard, 'Dashboard'),
          _buildMenuItem(Icons.layers, 'Talhões', isActive: true),
          _buildMenuItem(Icons.autorenew, 'Simulação de Rotação'),
          _buildMenuItem(Icons.person, 'Perfil'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Área monitorada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '128,4 ha',
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                ),
                Text(
                  '4 talhões cadastrados',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? corVerdeEscuro : Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? corVerdeEscuro : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}