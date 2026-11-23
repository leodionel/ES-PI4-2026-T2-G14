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

  // Pede o codigo de recuperacao de senha (RF03).
  // Devolve o codigo simulado quando o backend o exibe, ou null quando nao
  // (RECUPERACAO_EXIBIR_CODIGO=false: o codigo fica so nos logs do backend).
  Future<String?> solicitarRecuperacao(String email);

  // Troca a senha usando o codigo recebido (RF03).
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  });

  //Encerra a sessao
  Future<void> sair();
}
