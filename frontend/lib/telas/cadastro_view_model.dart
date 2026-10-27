import '../core/base_view_model.dart';
import '../data/repositories/auth_repository.dart';

//Controla as acoes da tela de cadastro
class CadastroViewModel extends BaseViewModel {
  CadastroViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> cadastrar(
    String nome,
    String email,
    String telefone,
    String senha,
  ) {
    return executar(() async {
      //Remove a formatacao do telefone antes de enviar
      final telefoneLimpo = telefone.replaceAll(RegExp(r'\D'), '');

      await _authRepository.cadastrar(
        nome.trim(),
        email.trim(),
        telefoneLimpo,
        senha,
      );
    });
  }
}
