import '../../core/app_exception.dart';
import '../../domain/models/talhao_resumo.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

// Acesso aos talhões. Toda regra (status do solo, contagens) vem do backend.
class TalhaoRepository {
  TalhaoRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<String> _token() async {
    final token = await _tokens.lerToken();

    if (token == null || token.isEmpty) {
      throw const AppException(
        tipo: TipoErro.autenticacao,
        mensagem: 'Sua sessão terminou. Entre novamente.',
      );
    }

    return token;
  }

  // Lista os talhões com status do solo e cultura atual (RF07).
  Future<List<TalhaoResumo>> listar() async {
    final token = await _token();
    final resposta = await _api.get('/api/talhoes', token: token);

    if (resposta is! List) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou uma lista de talhões inválida.',
      );
    }

    final itens = resposta
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Future.wait(itens.map((item) => _resumir(item, token)));
  }

  Future<TalhaoResumo> _resumir(Map<String, dynamic> talhao, String token) async {
    final id = talhao['id'].toString();

    final respostas = await Future.wait<dynamic>([
      _api.get('/api/talhoes/$id/status-solo', token: token),
      _api.get('/api/talhoes/$id/plantios', token: token),
    ]);

    final status = respostas[0] is Map
        ? Map<String, dynamic>.from(respostas[0] as Map)
        : <String, dynamic>{};
    final plantios = respostas[1] is List
        ? (respostas[1] as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList()
        : <Map<String, dynamic>>[];

    return TalhaoResumo(
      id: id,
      nome: (talhao['nome'] ?? '').toString(),
      areaHa: (talhao['areaHa'] as num?)?.toDouble() ?? 0,
      totalPlantios: (talhao['totalPlantios'] as num?)?.toInt() ?? 0,
      totalAnalises: (talhao['totalAnalises'] as num?)?.toInt() ?? 0,
      status: StatusSolo.doServidor(status['status']),
      motivos: ((status['motivos'] as List?) ?? const [])
          .map((m) => m.toString())
          .toList(),
      dataAnalise: DateTime.tryParse((status['dataAnalise'] ?? '').toString()),
      culturaAtual: _culturaAtual(plantios),
    );
  }

  // A cultura atual é o plantio mais recente que ainda não foi colhido.
  String? _culturaAtual(List<Map<String, dynamic>> plantios) {
    final emAndamento = plantios.where((p) => p['dataColheita'] == null).toList()
      ..sort(
        (a, b) => (b['dataPlantio'] ?? '').toString().compareTo(
          (a['dataPlantio'] ?? '').toString(),
        ),
      );

    if (emAndamento.isEmpty) return null;

    return emAndamento.first['culturaNome']?.toString();
  }

  // Cria um talhão na propriedade do usuário.
  Future<void> criar(String nome, double areaHa) async {
    await _api.post('/api/talhoes', {
      'nome': nome,
      'areaHa': areaHa,
    }, token: await _token());
  }

  // Altera nome e área (RF06).
  Future<void> atualizar(String id, String nome, double areaHa) async {
    await _api.put('/api/talhoes/$id', {
      'nome': nome,
      'areaHa': areaHa,
    }, token: await _token());
  }

  // Exclui o talhão. O servidor repete a validação do nome (RF09).
  Future<void> excluir(String id, String confirmacaoNome) async {
    await _api.delete(
      '/api/talhoes/$id',
      dados: {'confirmacaoNome': confirmacaoNome},
      token: await _token(),
    );
  }

  // Indica se o usuário já tem propriedade cadastrada (RN11).
  Future<bool> temPropriedade() async {
    final resposta = await _api.get('/api/propriedades', token: await _token());

    return resposta is List && resposta.isNotEmpty;
  }

  // Cadastra a propriedade do produtor.
  Future<void> criarPropriedade(String nome, String localizacao) async {
    await _api.post('/api/propriedades', {
      'nome': nome,
      'localizacao': localizacao,
    }, token: await _token());
  }

  // Reúne os dados do prontuário de um talhão para exportar em PDF (RF22).
  Future<({
    Map<String, dynamic> talhao,
    List<Map<String, dynamic>> analises,
    List<Map<String, dynamic>> plantios,
  })>
  carregarProntuario(String id) async {
    final token = await _token();
    final codigo = Uri.encodeComponent(id);

    final talhao = await _api.get('/api/talhoes/$codigo', token: token);
    final plantios = await _api.get('/api/talhoes/$codigo/plantios', token: token);
    final analises = await _api.get('/api/analises-solo', token: token);

    List<Map<String, dynamic>> comoLista(dynamic valor) => valor is List
        ? valor.map((item) => Map<String, dynamic>.from(item as Map)).toList()
        : <Map<String, dynamic>>[];

    return (
      talhao: talhao is Map
          ? Map<String, dynamic>.from(talhao)
          : <String, dynamic>{},
      plantios: comoLista(plantios),
      // A API devolve as análises do usuário; filtra as deste talhão.
      analises: comoLista(
        analises,
      ).where((a) => a['talhaoId']?.toString() == id).toList(),
    );
  }

  List<Map<String, dynamic>> _lista(dynamic valor) => valor is List
      ? valor.map((item) => Map<String, dynamic>.from(item as Map)).toList()
      : <Map<String, dynamic>>[];

  // Safras do talhão (RF13), da mais recente para a mais antiga.
  Future<List<Map<String, dynamic>>> plantios(String talhaoId) async {
    final resposta = await _api.get(
      '/api/talhoes/${Uri.encodeComponent(talhaoId)}/plantios',
      token: await _token(),
    );

    return _lista(resposta)..sort(
      (a, b) => (b['dataPlantio'] ?? '').toString().compareTo(
        (a['dataPlantio'] ?? '').toString(),
      ),
    );
  }

  // Registra a cultura plantada (RF10).
  Future<void> registrarPlantio(
    String talhaoId,
    String culturaId,
    String dataPlantio,
  ) async {
    await _api.post(
      '/api/talhoes/${Uri.encodeComponent(talhaoId)}/plantios',
      {'culturaId': culturaId, 'dataPlantio': dataPlantio},
      token: await _token(),
    );
  }

  // Registra a colheita de uma safra (RF11).
  Future<void> registrarColheita(
    String talhaoId,
    String plantioId,
    String dataColheita,
  ) async {
    await _api.put(
      '/api/talhoes/${Uri.encodeComponent(talhaoId)}/plantios/'
      '${Uri.encodeComponent(plantioId)}/colheita',
      {'dataColheita': dataColheita},
      token: await _token(),
    );
  }

  // Análises de solo do talhão, da mais recente para a mais antiga (RF13).
  Future<List<Map<String, dynamic>>> analises(String talhaoId) async {
    final resposta = await _api.get('/api/analises-solo', token: await _token());

    return _lista(resposta)
        .where((a) => a['talhaoId']?.toString() == talhaoId)
        .toList()
      ..sort(
        (a, b) => (b['dataColeta'] ?? '').toString().compareTo(
          (a['dataColeta'] ?? '').toString(),
        ),
      );
  }

  // Registra uma análise de solo (RF12). Todos os campos são obrigatórios.
  Future<void> registrarAnalise({
    required String propriedadeId,
    required String talhaoId,
    required String dataColeta,
    required double ph,
    required double fosforo,
    required double potassio,
    required double saturacaoBases,
  }) async {
    await _api.post('/api/analises-solo', {
      'propriedadeId': propriedadeId,
      'talhaoId': talhaoId,
      'dataColeta': dataColeta,
      'ph': ph,
      'fosforo': fosforo,
      'potassio': potassio,
      'saturacaoBases': saturacaoBases,
    }, token: await _token());
  }

  // Dados do talhão (GET /api/talhoes/{id}).
  Future<Map<String, dynamic>> detalhe(String id) async {
    final resposta = await _api.get(
      '/api/talhoes/${Uri.encodeComponent(id)}',
      token: await _token(),
    );

    return resposta is Map
        ? Map<String, dynamic>.from(resposta)
        : <String, dynamic>{};
  }

  // Status do solo calculado pelo servidor (RN02).
  Future<Map<String, dynamic>> statusSolo(String id) async {
    final resposta = await _api.get(
      '/api/talhoes/${Uri.encodeComponent(id)}/status-solo',
      token: await _token(),
    );

    return resposta is Map
        ? Map<String, dynamic>.from(resposta)
        : <String, dynamic>{};
  }
}
