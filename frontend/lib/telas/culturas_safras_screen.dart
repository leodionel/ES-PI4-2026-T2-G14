import 'package:flutter/material.dart';

class CulturasSafrasScreen extends StatefulWidget {
  final String talhaoNome;
  final String talhaoArea;

  const CulturasSafrasScreen({
    super.key,
    this.talhaoNome = 'Talhão 04',
    this.talhaoArea = '42,8 ha',
  });

  @override
  State<CulturasSafrasScreen> createState() => _CulturasSafrasScreenState();
}

class _CulturasSafrasScreenState extends State<CulturasSafrasScreen> {
  // Paleta de cores oficial do projeto
  final Color corFundo = const Color(0xFFF7F5EE);
  final Color corCard = const Color(0xFFF0EBE1);
  final Color corVerdeEscuro = const Color(0xFF4A5D23);
  final Color corVerdeClaro = const Color(0xFF8DA259);

  final _formKey = GlobalKey<FormState>();

  // Catálogo oficial de culturas (RF10 / RN04)
  final List> _catalogoCulturas = [
    {'nome': 'Soja', 'grupo': 'Leguminosa'},
    {'nome': 'Feijão', 'grupo': 'Leguminosa'},
    {'nome': 'Milho', 'grupo': 'Gramínea'},
    {'nome': 'Trigo', 'grupo': 'Gramínea'},
    {'nome': 'Sorgo', 'grupo': 'Gramínea'},
    {'nome': 'Batata', 'grupo': 'Tubérculo / Outra'},
    {'nome': 'Pousio', 'grupo': 'Descanso do solo'},
  ];

  String? _culturaSelecionada;
  final TextEditingController _dataPlantioController = TextEditingController();
  final TextEditingController _dataColheitaController = TextEditingController();
  bool _jaColhida = false;

  // Lista simulando o histórico cronológico vindo do Backend (RF13 / RN05)
  final List> _historicoSafras = [
    {
      'cultura': 'Soja',
      'grupo': 'Leguminosa',
      'dataPlantio': '15/11/2025',
      'dataColheita': null, // Safra em andamento
    },
    {
      'cultura': 'Milho',
      'grupo': 'Gramínea',
      'dataPlantio': '10/02/2025',
      'dataColheita': '28/07/2025',
    },
  ];

