// FEITO POR (Demetrius Valverde) RA: (25015035)

import 'classificacao.dart';
import 'mensagem_regra.dart';

// Resultado de uma cultura candidata na comparacao.
class CenarioResultado {
  const CenarioResultado({
    required this.cultura,
    required this.classificacao,
    required this.temAlerta,
    required this.mensagens,
  });

  final String cultura;
  final Classificacao classificacao;
  final bool temAlerta;
  final List<MensagemRegra> mensagens;
}