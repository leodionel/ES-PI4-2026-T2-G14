// Contribuição de Matheus Azevedo Teixeira RA: 25014927

import '../../core/app_exception.dart';
import 'auth_repository.dart';

/// Permite iniciar a interface enquanto o backend de autenticação não existe.
class AuthRepositoryIndisponivel extends AuthRepository {
  @override
  bool get iniciando => false;

  @override
  bool get autenticado => false;

  @override
  Future<void> restaurarSessao() async {}

  @override
  Future<void> entrar(String email, String senha) async {
    throw const AppException(
      tipo: TipoErro.desconhecido,
      mensagem: 'O login ainda não está conectado ao serviço de autenticação.',
    );
  }

  @override
  Future<String?> solicitarRecuperacao(String email) async {
    throw const AppException(
      tipo: TipoErro.desconhecido,
      mensagem: 'A recuperação de senha ainda não está conectada ao servidor.',
    );
  }

  @override
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    throw const AppException(
      tipo: TipoErro.desconhecido,
      mensagem: 'A recuperação de senha ainda não está conectada ao servidor.',
    );
  }

  @override
  Future<void> sair() async {}
}
