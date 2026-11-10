import 'cenario_resultado.dart';

// Resultado completo da comparacao de culturas.
class ResultadoSimulacao {
  const ResultadoSimulacao({
    required this.cenarios,
    required this.equivalentes,
  });

  final List<CenarioResultado> cenarios;
  final bool equivalentes;
}