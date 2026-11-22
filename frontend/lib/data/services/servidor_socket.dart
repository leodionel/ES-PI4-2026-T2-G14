// Feito por Leonardo Dionel RA: 25010092

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'serializacao_java.dart';
import 'servidor_transporte.dart';

// Conexão com o servidor Java de sockets.
//
// Cada chamada abre uma conexão TCP, envia um PedidoRequisicao, aguarda a
// RespostaRequisicao e fecha. Uma conexão por pedido mantém o código simples
// e evita conexões penduradas quando o aplicativo vai para segundo plano.
class ServidorSocket implements ServidorTransporte {
  ServidorSocket({String? host, int? porta})
    : _host =
          host ??
          const String.fromEnvironment(
            'SERVIDOR_HOST',
            // Endereço do computador visto pelo emulador Android.
            defaultValue: '10.0.2.2',
          ),
      _porta =
          porta ??
          const int.fromEnvironment('SERVIDOR_PORTA', defaultValue: 3000);

  final String _host;
  final int _porta;

  static const Duration _tempoConexao = Duration(seconds: 5);

  // Envia a requisição e devolve a resposta do servidor.
  // Lança ConexaoFalhouException, TimeoutException ou
  // FormatoInvalidoException.
  @override
  Future<RespostaServidor> enviar({
    required String metodo,
    required String caminho,
    String token = '',
    Uint8List? corpo,
    Duration tempoLimite = const Duration(seconds: 15),
  }) async {
    final Socket socket;

    try {
      socket = await Socket.connect(_host, _porta, timeout: _tempoConexao);
    } on SocketException {
      throw const ConexaoFalhouException(
        'Não foi possível conectar ao servidor.',
      );
    }

    final trabalho = _trocarMensagens(
      socket,
      SerializacaoJava.codificarPedido(
        metodo: metodo,
        caminho: caminho,
        token: token,
        corpo: corpo,
      ),
    );

    try {
      return await trabalho.timeout(tempoLimite);
    } on SocketException {
      throw const ConexaoFalhouException('O servidor encerrou a conexão.');
    } finally {
      socket.destroy();

      // Se o tempo esgotou, o erro tardio do trabalho não deve escapar.
      unawaited(trabalho.then<void>((_) {}, onError: (_) {}));
    }
  }

  Future<RespostaServidor> _trocarMensagens(
    Socket socket,
    Uint8List pedido,
  ) async {
    // O cliente e o servidor trocam o cabeçalho do fluxo antes dos objetos.
    socket.add(cabecalhoJava);
    socket.add(pedido);
    await socket.flush();

    final recebido = BytesBuilder(copy: false);
    var cabecalhoLido = false;

    await for (final pedaco in socket) {
      recebido.add(pedaco);

      final todos = recebido.toBytes();

      if (todos.length < cabecalhoJava.length) {
        continue;
      }

      // O cabeçalho só precisa ser conferido uma vez, mas precisa ser
      // descartado a cada leitura: a resposta pode chegar em vários pedaços.
      if (!cabecalhoLido) {
        for (var i = 0; i < cabecalhoJava.length; i++) {
          if (todos[i] != cabecalhoJava[i]) {
            throw const FormatoInvalidoException(
              'O servidor não respondeu no formato esperado.',
            );
          }
        }

        cabecalhoLido = true;
      }

      final resposta = SerializacaoJava.lerResposta(
        Uint8List.sublistView(todos, cabecalhoJava.length),
      );

      if (resposta != null) {
        return resposta;
      }
    }

    throw const SocketException('O servidor encerrou a conexão.');
  }
}
