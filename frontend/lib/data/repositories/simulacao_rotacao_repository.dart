
import '../models/talhao_simulacao.dart';
import '../models/cultura_simulacao.dart';

// Define as operacoes necessarias para obter
// os dados utilizados na simulacao de rotacao.
abstract class SimulacaoRotacaoRepository {

  // Busca os talhoes cadastrados pelo produtor.
  Future<List<TalhaoSimulacao>> buscarTalhoes();

  // Busca as culturas disponiveis para comparacao.
  Future<List<CulturaSimulacao>> buscarCulturas();
}
