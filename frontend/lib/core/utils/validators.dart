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

  //Nome n pode ficar vazio
  static String? nome(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return AppTextos.nomeObrigatorio;
    }

    return null;
  }

  //Confere a quantidade de digitos do telefone com DDD
  static String? telefone(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');

    if (digitos.length != 10 && digitos.length != 11) {
      return AppTextos.telefoneInvalido;
    }

    return null;
  }

  //Senha minima para criar uma conta
  static String? senhaCadastro(String? valor) {
    if (valor == null || valor.length < 8) {
      return AppTextos.senhaMinima;
    }

    return null;
  }

  //Compara a confirmacao com a senha digitada
  static String? confirmarSenha(String? valor, String senha) {
    if (valor == null || valor.isEmpty) {
      return AppTextos.confirmacaoObrigatoria;
    }
    if (valor != senha) {
      return AppTextos.senhasDiferentes;
    }

    return null;
  }
}
