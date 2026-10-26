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
}
