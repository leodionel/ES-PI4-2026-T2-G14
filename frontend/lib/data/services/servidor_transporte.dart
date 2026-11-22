import 'dart:typed_data';

import 'serializacao_java.dart';

// A conexão com o servidor falhou antes de haver resposta
// (servidor desligado, rede fora do ar, conexão encerrada).
class ConexaoFalhouException implements Exception {
  const ConexaoFalhouException(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ConexaoFalhouException: $mensagem';
}

// Forma de falar com o servidor Java.
//
// No celular e no emulador o app usa sockets (ServidorSocket). O navegador
// não abre sockets TCP, então no Flutter Web o app usa a porta HTTP do mesmo
// servidor (ServidorHttp). O resto do app não sabe qual dos dois está em uso.
abstract class ServidorTransporte {
  // Envia a requisição e devolve a resposta do servidor.
  // Lança ConexaoFalhouException, TimeoutException ou
  // FormatoInvalidoException.
  Future<RespostaServidor> enviar({
    required String metodo,
    required String caminho,
    String token = '',
    Uint8List? corpo,
    Duration tempoLimite = const Duration(seconds: 15),
  });
}