  @override
  void dispose() {
    _dataPlantioController.dispose();
    _dataColheitaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
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
        controller.text = '$dia/$mes/$ano';
      });
    }
  }

  void _salvarSafra() {
    if (_formKey.currentState!.validate()) {
      final grupo = _catalogoCulturas.firstWhere(
        (c) => c['nome'] == _culturaSelecionada,
      )['grupo']!;

      setState(() {
        _historicoSafras.insert(0, {
          'cultura': _culturaSelecionada!,
          'grupo': grupo,
          'dataPlantio': _dataPlantioController.text.trim(),
          'dataColheita': _jaColhida && _dataColheitaController.text.isNotEmpty
              ? _dataColheitaController.text.trim()
              : null,
        });

        _culturaSelecionada = null;
        _dataPlantioController.clear();
        _dataColheitaController.clear();
        _jaColhida = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: corVerdeEscuro,
          content: const Text('Registro de safra salvo com sucesso!'),
        ),
      );
    }
  }

  // Modal para registrar a colheita de uma cultura em andamento (RF11)
  void _abrirModalColheita(int index) {
    final TextEditingController colheitaModalController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: corFundo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Registrar Colheita (RF11)',
            style: TextStyle(
              color: corVerdeEscuro,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cultura: ${_historicoSafras[index]['cultura']}\nPlantio em: ${_historicoSafras[index]['dataPlantio']}',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: colheitaModalController,
                readOnly: true,
                onTap: () => _selecionarData(context, colheitaModalController),
                decoration: InputDecoration(
                  labelText: 'Data da colheita *',
                  hintText: 'DD/MM/AAAA',
                  suffixIcon: Icon(Icons.calendar_today, color: corVerdeEscuro),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: corVerdeEscuro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                if (colheitaModalController.text.isNotEmpty) {
                  setState(() {
                    _historicoSafras[index]['dataColheita'] =
                        colheitaModalController.text;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: corVerdeEscuro,
                      content: const Text('Colheita registrada no histórico!'),
                    ),
                  );
                }
              },
              child: const Text('Confirmar Colheita'),
            ),
          ],
        );
      },
    );
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
                  // NAVEGAÇÃO SUPERIOR
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
                    'Talhões / ${widget.talhaoNome} / Culturas e Safras',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registro de Culturas e Safras',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: corVerdeEscuro,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.talhaoNome} (${widget.talhaoArea}) • Cadastre o plantio a partir do catálogo e registre a data de colheita.',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // CONTEÚDO DIVIDIDO: FORMULÁRIO (RF10/RF11) E HISTÓRICO (RF13/RN05)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUNA ESQUERDA: FORMULÁRIO DE PLANTIO
                      Expanded(
                        flex: 5,
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
                                  'Novo Plantio no Talhão',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: corVerdeEscuro,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Escolha a cultura no catálogo oficial e informe a data de plantio.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // CAMPO 1: CATÁLOGO DE CULTURAS (RF10)
                                const Text(
                                  'Cultura plantada (Catálogo) *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _culturaSelecionada,
                                  decoration: InputDecoration(
                                    hintText: 'Selecione uma cultura',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _catalogoCulturas.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['nome'],
                                      child: Text(
                                        '${item['nome']} (${item['grupo']})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (valor) {
                                    setState(() {
                                      _culturaSelecionada = valor;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Selecione uma cultura do catálogo.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // CAMPO 2: DATA DE PLANTIO (RF10)
                                const Text(
                                  'Data de plantio *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _dataPlantioController,
                                  readOnly: true,
                                  onTap: () => _selecionarData(
                                    context,
                                    _dataPlantioController,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Toque para selecionar a data',
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      color: corVerdeEscuro,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'A data de plantio é obrigatória.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // OPÇÃO PARA SAFRA JÁ COLHIDA (RF11)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: corVerdeEscuro,
                                  title: const Text(
                                    'Esta safra já foi colhida (registro retroativo)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  value: _jaColhida,
                                  onChanged: (val) {
                                    setState(() {
                                      _jaColhida = val ?? false;
                                    });
                                  },
                                ),

                                if (_jaColhida) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Data de colheita *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _dataColheitaController,
                                    readOnly: true,
                                    onTap: () => _selecionarData(
                                      context,
                                      _dataColheitaController,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Selecione a data da colheita',
                                      suffixIcon: Icon(
                                        Icons.event_available,
                                        color: corVerdeEscuro,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (_jaColhida &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Informe a data da colheita.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 28),

                                // BOTÃO GRANDE E CLARO (RNF01)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _salvarSafra,
                                    icon: const Icon(Icons.check),
                                    label: const Text(
                                      'Salvar Registro de Safra',
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

                      // COLUNA DIREITA: HISTÓRICO DE SAFRAS E REGISTRO DE COLHEITA
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
                                'Safras Registradas no Talhão',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: corVerdeEscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'As duas últimas safras são consideradas na simulação de rotação (RN05).',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),

                              ...List.generate(_historicoSafras.length, (index) {
                                final safra = _historicoSafras[index];
                                final bool emAndamento =
                                    safra['dataColheita'] == null;
                                final bool usadaNaSimulacao = index < 2;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: emAndamento
                                          ? corVerdeClaro
                                          : Colors.grey.shade300,
                                      width: emAndamento ? 2 : 1,
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
                                          Row(
                                            children: [
                                              Text(
                                                safra['cultura'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: corVerdeEscuro,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: corCard,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  safra['grupo'],
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (usadaNaSimulacao)
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
                                                    ? 'Safra atual / última'
                                                    : 'Penúltima safra',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: corVerdeEscuro,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Plantio: ${safra['dataPlantio']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (emAndamento) ...[
                                        const Text(
                                          'Colheita: Em andamento no campo',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _abrirModalColheita(index),
                                          icon: const Icon(
                                            Icons.agriculture,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Registrar Colheita',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: corVerdeEscuro,
                                            side: BorderSide(
                                              color: corVerdeEscuro,
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Colheita concluída em: ${safra['dataColheita']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
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