import '../../core/app_exception.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'auth_repository.dart';

// Implementação real da autenticação.
// Utiliza a API Java e armazena o token JWT.
class AuthRepositoryRemote extends AuthRepository {
  AuthRepositoryRemote({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  bool _iniciando = false;
  bool _autenticado = false;

  @override
  bool get iniciando => _iniciando;

  @override
  bool get autenticado => _autenticado;

  // Verifica se existe uma sessão salva e válida.
  @override
  Future<void> restaurarSessao() async {
    _iniciando = true;
    notifyListeners();

    try {
      final token = await _tokenStorage.lerToken();

      if (token == null || token.isEmpty) {
        _autenticado = false;
        return;
      }

      try {
        // Confirma a validade do token no backend.
        await _apiClient.get('/api/talhoes', token: token);

        _autenticado = true;
      } on AppException catch (erro) {
        _autenticado = false;

        // Apaga somente tokens rejeitados pela API.
        if (erro.tipo == TipoErro.autenticacao) {
          await _tokenStorage.apagarToken();
        }
      }
    } catch (_) {
      _autenticado = false;
    } finally {
      _iniciando = false;
      notifyListeners();
    }
  }

  // Realiza o login com dados reais.
  @override
  Future<void> entrar(String email, String senha) async {
    final resposta = await _apiClient.post('/api/usuarios/login', {
      'email': email.trim(),
      'senha': senha,
    });

    // Recupera o JWT retornado pelo Spring Boot.
    final token = resposta['token'];

    if (token is! String || token.trim().isEmpty) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor não retornou um token válido.',
      );
    }

    // Armazena a sessão do usuário.
    try {
      await _tokenStorage.salvarToken(token);
    } catch (_) {
      throw const AppException(
        tipo: TipoErro.desconhecido,
        mensagem:
            'Não foi possível salvar a sessão. '
            'Tente novamente.',
      );
    }

    // Atualiza o estado de autenticação.
    _autenticado = true;
    _iniciando = false;

    notifyListeners();
  }

  // Encerra a sessão e remove o JWT.
  @override
  Future<void> sair() async {
    try {
      await _tokenStorage.apagarToken();
    } finally {
      _autenticado = false;
      notifyListeners();
    }
  }
}
