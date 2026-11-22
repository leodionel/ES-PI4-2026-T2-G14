// Feito por Leonardo Dionel RA: 25010092

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prontuario_talhao/data/services/servidor_socket.dart';

// Bytes gerados pelo ObjectOutputStream do Java: cabeçalho do fluxo seguido
// de uma RespostaRequisicao com status 200 e corpo {"ok":true}.
const _respostaJava =
    'aced000573720012526573706f7374615265717569736963616f000000000000'
    '00010200034900067374617475735b0005636f72706f7400025b424c000c7469'
    '706f436f6e746575646f7400124c6a6176612f6c616e672f537472696e673b78'
    '72000a436f6d756e696361646f00000000000000010200007870000000c87572'
    '00025b42acf317f8060854e002000078700000000b7b226f6b223a747275657d'
    '7400106170706c69636174696f6e2f6a736f6e79';

Uint8List _hex(String texto) {
  return Uint8List.fromList([
    for (var i = 0; i < texto.length; i += 2)
      int.parse(texto.substring(i, i + 2), radix: 16),
  ]);
}

// Servidor falso que entrega a resposta em pedaços do tamanho [pedaco].
Future<ServerSocket> _servidorFalso(int pedaco) async {
  final servidor = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

  servidor.listen((cliente) async {
    final bytes = _hex(_respostaJava);

    try {
      for (var i = 0; i < bytes.length; i += pedaco) {
        final fim = i + pedaco > bytes.length ? bytes.length : i + pedaco;

        cliente.add(bytes.sublist(i, fim));
        await cliente.flush();

        // Dá tempo de o pedaço chegar separado
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    } on SocketException {
      // O app já leu a resposta inteira e fechou a conexão: é esperado
    } finally {
      cliente.destroy();
    }
  });

  return servidor;
}

void main() {
  // A resposta pode chegar em vários pedaços de TCP: o cabeçalho sozinho,
  // no meio de um campo ou byte a byte. O resultado precisa ser o mesmo.
  for (final pedaco in [1, 4, 7, 50, 1000]) {
    test('lê a resposta entregue em pedaços de $pedaco bytes', () async {
      final servidor = await _servidorFalso(pedaco);
      addTearDown(servidor.close);

      final cliente = ServidorSocket(host: '127.0.0.1', porta: servidor.port);

      final resposta = await cliente.enviar(
        metodo: 'GET',
        caminho: '/api/talhoes',
        token: 'abc',
      );

      expect(resposta.status, 200);
      expect(utf8.decode(resposta.corpo), '{"ok":true}');
    });
  }
}
