// Feito por Leonardo Dionel RA:25010092

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prontuario_talhao/data/services/serializacao_java.dart';

// Os bytes abaixo foram gerados pelo ObjectOutputStream do Java, com as
// classes PedidoRequisicao e RespostaRequisicao do servidor.
Uint8List _hex(String texto) {
  final limpo = texto.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var i = 0; i < limpo.length; i += 2)
      int.parse(limpo.substring(i, i + 2), radix: 16),
  ]);
}

// Remove o cabeçalho do fluxo (AC ED 00 05).
Uint8List _semCabecalho(Uint8List dados) =>
    Uint8List.sublistView(dados, cabecalhoJava.length);

const _pedidoGet =
    'aced00057372001050656469646f5265717569736963616f0000000000000001'
    '0200044c000763616d696e686f7400124c6a6176612f6c616e672f537472696e'
    '673b5b0005636f72706f7400025b424c00066d65746f646f71007e00014c0005'
    '746f6b656e71007e00017872000a436f6d756e696361646f0000000000000001'
    '020000787074000c2f6170692f74616c686f6573757200025b42acf317f80608'
    '54e002000078700000000074000347455474000361626379';

const _pedidoPost =
    'aced00057372001050656469646f5265717569736963616f0000000000000001'
    '0200044c000763616d696e686f7400124c6a6176612f6c616e672f537472696e'
    '673b5b0005636f72706f7400025b424c00066d65746f646f71007e00014c0005'
    '746f6b656e71007e00017872000a436f6d756e696361646f0000000000000001'
    '02000078707400132f6170692f7573756172696f732f6c6f67696e757200025b'
    '42acf317f8060854e002000078700000000a7b2261223a22c3a7227d74000450'
    '4f535474000079';

const _respostas =
    'aced000573720012526573706f7374615265717569736963616f000000000000'
    '00010200034900067374617475735b0005636f72706f7400025b424c000c7469'
    '706f436f6e746575646f7400124c6a6176612f6c616e672f537472696e673b78'
    '72000a436f6d756e696361646f00000000000000010200007870000000c87572'
    '00025b42acf317f8060854e002000078700000000b7b226f6b223a747275657d'
    '7400106170706c69636174696f6e2f6a736f6e7973720012526573706f737461'
    '5265717569736963616f00000000000000010200034900067374617475735b00'
    '05636f72706f7400025b424c000c7469706f436f6e746575646f7400124c6a61'
    '76612f6c616e672f537472696e673b7872000a436f6d756e696361646f000000'
    '0000000001020000787000000191757200025b42acf317f8060854e002000078'
    '70000000007400106170706c69636174696f6e2f6a736f6e79';

void main() {
  group('leitura de objetos gerados pelo Java', () {
    test('pedido GET sem corpo', () {
      final leitura = SerializacaoJava.lerObjeto(
        _semCabecalho(_hex(_pedidoGet)),
      )!;

      expect(leitura.campos['metodo'], 'GET');
      expect(leitura.campos['caminho'], '/api/talhoes');
      expect(leitura.campos['token'], 'abc');
      expect((leitura.campos['corpo'] as Uint8List), isEmpty);
    });

    test('pedido POST com corpo em UTF-8', () {
      final leitura = SerializacaoJava.lerObjeto(
        _semCabecalho(_hex(_pedidoPost)),
      )!;
      final corpo = leitura.campos['corpo'] as Uint8List;

      expect(leitura.campos['metodo'], 'POST');
      expect(utf8.decode(corpo), '{"a":"ç"}');
    });

    test('resposta 200 com JSON', () {
      final resposta = SerializacaoJava.lerResposta(
        _semCabecalho(_hex(_respostas)),
      )!;

      expect(resposta.status, 200);
      expect(resposta.tipoConteudo, 'application/json');
      expect(utf8.decode(resposta.corpo), '{"ok":true}');
    });

    test('mensagem incompleta devolve null em qualquer prefixo', () {
      final dados = _semCabecalho(_hex(_pedidoPost));
      final completo = SerializacaoJava.lerObjeto(dados)!;

      for (var n = 0; n < completo.consumidos; n++) {
        expect(
          SerializacaoJava.lerObjeto(Uint8List.sublistView(dados, 0, n)),
          isNull,
          reason: 'prefixo de $n bytes',
        );
      }
    });

    test('fluxo com lixo lança FormatoInvalidoException', () {
      expect(
        () => SerializacaoJava.lerObjeto(Uint8List.fromList([0x01, 0x02])),
        throwsA(isA<FormatoInvalidoException>()),
      );
    });
  });

  group('escrita do pedido', () {
    test('o que o app escreve é lido de volta igual', () {
      final corpo = Uint8List.fromList(utf8.encode('{"nome":"São José"}'));
      final bytes = SerializacaoJava.codificarPedido(
        metodo: 'POST',
        caminho: '/api/talhoes?x=1',
        token: 'token.jwt.aqui',
        corpo: corpo,
      );
      final leitura = SerializacaoJava.lerObjeto(bytes)!;

      expect(leitura.consumidos, bytes.length);
      expect(leitura.campos['metodo'], 'POST');
      expect(leitura.campos['caminho'], '/api/talhoes?x=1');
      expect(leitura.campos['token'], 'token.jwt.aqui');
      expect(leitura.campos['corpo'], corpo);
    });

    test('começa com TC_RESET e TC_OBJECT', () {
      final bytes = SerializacaoJava.codificarPedido(
        metodo: 'GET',
        caminho: '/status',
      );

      expect(bytes[0], 0x79);
      expect(bytes[1], 0x73);
    });
  });
}
