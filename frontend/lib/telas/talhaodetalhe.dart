import '../core/utils/pdf_export_service.dart';

class ProntuarioScreen extends StatelessWidget {
  ProntuarioScreen({super.key});

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
          _buildSidebar(),
          
          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                children: [
                  // CABEÇALHO COM BOTÃO DE VOLTAR
                  Row(
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      const Text('Voltar para Talhões', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Talhões / Talhão 04', style: TextStyle(color: Colors.black45, fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: corVerdeClaro.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: corVerdeEscuro),
                            const SizedBox(width: 6),
                            Text('Saudável', style: TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '42,8 hectares  •  Estádio atual: R3 — Início da formação de vagens',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // BOTÕES DE AÇÃO
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await PdfExportService.exportarProntuarioTalhao();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black54),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Exportar Prontuário PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Registro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corVerdeClaro,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  // CARDS DE ANÁLISE DO SOLO
                  Row(
                    children: [
                      Expanded(child: _buildSoloCard('pH do solo', '6,2', 'Ideal', corVerdeClaro)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSoloCard('Matéria orgânica', '3,1%', 'Adequado', corVerdeClaro)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSoloCard('Nitrogênio', 'Baixo', 'Atenção na próxima safra', Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSoloCard('Última analise', '10 jan', 'Laudo cadastrado em 2026', Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 32),

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
                              Text('Simulação de Rotação', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corVerdeEscuro)),
                              const Text('Última comparação de cenários feita para este talhão', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 24),
                              
                              _buildSimulacaoItem('Recomendado', 'Feijão - fixa nitrogênio e recompõe o solo após a soja', corVerdeClaro),
                              const SizedBox(height: 16),
                              _buildSimulacaoItem('Alternativa', 'Milho - mantém produtividade, mas nao recompõe nitrogênio', Colors.orange.shade300),
                              
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: corVerdeClaro,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Simular novo cenário', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
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
                              Text('Resumo do talhão', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corVerdeEscuro)),
                              const Text('Dados gerais cadastrados', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 24),
                              
                              _buildResumoRow('Área', '42,8 ha'),
                              const SizedBox(height: 16),
                              _buildResumoRow('Cultura atual', 'Soja'),
                              const SizedBox(height: 16),
                              _buildResumoRow('Cultura anterior', 'Milho'),
                              const SizedBox(height: 16),
                              _buildResumoRow('Status geral', 'Saudável', valueColor: corVerdeClaro),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: corCard,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prontuário Digital\ndo Talhão', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corVerdeEscuro, fontFamily: 'Serif')),
          const SizedBox(height: 40),
          const Text('GESTÃO DA FAZENDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildMenuItem(Icons.dashboard, 'Dashboard'),
          _buildMenuItem(Icons.layers, 'Talhões', isActive: true),
          _buildMenuItem(Icons.autorenew, 'Simulação de Rotação'),
          _buildMenuItem(Icons.person, 'Perfil'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(8)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Área monitorada', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('128.4 ha', style: TextStyle(fontSize: 20, color: Colors.black87)),
                Text('6 talhões cadastrados\n3 alertas ativos', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          )
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
        title: Text(title, style: TextStyle(color: isActive ? corVerdeEscuro : Colors.black87, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        onTap: () {},
      ),
    );
  }

  Widget _buildSoloCard(String titulo, String valor, String subtitulo, Color tagColor) {
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
          Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
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
              color: tagColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(tag, style: TextStyle(color: tagColor == Colors.black54 ? Colors.black87 : corVerdeEscuro, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 12),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
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
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }
}