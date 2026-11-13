
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.painel,
        title: const Text('Meu perfil'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),

              Text(
                'Perfil do produtor',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),

              const SizedBox(height: 8),

              const Text(
                'Consulte e gerencie as informações '
                'da sua conta.',
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.painel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.borda,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.verde,
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minha conta',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppColors.verdeEscuro,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Informações cadastrais',
                                style: TextStyle(
                                  color:
                                      AppColors.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _campo(
                      icone: Icons.badge_outlined,
                      titulo: 'Nome completo',
                    ),

                    const Divider(height: 28),

                    _campo(
                      icone: Icons.email_outlined,
                      titulo: 'E-mail',
                    ),

                    const Divider(height: 28),

                    _campo(
                      icone: Icons.phone_outlined,
                      titulo: 'Telefone',
                    ),

                    const SizedBox(height: 28),

                    const SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.edit_outlined),
                        label: Text('Editar dados'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borda,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.verdeEscuro,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A consulta e a edição do perfil '
                        'ainda dependem da integração '
                        'com a API de usuários. '
                        'Nenhuma informação fictícia '
                        'está sendo exibida.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Voltar ao Dashboard',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required IconData icone,
    required String titulo,
  }) {
    return Row(
      children: [
        Icon(
          icone,
          color: AppColors.verdeEscuro,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.texto,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Ainda não carregado',
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
