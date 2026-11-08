import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                  // CABEÇALHO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, Leonardo',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: corVerdeEscuro,
                              fontFamily: 'Serif', // Ajuste para a fonte serifada do seu projeto
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Aqui está o panorama geral da Fazenda Santa Clara hoje.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Novo Talhão'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corVerdeClaro,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // CARDS DE INDICADORES (KPIs)
                  Row(
                    children: [
                      _buildKpiCard('Área total', '128,4 ha', '4 Talhões cadastrados'),
                      const SizedBox(width: 16),
                      _buildKpiCard('Talhões saudáveis', '2', '50% da propriedade', textColor: corVerdeVerdeClaro),
                      const SizedBox(width: 16),
                      _buildKpiCard('Em atenção', '1', 'Nitrogênio baixo', textColor: Colors.orange),
                      const SizedBox(width: 16),
                      _buildKpiCard('Em risco', '1', 'pH fora da faixa', textColor: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // SEÇÃO DO MEIO (SAÚDE DO SOLO E ATIVIDADES)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SAÚDE DO SOLO
                      Expanded(
                        flex: 2,
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
                              Text('Saúde geral do solo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corVerdeEscuro)),
                              const Text('Distribuição de status entre os talhões da propriedade', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 16),
                              // Barra de status visual simulada
                              Row(
                                children: [
                                  Expanded(flex: 2, child: Container(height: 12, color: corVerdeClaro)),
                                  Expanded(flex: 1, child: Container(height: 12, color: Colors.orange)),
                                  Expanded(flex: 1, child: Container(height: 12, color: Colors.redAccent)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text('Talhões que precisam de atenção', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 16),
                              _buildAlertItem('Talhão 2 - Soja', 'pH fora da faixa ideal • último laudo em 14 jan 2026', 'Risco', Colors.redAccent),
                              const SizedBox(height: 12),
                              _buildAlertItem('Talhão 3 - Feijão', 'Nitrogênio baixo • recomenda-se rotação', 'Atenção', Colors.orange),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // ATIVIDADE RECENTE
                      Expanded(
                        flex: 1,
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
                              Text('Atividade recente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corVerdeEscuro)),
                              const SizedBox(height: 16),
                              _buildActivityItem('Ánalise de solo - Talhão 04', '10 jan 2026', Colors.orangeAccent),
                              _buildActivityItem('Praga identificada - Talhão 02', '12 jan 2026', Colors.redAccent),
                              _buildActivityItem('Plantio de Batata - Talhão 04', '15 nov 2025', corVerdeClaro),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // BANNER INFERIOR
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: corVerdeEscuro,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pronto para planejar a próxima safra?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Compare cenários de rotação com base no histórico dos seus talhões', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: corVerdeEscuro,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Simular Rotação', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
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
          _buildMenuItem(Icons.dashboard, 'Dashboard', isActive: true),
          _buildMenuItem(Icons.layers, 'Talhões'),
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

  Widget _buildKpiCard(String title, String value, String subtitle, {Color? textColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: corCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor ?? Colors.black)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.7) ?? Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, String tag, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: tagColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: tagColor.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Text(tag, style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String date, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 12, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const Divider(),
              ],
            ),
          )
        ],
      ),
    );
  }
}