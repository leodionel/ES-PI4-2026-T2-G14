import 'package:flutter/foundation.dart';

// Contrato de autenticacao do app
abstract class AuthRepository extends ChangeNotifier {
  //Informa se a sessao salva ainda essta sendo verificaoa
  bool get iniciando;

  // Informa se o usuario esta autenticaod
  bool get autenticado;

  // Verifica se ja existe uma sessao
  Future<void> restaurarSessao();

  //Solicita a autentiucacao com email e senha
  Future<void> entrar(String email, String senha);



  //Encerra a sessao
  Future<void> sair();
}
