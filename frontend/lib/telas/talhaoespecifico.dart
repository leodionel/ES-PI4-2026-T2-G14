import 'package:flutter/material.dart';

class LinhaTempoScreen extends StatelessWidget {
  LinhaTempoScreen({super.key});

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
            child: Row(
              children: [
                // Faixa branca decorativa do fundo (igual ao design)
                Container(
                  width: 120,
                  color: Colors.white,
                ),
                Expanded(
                  child: Container(
                    color: corFundo,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32.0, right: 32.0, bottom: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CABEÇALHO
                          Transform.translate(
                            offset: const Offset(-80, 0), // Ajuste para o texto sobrepor a faixa branca
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, size: 10, color: corVerdeEscuro),
                                          const SizedBox(width: 6),
                                          Text('Em monitoramento', style: TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold, fontSize: 12)),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // LISTA DA LINHA DO TEMPO
                          Expanded(
                            child: ListView(
                              children: [
                                _buildTimelineItem(
                                  dotColor: Colors.black,
                                  titulo: 'Aplicação de Fungicida',
                                  descricao: 'Fox X pro - 0.5L/ha - volume de calda 120L/ha\nRegistrado por Lucas Kendi',
                                  data: '18 JAN 2026',
                                ),
                                _buildTimelineItem(
                                  dotColor: Colors.orangeAccent,
                                  titulo: 'Alerta de Praga',
                                  descricao: 'Percevejo-marrom identificado - nivel 1,8 insetos/m\nRegistrado por Lucas Kendi',
                                  data: '12 JAN 2026',
                                ),
                                _buildTimelineItem(
                                  dotColor: Colors.blue,
                                  titulo: 'Chuva registrada',
                                  descricao: '43mm de chuva acumulados em 3h\nRegistrado por Lucas Kendi',
                                  data: '08 JAN 2026',
                                ),
                                _buildTimelineItem(
                                  dotColor: corVerdeClaro,
                                  titulo: 'Plantio de Milho',
                                  descricao: 'Plantio de Milho Híbrido - população para 500 mil plantas/ha\n+5,2% vs. Safra anterior',
                                  data: '15 NOV 2025',
                                ),
                                _buildTimelineItem(
                                  dotColor: Colors.purpleAccent,
                                  titulo: 'Colheita de Batata',
                                  descricao: 'Colheita de Batata - 100% do Talhão 4\nRegistrado por Lucas Kendi',
                                  data: '04 NOV 2025',
                                  isLast: true,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  // Componente nativo construído para simular a linha do tempo do Figma
  Widget _buildTimelineItem({
    required Color dotColor,
    required String titulo,
    required String descricao,
    required String data,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lado esquerdo (Ponto e Linha)
          Transform.translate(
            offset: const Offset(-80, 0),
            child: SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lado direito (Card de conteúdo)
          Expanded(
            child: Transform.translate(
              offset: const Offset(-60, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corCard, width: 3), // Borda bege simulando o design
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: corVerdeEscuro,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              descricao,
                              style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        data,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}