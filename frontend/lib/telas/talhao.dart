import 'package:flutter/material.dart';

class TalhoesScreen extends StatelessWidget {
  TalhoesScreen({super.key});

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
                  // CABEÇALHO E BOTÃO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meus Talhões',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: corVerdeEscuro,
                              fontFamily: 'Serif', 
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gerencie o histórico e a saúde do solo de cada área da sua propriedade',
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

                  // PÍLULAS DE RESUMO (Área, Cadastrados, Atenção)
                  Row(
                    children: [
                      _buildResumoPill('Área Total: ', '128.4 ha'),
                      const SizedBox(width: 16),
                      _buildResumoPill('Talhões cadastrados: ', '4'),
                      const SizedBox(width: 16),
                      _buildResumoAlertaPill('2 Talhões em atenção', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // GRADE DE CARDS DOS TALHÕES
                  Row(
                    children: [
                      Expanded(
                        child: _buildTalhaoCard(
                          numero: '01',
                          area: '42.3 ha',
                          cultura: 'Milho',
                          dataPlantio: '04 dez 2025',
                          dataLaudo: '29 jan 2026',
                          status: 'Saudável',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTalhaoCard(
                          numero: '02',
                          area: '20 ha',
                          cultura: 'Soja',
                          dataPlantio: '28 nov 2025',
                          dataLaudo: '14 jan 2026',
                          status: 'Risco',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTalhaoCard(
                          numero: '03',
                          area: '26.1 ha',
                          cultura: 'Feijão',
                          dataPlantio: '08 nov 2025',
                          dataLaudo: '21 jan 2026',
                          status: 'Atenção',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTalhaoCard(
                          numero: '04',
                          area: '40 ha',
                          cultura: 'Batata',
                          dataPlantio: '15 nov 2025',
                          dataLaudo: '10 jan 2026',
                          status: 'Saudável',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (SIDEBAR) ---

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
          // Note que agora o item ativo (isActive: true) é o de Talhões
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

  // --- WIDGETS AUXILIARES (CONTEÚDO DA TELA) ---

  Widget _buildResumoPill(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoAlertaPill(String texto, Color corDot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: corDot),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTalhaoCard({
    required String numero,
    required String area,
    required String cultura,
    required String dataPlantio,
    required String dataLaudo,
    required String status,
  }) {
    // Definindo as cores com base no status (Saudável, Atenção, Risco)
    Color corFundoStatus;
    Color corTextoStatus;

    if (status == 'Saudável') {
      corFundoStatus = corVerdeClaro.withOpacity(0.3);
      corTextoStatus = corVerdeEscuro;
    } else if (status == 'Atenção') {
      corFundoStatus = Colors.orange.withOpacity(0.2);
      corTextoStatus = Colors.orange.shade800;
    } else {
      // Risco
      corFundoStatus = Colors.redAccent.withOpacity(0.2);
      corTextoStatus = Colors.redAccent.shade700;
    }

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
          // CABEÇALHO DO CARD (Título e Tag de Status)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Talhão $numero',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: corVerdeEscuro, fontFamily: 'Serif'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: corFundoStatus,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: corTextoStatus),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: corTextoStatus, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // INFORMAÇÕES DE ÁREA E CULTURA
          Text(
            '$area  •  $cultura',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Plantio em $dataPlantio',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          
          // RODAPÉ DO CARD (Último laudo e Ação)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Último laudo: $dataLaudo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Lógica para abrir os detalhes do Talhão
                  },
                  child: Row(
                    children: [
                      Text(
                        'Ver detalhes',
                        style: TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: corVerdeEscuro),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}