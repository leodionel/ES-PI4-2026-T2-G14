import '../app_textos.dart';

//Validacooes dos formularios
class Validators {
  static String? email(String? valor) {
    // remove espacos nas pontas do email
    final email = (valor ?? '').trim();

    // confere o formato basico: nome@dominio.com
    final formato = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!formato.hasMatch(email)) {
      return AppTextos.emailInvalido;
    }

    return null;
  }

  static String? senhaLogin(String? valor) {
    //No login, a senha so precisa estar preenchida
    if (valor == null || valor.isEmpty) {
      return AppTextos.senhaObrigatoria;
    }

    return null;
  }

  // Codigo de recuperacao de senha: exatamente 6 digitos.
  static String? codigoRecuperacao(String? valor) {
    final codigo = (valor ?? '').trim();

    if (codigo.isEmpty) {
      return 'Informe o código recebido.';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      return 'O código tem 6 dígitos.';
    }

    return null;
  }

  // Nova senha: mesma regra do cadastro (8 a 128 caracteres).
  static String? novaSenha(String? valor) {
    final senha = valor ?? '';

    if (senha.isEmpty) {
      return 'Informe a nova senha.';
    }

    if (senha.length < 8 || senha.length > 128) {
      return 'A senha deve ter entre 8 e 128 caracteres.';
    }

    return null;
  }
}
