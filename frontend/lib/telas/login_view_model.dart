import '../core/base_view_model.dart';
import '../data/repositories/auth_repository.dart';

//Controla as acoes da tela de login
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> entrar(String email, String senha) {
    // O controle de carregamento e erro vem da BaseViewModel
    return executar(() async {
      await _authRepository.entrar(email.trim(), senha);
    });
  }
}
