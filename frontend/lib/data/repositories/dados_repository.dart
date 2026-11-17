import '../services/api_client.dart';
import '../services/token_storage.dart';
import '../../core/app_exception.dart';

typedef Registro = Map<String, dynamic>;

class DadosTalhao {
  const DadosTalhao(
    this.talhao,
    this.propriedade,
    this.plantios,
    this.analises,
    this.status,
  );
  final Registro talhao;
  final Registro? propriedade;
  final List<Registro> plantios;
  final List<Registro> analises;
  final Registro status;

  String get nome => talhao['nome'] as String;
  String get id => talhao['id'] as String;
  String get culturaAtual {
    final abertos = plantios.where((p) => p['dataColheita'] == null).toList()
      ..sort((a, b) => '${b['dataPlantio']}'.compareTo('${a['dataPlantio']}'));
    return abertos.isEmpty
        ? 'Sem plantio em aberto'
        : '${abertos.first['culturaNome']}';
  }

  List<Registro> get eventos {
    final lista = <Registro>[];
    for (final p in plantios) {
      lista.add({
        'data': p['dataPlantio'],
        'titulo': 'Plantio de ${p['culturaNome']}',
        'descricao': 'Safra registrada',
        'talhao': nome,
      });
      if (p['dataColheita'] != null) {
        lista.add({
          'data': p['dataColheita'],
          'titulo': 'Colheita de ${p['culturaNome']}',
          'descricao': 'Safra concluída',
          'talhao': nome,
        });
      }
    }
    for (final a in analises) {
      lista.add({
        'data': a['dataColeta'],
        'titulo': 'Análise de solo',
        'descricao': a['observacoes'] ?? '',
        'talhao': nome,
      });
    }
    lista.sort((a, b) => '${b['data'] ?? ''}'.compareTo('${a['data'] ?? ''}'));
    return lista;
  }
}

class PainelDados {
  const PainelDados(this.propriedade, this.talhoes);
  final Registro? propriedade;
  final List<DadosTalhao> talhoes;
  double get area =>
      talhoes.fold(0, (s, t) => s + (t.talhao['areaHa'] as num).toDouble());
  int quantidade(String status) =>
      talhoes.where((t) => t.status['status'] == status).length;
  List<Registro> get eventos =>
      talhoes.expand((t) => t.eventos).toList()
        ..sort((a, b) => '${b['data'] ?? ''}'.compareTo('${a['data'] ?? ''}'));
}

// Toda consulta usa o token da sessão; IDs de usuário nunca são enviados pelo cliente.
class DadosRepository {
  DadosRepository({required ApiClient api, required TokenStorage tokens})
    : _api = api,
      _tokens = tokens;
  final ApiClient _api;
  final TokenStorage _tokens;
  Future<String> _token() async {
    final token = await _tokens.lerToken();
    if (token == null || token.isEmpty) {
      throw const AppException(
        tipo: TipoErro.autenticacao,
        mensagem: 'Sessão expirada. Faça login novamente.',
      );
    }
    return token;
  }

  static Registro registro(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  static List<Registro> registros(dynamic value) =>
      (value as List).map(registro).toList();
  Future<dynamic> buscar(String rota) async =>
      _api.get(rota, token: await _token());
  Future<Registro> salvar(String rota, Registro dados) async =>
      _api.post(rota, dados, token: await _token());
  Future<dynamic> atualizar(String rota, Registro dados) async =>
      _api.put(rota, dados, token: await _token());
  Future<List<Registro>> culturas() async =>
      registros(await buscar('/api/culturas'));
  Future<List<Registro>> talhoes() async =>
      registros(await buscar('/api/talhoes'));
  Future<List<Registro>> propriedades() async =>
      registros(await buscar('/api/propriedades'));

  Future<DadosTalhao> detalhe(String id) async {
    final codigo = Uri.encodeComponent(id);
    final resultados = await Future.wait([
      buscar('/api/talhoes/$codigo'),
      propriedades(),
      buscar('/api/talhoes/$codigo/plantios'),
      buscar('/api/analises-solo'),
      buscar('/api/talhoes/$codigo/status-solo'),
    ]);
    final propriedadesUsuario = resultados[1] as List<Registro>;
    final analises =
        registros(resultados[3]).where((a) => a['talhaoId'] == id).toList()
          ..sort(
            (a, b) => '${b['dataColeta']}'.compareTo('${a['dataColeta']}'),
          );
    return DadosTalhao(
      registro(resultados[0]),
      propriedadesUsuario.firstOrNull,
      registros(resultados[2]),
      analises,
      registro(resultados[4]),
    );
  }

  Future<PainelDados> painel() async {
    final token = await _token();
    final respostas = await Future.wait([
      _api.get('/api/propriedades', token: token),
      _api.get('/api/talhoes', token: token),
      _api.get('/api/analises-solo', token: token),
    ]);
    final props = registros(respostas[0]);
    final lista = registros(respostas[1]);
    final analises = registros(respostas[2]);
    final detalhes = await Future.wait(
      lista.map((t) async {
        final id = t['id'] as String;
        final codigo = Uri.encodeComponent(id);
        final dados = await Future.wait([
          _api.get('/api/talhoes/$codigo/plantios', token: token),
          _api.get('/api/talhoes/$codigo/status-solo', token: token),
        ]);
        final historico = analises.where((a) => a['talhaoId'] == id).toList()
          ..sort(
            (a, b) => '${b['dataColeta']}'.compareTo('${a['dataColeta']}'),
          );
        return DadosTalhao(
          t,
          props.firstOrNull,
          registros(dados[0]),
          historico,
          registro(dados[1]),
        );
      }),
    );
    return PainelDados(props.firstOrNull, detalhes);
  }
}
