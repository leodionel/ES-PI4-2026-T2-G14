// Status do solo de um talhão (RN02). Quem calcula é o backend.
enum StatusSolo {
  semAnalise('Sem análise'),
  saudavel('Saudável'),
  atencao('Atenção'),
  risco('Risco');

  const StatusSolo(this.rotulo);

  final String rotulo;

  // Converte o texto enviado pelo servidor (SEM_ANALISE, SAUDAVEL...).
  static StatusSolo doServidor(Object? valor) {
    switch ((valor ?? '').toString().toUpperCase()) {
      case 'SAUDAVEL':
        return StatusSolo.saudavel;
      case 'ATENCAO':
        return StatusSolo.atencao;
      case 'RISCO':
        return StatusSolo.risco;
      default:
        return StatusSolo.semAnalise;
    }
  }
}

// Dados de um talhão prontos para as listas e para o dashboard.
class TalhaoResumo {
  const TalhaoResumo({
    required this.id,
    required this.nome,
    required this.areaHa,
    required this.totalPlantios,
    required this.totalAnalises,
    required this.status,
    required this.motivos,
    this.dataAnalise,
    this.culturaAtual,
  });

  final String id;
  final String nome;
  final double areaHa;
  final int totalPlantios;
  final int totalAnalises;
  final StatusSolo status;

  // Parâmetros que motivaram o status, como "pH (acidez alta)".
  final List<String> motivos;
  final DateTime? dataAnalise;

  // Cultura plantada e ainda não colhida; nula quando não há.
  final String? culturaAtual;
}
