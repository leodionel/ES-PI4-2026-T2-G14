import 'package:flutter/material.dart';

import '../../domain/models/talhao_resumo.dart';
import '../theme/app_colors.dart';

// Indicador do status do solo. A cor acompanha sempre o texto, para que o
// significado não dependa só da cor.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final StatusSolo status;

  // Cor associada a cada status. Também usada nas barras do dashboard.
  static Color corDo(StatusSolo status) {
    switch (status) {
      case StatusSolo.saudavel:
        return AppColors.statusSaudavel;
      case StatusSolo.atencao:
        return AppColors.statusAtencao;
      case StatusSolo.risco:
        return AppColors.statusRisco;
      case StatusSolo.semAnalise:
        return AppColors.statusSemAnalise;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = corDo(status);

    return Semantics(
      label: 'Status do solo: ${status.rotulo}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                status.rotulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.texto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
