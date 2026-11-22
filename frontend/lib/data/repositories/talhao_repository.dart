import '../../core/app_exception.dart';
import '../../domain/models/talhao_resumo.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

// Acesso aos talhoes.
// As regras agronomicas sao calculadas no backend.
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

  // Lista os talhoes em uma unica requisicao (RF07).
  // Status, motivos e cultura atual vem do backend.
  Future<List<TalhaoResumo>> listar() async {
    final token = await _token();

    final resposta = await _api.get('/api/talhoes', token: token);

    if (resposta is! List) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou uma lista de talhões inválida.',
      );
    }

    return resposta.map<TalhaoResumo>((item) {
      if (item is! Map) {
        throw const AppException(
          tipo: TipoErro.servidor,
          mensagem: 'Os dados de um talhão são inválidos.',
        );
      }

      final talhao = Map<String, dynamic>.from(item);

      // Exige o contrato atualizado da API.
      if (talhao['statusSolo'] == null) {
        throw const AppException(
          tipo: TipoErro.servidor,
          mensagem: 'O servidor não retornou o status do talhão.',
        );
      }

      final cultura = talhao['culturaAtual'];

      final String? nomeCultura = cultura is Map
          ? cultura['nome']?.toString()
          : null;

      final motivosRecebidos = talhao['motivos'];

      final List<String> motivos = motivosRecebidos is List
          ? motivosRecebidos.map((motivo) => motivo.toString()).toList()
          : <String>[];

      return TalhaoResumo(
        id: talhao['id'].toString(),
        nome: (talhao['nome'] ?? '').toString(),
        areaHa: (talhao['areaHa'] as num?)?.toDouble() ?? 0,
        totalPlantios: (talhao['totalPlantios'] as num?)?.toInt() ?? 0,
        totalAnalises: (talhao['totalAnalises'] as num?)?.toInt() ?? 0,
        status: StatusSolo.doServidor(talhao['statusSolo']),
        motivos: motivos,
        dataAnalise: DateTime.tryParse(
          (talhao['dataAnalise'] ?? '').toString(),
        ),
        culturaAtual: nomeCultura == null || nomeCultura.trim().isEmpty
            ? null
            : nomeCultura,
      );
    }).toList();
  }

  // Cria um talhao na propriedade do usuario.
  Future<void> criar(String nome, double areaHa) async {
    await _api.post('/api/talhoes', {
      'nome': nome,
      'areaHa': areaHa,
    }, token: await _token());
  }

  // Altera nome e area (RF06).
  Future<void> atualizar(String id, String nome, double areaHa) async {
    await _api.put('/api/talhoes/$id', {
      'nome': nome,
      'areaHa': areaHa,
    }, token: await _token());
  }

  // Exclui o talhao com confirmacao do nome (RF09).
  Future<void> excluir(String id, String confirmacaoNome) async {
    await _api.delete(
      '/api/talhoes/$id',
      dados: {'confirmacaoNome': confirmacaoNome},
      token: await _token(),
    );
  }

  // Verifica se o usuario tem propriedade (RN11).
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

  // Carrega dados do prontuario para exportacao PDF (RF22).
  Future<
    ({
      Map<String, dynamic> talhao,
      List<Map<String, dynamic>> analises,
      List<Map<String, dynamic>> plantios,
    })
  >
  carregarProntuario(String id) async {
    final token = await _token();
    final codigo = Uri.encodeComponent(id);

    final talhao = await _api.get('/api/talhoes/$codigo', token: token);

    final plantios = await _api.get(
      '/api/talhoes/$codigo/plantios',
      token: token,
    );

    final analises = await _api.get('/api/analises-solo', token: token);

    List<Map<String, dynamic>> comoLista(dynamic valor) {
      return valor is List
          ? valor.map((item) => Map<String, dynamic>.from(item as Map)).toList()
          : <Map<String, dynamic>>[];
    }

    return (
      talhao: talhao is Map
          ? Map<String, dynamic>.from(talhao)
          : <String, dynamic>{},
      plantios: comoLista(plantios),
      analises: comoLista(
        analises,
      ).where((a) => a['talhaoId']?.toString() == id).toList(),
    );
  }

  List<Map<String, dynamic>> _lista(dynamic valor) {
    return valor is List
        ? valor.map((item) => Map<String, dynamic>.from(item as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  // Safras do talhao, da mais recente para a antiga (RF13).
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

  // Registra o plantio de uma cultura (RF10).
  Future<void> registrarPlantio(
    String talhaoId,
    String culturaId,
    String dataPlantio,
  ) async {
    await _api.post('/api/talhoes/${Uri.encodeComponent(talhaoId)}/plantios', {
      'culturaId': culturaId,
      'dataPlantio': dataPlantio,
    }, token: await _token());
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

  // Analises do solo do talhao, da mais recente para a antiga.
  Future<List<Map<String, dynamic>>> analises(String talhaoId) async {
    final resposta = await _api.get(
      '/api/analises-solo',
      token: await _token(),
    );

    return _lista(
      resposta,
    ).where((a) => a['talhaoId']?.toString() == talhaoId).toList()..sort(
      (a, b) => (b['dataColeta'] ?? '').toString().compareTo(
        (a['dataColeta'] ?? '').toString(),
      ),
    );
  }

  // Registra uma analise de solo (RF12).
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

  // Busca os dados detalhados do talhao.
  Future<Map<String, dynamic>> detalhe(String id) async {
    final resposta = await _api.get(
      '/api/talhoes/${Uri.encodeComponent(id)}',
      token: await _token(),
    );

    return resposta is Map
        ? Map<String, dynamic>.from(resposta)
        : <String, dynamic>{};
  }

  // Busca os detalhes do status do solo (RN02).
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
