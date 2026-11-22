import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'serializacao_java.dart';
import 'servidor_transporte.dart';

// Conexão usada pelo Flutter Web: HTTP na porta do servidor Java (3001).
// O servidor valida o pedido e repassa ao Spring Boot, como faz com os sockets.
class ServidorHttp implements ServidorTransporte {
  ServidorHttp({String? enderecoBase, http.Client? cliente})
    : _base = _semBarraFinal(
        enderecoBase ??
            const String.fromEnvironment(
              'SERVIDOR_HTTP',
              defaultValue: 'http://localhost:3001',
            ),
      ),
      _cliente = cliente ?? http.Client();

  final String _base;
  final http.Client _cliente;

  static String _semBarraFinal(String endereco) {
    return endereco.endsWith('/')
        ? endereco.substring(0, endereco.length - 1)
        : endereco;
  }

  @override
  Future<RespostaServidor> enviar({
    required String metodo,
    required String caminho,
    String token = '',
    Uint8List? corpo,
    Duration tempoLimite = const Duration(seconds: 15),
  }) async {
    final pedido = http.Request(metodo, Uri.parse('$_base$caminho'));

    pedido.headers['Accept'] = 'application/json';

    if (token.isNotEmpty) {
      pedido.headers['Authorization'] = 'Bearer $token';
    }

    if (corpo != null && corpo.isNotEmpty) {
      pedido.headers['Content-Type'] = 'application/json';
      pedido.bodyBytes = corpo;
    }

    try {
      final resposta = await _cliente.send(pedido).timeout(tempoLimite);
      final bytes = await resposta.stream.toBytes().timeout(tempoLimite);

      return RespostaServidor(
        status: resposta.statusCode,
        tipoConteudo: resposta.headers['content-type'] ?? 'application/json',
        corpo: bytes,
      );
    } on http.ClientException {
      // Servidor desligado ou página sem permissão (CORS)
      throw const ConexaoFalhouException(
        'Não foi possível conectar ao servidor.',
      );
    }
  }
}
