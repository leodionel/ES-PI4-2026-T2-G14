
import '../core/base_view_model.dart';
import '../data/models/talhao_simulacao.dart';
import '../data/models/cultura_simulacao.dart';
import '../data/repositories/simulacao_rotacao_repository.dart';

// Responsavel pelo estado e pelas acoes da simulacao
class SimulacaoRotacaoViewModel extends BaseViewModel {

  // Repository responsavel por fornecer os dados
  final SimulacaoRotacaoRepository _repository;

  // Recebe o Repository pelo construtor
  SimulacaoRotacaoViewModel(this._repository);

  // Lista dos talhoes disponiveis
  List<TalhaoSimulacao> _talhoes = [];

  // Lista das culturas disponiveis
  List<CulturaSimulacao> _culturas = [];

  // Identificador do talhao selecionado
  String? _talhaoSelecionadoId;

  // Identificadores das culturas selecionadas
  final Set<String> _culturasSelecionadasIds = {};

  // Limite de culturas para comparacao
  static const int maxCulturas = 3;

  // Retorna os talhoes sem permitir alterar a lista
  List<TalhaoSimulacao> get talhoes =>
      List.unmodifiable(_talhoes);

  // Retorna as culturas disponiveis
  List<CulturaSimulacao> get culturas =>
      List.unmodifiable(_culturas);

  // Retorna o ID do talhao selecionado
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

  // Verifica se atingiu o limite de culturas
  bool get limiteCulturasAtingido =>
      _culturasSelecionadasIds.length >= maxCulturas;

  // Solicita ao Repository os dados da simulacao
  Future<void> carregarDados() {

    // Centraliza os estados de carregamento e erro
    // utilizando o BaseViewModel do projeto
    return executar(() async {

      // Busca os talhoes cadastrados
      final talhoes = await _repository.buscarTalhoes();

      // Busca as culturas disponiveis
      final culturas = await _repository.buscarCulturas();

      // Atualiza os dados do ViewModel
      definirTalhoes(talhoes);
      definirCulturas(culturas);
    });
  }

  // Atualiza a lista de talhoes
  void definirTalhoes(List<TalhaoSimulacao> talhoes) {

    _talhoes = List.of(talhoes);

    // Verifica se o talhao selecionado ainda existe
    final selecionadoExiste = _talhoes.any(
      (talhao) => talhao.id == _talhaoSelecionadoId,
    );

    // Seleciona o primeiro talhao disponivel
    if (!selecionadoExiste) {
      _talhaoSelecionadoId = _talhoes.isEmpty
          ? null
          : _talhoes.first.id;
    }

    notifyListeners();
  }

  // Atualiza a lista de culturas
  void definirCulturas(List<CulturaSimulacao> culturas) {

    _culturas = List.of(culturas);

    // Identifica as culturas disponiveis
    final idsDisponiveis = _culturas
        .map((cultura) => cultura.id)
        .toSet();

    // Remove selecoes que nao existem mais
    _culturasSelecionadasIds.retainAll(idsDisponiveis);

    notifyListeners();
  }

  // Seleciona um talhao pelo identificador
  bool selecionarTalhao(String id) {

    // Verifica se o talhao existe
    if (!_talhoes.any((talhao) => talhao.id == id)) {
      return false;
    }

    // Evita atualizar quando ja estiver selecionado
    if (_talhaoSelecionadoId == id) {
      return true;
    }

    _talhaoSelecionadoId = id;

    notifyListeners();

    return true;
  }

  // Adiciona ou remove uma cultura da comparacao
  bool alternarCultura(String id) {

    // Remove a cultura quando ja estiver selecionada
    if (_culturasSelecionadasIds.contains(id)) {

      _culturasSelecionadasIds.remove(id);

      notifyListeners();

      return true;
    }

    // Impede ultrapassar o limite de tres culturas
    if (limiteCulturasAtingido) {
      return false;
    }

    // Impede selecionar culturas inexistentes
    if (!_culturas.any((cultura) => cultura.id == id)) {
      return false;
    }

    // Adiciona a cultura
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
