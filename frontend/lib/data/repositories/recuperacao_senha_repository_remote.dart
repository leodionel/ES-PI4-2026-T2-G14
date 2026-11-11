import '../services/api_client.dart';

// Responsável por solicitar a recuperação de senha
// através do backend Java.
class RecuperacaoSenhaRepositoryRemote {
  RecuperacaoSenhaRepositoryRemote({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // Solicita a recuperação da senha.
  Future<void> solicitarRecuperacao(String email) async {
    await _apiClient.post('/api/usuarios/recuperacao-senha', {
      'email': email.trim().toLowerCase(),
    });
  }
}
