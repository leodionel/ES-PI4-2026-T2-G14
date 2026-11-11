import 'package:flutter/material.dart';
import 'pdf_export_service.dart';
import 'culturas_safras_screen.dart';
import 'analise_solo_screen.dart';
import 'simulacao_rotacao_screen.dart';

class ProntuarioScreen extends StatelessWidget {
  const ProntuarioScreen({super.key});

  // Paleta de cores baseada no design
  final Color corFundo = const Color(0xFFF7F5EE);
  final Color corCard = const Color(0xFFF0EBE1);
  final Color corVerdeEscuro = const Color(0xFF4A5D23);
  final Color corVerdeClaro = const Color(0xFF8DA259);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: Row(
        children: [
          // MENU LATERAL (SIDEBAR)
          _buildSidebar(context),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                children: [
                  // CABEÇALHO COM BOTÃO DE VOLTAR
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: Colors.black54),
                        SizedBox(width: 4),
                        Text(
                          'Voltar para Talhões',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Talhões / Talhão 04',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // TÍTULO E STATUS
                  Row(
                    children: [
                      Text(
                        'Talhão 04 - Soja',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: corVerdeEscuro,
                          fontFamily: 'Serif',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: corVerdeClaro.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: corVerdeEscuro),
                            const SizedBox(width: 6),
                            Text(
                              'Saudável',
                              style: TextStyle(
                                color: corVerdeEscuro,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '42,8 hectares  •  Última análise de solo em 10/01/2026',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // BOTÕES DE AÇÃO (PDF + NOVO REGISTRO)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await PdfExportService.exportarProntuarioTalhao();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black54),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Exportar Prontuário PDF',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFF7F5EE),
                              title: const Text(
                                'Novo Registro no Talhão',
                                style: TextStyle(
                                  color: Color(0xFF4A5D23),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Serif',
                                ),
                              ),
                              content: const Text(
                                'Selecione o tipo de informação que deseja registrar:',
                              ),
                              actions: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8DA259),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.grass),
                                  label: const Text('Cultura / Safra'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CulturasSafrasScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A5D23),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.science),
                                  label: const Text('Análise de Solo'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AnaliseSoloScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Registro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corVerdeClaro,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // CARDS DE ANÁLISE DO SOLO (Boletim 100 IAC - Seção 4 do MVP)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoloCard(
                          'pH (CaCl₂)',
                          '5,6',
                          'Faixa adequada',
                          corVerdeEscuro,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSoloCard(
                          'Fósforo (P resina)',
                          '18 mg/dm³',
                          'Teor adequado',
                          corVerdeEscuro,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSoloCard(
                          'Potássio (K)',
                          '2,4 mmolc/dm³',
                          'Teor adequado',
                          corVerdeEscuro,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSoloCard(
                          'Saturação (V%)',
                          '65%',
                          'Laudo de 10/01/2026',
                          corVerdeEscuro,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nota (RN02): O status "Saudável" indica apenas que nenhum dos 4 indicadores avaliados acendeu alerta no último laudo.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),

                  // SEÇÃO INFERIOR: SIMULAÇÃO E RESUMO
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SIMULAÇÃO DE ROTAÇÃO
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
                                'Simulação de Rotação',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: corVerdeEscuro,
                                ),
                              ),
                              const Text(
                                'Última comparação de cenários feita para este talhão',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24),
                              _buildSimulacaoItem(
                                'Recomendado',
                                'Milho (Gramínea) — favorece a alternância após Soja (Leguminosa) (RN04).',
                                corVerdeClaro,
                              ),
                              const SizedBox(height: 16),
                              _buildSimulacaoItem(
                                'Não recomendado',
                                'Soja — repetir a mesma cultura da safra anterior não é recomendado (RN03).',
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 24),

                              // BOTÃO SIMULAR NOVO CENÁRIO CONECTADO À TELA #20
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SimulacaoRotacaoScreen(
                                              talhaoInicialId: '04',
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corVerdeClaro,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Simular novo cenário',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // RESUMO DO TALHÃO
                      Expanded(
                        flex: 4,
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
                                'Resumo do talhão',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: corVerdeEscuro,
                                ),
                              ),
                              const Text(
                                'Dados gerais cadastrados',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24),
                              _buildResumoRow('Área', '42,8 ha'),
                              const SizedBox(height: 16),
                              _buildResumoRow('Cultura atual', 'Soja'),
                              const SizedBox(height: 16),
                              _buildResumoRow('Cultura anterior', 'Milho'),
                              const SizedBox(height: 16),
                              _buildResumoRow(
                                'Status do solo',
                                'Saudável',
                                valueColor: corVerdeEscuro,
                              ),
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildSidebar(BuildContext context) {
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
          _buildMenuItem(
            Icons.autorenew,
            'Simulação de Rotação',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SimulacaoRotacaoScreen(talhaoInicialId: '04'),
                ),
              );
            },
          ),
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
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
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
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildSoloCard(
    String titulo,
    String valor,
    String subtitulo,
    Color tagColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitulo, style: TextStyle(fontSize: 12, color: tagColor)),
        ],
      ),
    );
  }

  Widget _buildSimulacaoItem(String tag, String texto, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: tagColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor == Colors.redAccent
                    ? Colors.red.shade900
                    : corVerdeEscuro,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            texto,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}