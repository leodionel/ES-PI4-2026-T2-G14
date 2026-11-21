import '../../core/app_exception.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

// Propriedade do produtor (uma por conta, RN11).
class PropriedadePerfil {
  const PropriedadePerfil({
    required this.id,
    required this.nome,
    required this.localizacao,
  });

  final String id;
  final String nome;
  final String localizacao;
}

// Dados do produtor e da propriedade (RF05).
class PerfilCompleto {
  const PerfilCompleto({
    required this.nome,
    required this.email,
    required this.telefone,
    this.propriedade,
  });

  final String nome;
  final String email;
  final String telefone;
  final PropriedadePerfil? propriedade;
}

class PerfilRepository {
  PerfilRepository(this._api, this._tokens);

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

  // GET /api/usuarios/me
  Future<PerfilCompleto> buscar() async {
    return _converter(await _api.get('/api/usuarios/me', token: await _token()));
  }

  // PUT /api/usuarios/me: altera nome e telefone. O e-mail não muda.
  Future<PerfilCompleto> atualizarUsuario(String nome, String telefone) async {
    return _converter(
      await _api.put('/api/usuarios/me', {
        'nome': nome,
        'telefone': telefone,
      }, token: await _token()),
    );
  }

  // Cria a propriedade (POST) ou altera a existente (PUT).
  Future<void> salvarPropriedade({
    String? id,
    required String nome,
    required String localizacao,
  }) async {
    final dados = {'nome': nome, 'localizacao': localizacao};
    final token = await _token();

    if (id == null) {
      await _api.post('/api/propriedades', dados, token: token);
    } else {
      await _api.put(
        '/api/propriedades/${Uri.encodeComponent(id)}',
        dados,
        token: token,
      );
    }
  }

  PerfilCompleto _converter(dynamic resposta) {
    if (resposta is! Map) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou um perfil inválido.',
      );
    }

    final usuario = resposta['usuario'] is Map
        ? resposta['usuario'] as Map
        : const {};
    final propriedade = resposta['propriedade'];

    return PerfilCompleto(
      nome: (usuario['nome'] ?? '').toString(),
      email: (usuario['email'] ?? '').toString(),
      telefone: (usuario['telefone'] ?? '').toString(),
      propriedade: propriedade is Map
          ? PropriedadePerfil(
              id: (propriedade['id'] ?? '').toString(),
              nome: (propriedade['nome'] ?? '').toString(),
              localizacao: (propriedade['localizacao'] ?? '').toString(),
            )
          : null,
    );
  }
}
