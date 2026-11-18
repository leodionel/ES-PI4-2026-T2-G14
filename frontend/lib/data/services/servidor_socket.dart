import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'serializacao_java.dart';

// Conexão com o servidor Java de sockets.
//
// Cada chamada abre uma conexão TCP, envia um PedidoRequisicao, aguarda a
// RespostaRequisicao e fecha. Uma conexão por pedido mantém o código simples
// e evita conexões penduradas quando o aplicativo vai para segundo plano.
class ServidorSocket {
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
  // Lança SocketException, TimeoutException ou FormatoInvalidoException.
  Future<RespostaServidor> enviar({
    required String metodo,
    required String caminho,
    String token = '',
    Uint8List? corpo,
    Duration tempoLimite = const Duration(seconds: 15),
  }) async {
    final socket = await Socket.connect(_host, _porta, timeout: _tempoConexao);

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

      var dados = recebido.toBytes();

      if (!cabecalhoLido) {
        if (dados.length < cabecalhoJava.length) {
          continue;
        }

        for (var i = 0; i < cabecalhoJava.length; i++) {
          if (dados[i] != cabecalhoJava[i]) {
            throw const FormatoInvalidoException(
              'O servidor não respondeu no formato esperado.',
            );
          }
        }

        cabecalhoLido = true;
        dados = Uint8List.sublistView(dados, cabecalhoJava.length);
      }

      final resposta = SerializacaoJava.lerResposta(dados);

      if (resposta != null) {
        return resposta;
      }
    }

    throw const SocketException('O servidor encerrou a conexão.');
  }
}
