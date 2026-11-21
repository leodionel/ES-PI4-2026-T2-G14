import '../../core/app_exception.dart';
import '../../domain/models/cenario_resultado.dart';
import '../../domain/models/classificacao.dart';
import '../../domain/models/mensagem_regra.dart';
import '../../domain/models/resultado_simulacao.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

// Cultura do catálogo oficial, usada para escolher os cenários.
class CulturaOpcao {
  const CulturaOpcao({required this.id, required this.nome});

  final String id;
  final String nome;
}

// Simulação de rotação. O app só envia as culturas e mostra o resultado: a
// classificação e as justificativas vêm do motor de regras do backend.
class SimulacaoRepository {
  SimulacaoRepository(this._api, this._tokens);

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

  // Catálogo de culturas (GET /api/culturas).
  Future<List<CulturaOpcao>> culturas() async {
    final resposta = await _api.get('/api/culturas', token: await _token());

    if (resposta is! List) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou um catálogo de culturas inválido.',
      );
    }

    return resposta
        .whereType<Map>()
        .map(
          (c) => CulturaOpcao(
            id: (c['id'] ?? '').toString(),
            nome: (c['nome'] ?? '').toString(),
          ),
        )
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  // Compara de 2 a 3 culturas para o talhão (RN01).
  Future<ResultadoSimulacao> simular(
    String talhaoId,
    List<String> culturaIds,
  ) async {
    final resposta = await _api.post(
      '/api/talhoes/${Uri.encodeComponent(talhaoId)}/simulacoes',
      {'culturaIds': culturaIds},
      token: await _token(),
    );

    final cenarios = ((resposta['cenarios'] as List?) ?? const [])
        .whereType<Map>()
        .map(_cenario)
        .toList();

    return ResultadoSimulacao(
      cenarios: cenarios,
      equivalentes: resposta['opcoesEquivalentes'] == true,
    );
  }

  CenarioResultado _cenario(Map<dynamic, dynamic> json) {
    final regras = ((json['regras'] as List?) ?? const [])
        .whereType<Map>()
        .toList();

    return CenarioResultado(
      cultura: (json['culturaNome'] ?? '').toString(),
      classificacao: _classificacao(json['classificacao']),
      temAlerta: regras.any(
        (r) => (r['efeito'] ?? '').toString().toUpperCase() == 'ALERTA',
      ),
      mensagens: regras.map(_mensagem).toList(),
    );
  }

  MensagemRegra _mensagem(Map<dynamic, dynamic> regra) {
    final fontes = ((regra['fontes'] as List?) ?? const [])
        .whereType<Map>()
        .map((f) => (f['titulo'] ?? '').toString())
        .where((titulo) => titulo.isNotEmpty)
        .toList();

    return MensagemRegra(
      texto: (regra['mensagem'] ?? '').toString(),
      fonte: fontes.join(' · '),
    );
  }

  Classificacao _classificacao(Object? valor) {
    switch ((valor ?? '').toString().toUpperCase()) {
      case 'RECOMENDADO':
        return Classificacao.recomendado;
      case 'ACEITAVEL':
        return Classificacao.aceitavel;
      default:
        return Classificacao.naoRecomendado;
    }
  }
}
