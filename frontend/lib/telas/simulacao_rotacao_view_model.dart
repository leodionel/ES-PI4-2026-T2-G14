
import '../core/base_view_model.dart';
import '../data/models/talhao_simulacao.dart';
import '../data/models/cultura_simulacao.dart';

// Responsavel pelo estado da simulacao de rotacao
class SimulacaoRotacaoViewModel extends BaseViewModel {

  // Lista dos talhoes disponiveis
  List<TalhaoSimulacao> _talhoes = [];

  // Lista das culturas disponiveis
  List<CulturaSimulacao> _culturas = [];

  // Identificador do talhao selecionado
  String? _talhaoSelecionadoId;

  // Identificadores das culturas selecionadas
  final Set<String> _culturasSelecionadasIds = {};

  // Quantidade maxima de culturas para comparacao
  static const int maxCulturas = 3;

  // Permite consultar os talhoes sem modificar a lista
  List<TalhaoSimulacao> get talhoes =>
      List.unmodifiable(_talhoes);

  // Permite consultar as culturas disponiveis
  List<CulturaSimulacao> get culturas =>
      List.unmodifiable(_culturas);

  // Retorna o identificador do talhao selecionado
  String? get talhaoSelecionadoId =>
      _talhaoSelecionadoId;

  // Retorna o talhao selecionado
  TalhaoSimulacao? get talhaoSelecionado {

    for (final talhao in _talhoes) {
      if (talhao.id == _talhaoSelecionadoId) {
        return talhao;
      }
    }

    return null;
  }

  // Retorna as culturas selecionadas
  List<CulturaSimulacao> get culturasSelecionadas =>
      List.unmodifiable(
        _culturas.where(
          (cultura) =>
              _culturasSelecionadasIds.contains(cultura.id),
        ),
      );

  // Verifica se uma cultura esta selecionada
  bool culturaEstaSelecionada(String id) {
    return _culturasSelecionadasIds.contains(id);
  }

  // Verifica se atingiu o limite de comparacao
  bool get limiteCulturasAtingido =>
      _culturasSelecionadasIds.length >= maxCulturas;

  // Atualiza a lista de talhoes recebida
  void definirTalhoes(List<TalhaoSimulacao> talhoes) {

    _talhoes = List.of(talhoes);

    // Mantem o talhao atual se ele continuar disponivel
    final selecionadoExiste = _talhoes.any(
      (talhao) => talhao.id == _talhaoSelecionadoId,
    );

    // Caso contrario, seleciona o primeiro disponivel
    if (!selecionadoExiste) {
      _talhaoSelecionadoId = _talhoes.isEmpty
          ? null
          : _talhoes.first.id;
    }

    notifyListeners();
  }

  // Atualiza a lista de culturas disponiveis
  void definirCulturas(List<CulturaSimulacao> culturas) {

    _culturas = List.of(culturas);

    // Remove selecoes que nao existem mais na lista
    final idsDisponiveis = _culturas
        .map((cultura) => cultura.id)
        .toSet();

    _culturasSelecionadasIds.retainAll(idsDisponiveis);

    notifyListeners();
  }

  // Seleciona um talhao pelo identificador
  bool selecionarTalhao(String id) {

    // Impede a selecao de um talhao inexistente
    if (!_talhoes.any((talhao) => talhao.id == id)) {
      return false;
    }

    if (_talhaoSelecionadoId == id) {
      return true;
    }

    _talhaoSelecionadoId = id;

    notifyListeners();

    return true;
  }

  // Adiciona ou remove uma cultura da comparacao
  bool alternarCultura(String id) {

    // Se estiver selecionada, remove
    if (_culturasSelecionadasIds.contains(id)) {

      _culturasSelecionadasIds.remove(id);

      notifyListeners();

      return true;
    }

    // Impede selecionar mais de tres culturas
    if (limiteCulturasAtingido) {
      return false;
    }

    // Impede selecionar culturas inexistentes
    if (!_culturas.any((cultura) => cultura.id == id)) {
      return false;
    }

    // Adiciona a cultura selecionada
    _culturasSelecionadasIds.add(id);

    notifyListeners();

    return true;
  }

  // Limpa as culturas selecionadas
  void limparSelecaoCulturas() {

    if (_culturasSelecionadasIds.isEmpty) {
      return;
    }

    _culturasSelecionadasIds.clear();

    notifyListeners();
  }
}
