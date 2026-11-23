// Feito por Leonardo Dionel RA:25010092

import 'dart:convert';
import 'dart:typed_data';

// Serialização Java (ObjectOutputStream/ObjectInputStream) mínima.
//
// O servidor de sockets usa objetos Java serializados. Este arquivo escreve
// e lê apenas as duas mensagens do protocolo do aplicativo:
//
//   PedidoRequisicao  (aplicativo -> servidor)
//     String caminho, byte[] corpo, String metodo, String token
//
//   RespostaRequisicao  (servidor -> aplicativo)
//     int status, byte[] corpo, String tipoConteudo
//
// Ambas estendem a classe base Comunicado (sem campos).

const int _tcNull = 0x70;
const int _tcReference = 0x71;
const int _tcClassDesc = 0x72;
const int _tcObject = 0x73;
const int _tcString = 0x74;
const int _tcArray = 0x75;
const int _tcEndBlockData = 0x78;
const int _tcReset = 0x79;
const int _tcLongString = 0x7C;

const int _scSerializable = 0x02;
const int _handleInicial = 0x7E0000;

// Cabeçalho que inicia todo fluxo de objetos Java.
final Uint8List cabecalhoJava = Uint8List.fromList([0xAC, 0xED, 0x00, 0x05]);

// serialVersionUID do tipo byte[] (fixo na plataforma Java).
const List<int> _suidByteArray = [
  0xAC,
  0xF3,
  0x17,
  0xF8,
  0x06,
  0x08,
  0x54,
  0xE0,
];

// serialVersionUID = 1L das classes Comunicado e PedidoRequisicao.
const List<int> _suidUm = [0, 0, 0, 0, 0, 0, 0, 1];

const String _tipoString = 'Ljava/lang/String;';

// Resposta do servidor ao pedido.
class RespostaServidor {
  const RespostaServidor({
    required this.status,
    required this.tipoConteudo,
    required this.corpo,
  });

  final int status;
  final String tipoConteudo;
  final Uint8List corpo;
}

// Resultado de uma leitura: a mensagem e quantos bytes ela ocupou.
class LeituraObjeto {
  const LeituraObjeto(this.campos, this.consumidos);

  final Map<String, Object?> campos;
  final int consumidos;
}

// Dados que não seguem a serialização esperada.
class FormatoInvalidoException implements Exception {
  const FormatoInvalidoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

// Faltam bytes: a mensagem ainda não chegou por completo.
class _DadosIncompletos implements Exception {
  const _DadosIncompletos();
}

class SerializacaoJava {
  const SerializacaoJava._();

  // Monta o PedidoRequisicao. Começa com TC_RESET, que faz o servidor
  // descartar o estado do fluxo anterior (permite várias mensagens na
  // mesma conexão sem acumular memória).
  static Uint8List codificarPedido({
    required String metodo,
    required String caminho,
    String token = '',
    Uint8List? corpo,
  }) {
    final saida = BytesBuilder(copy: false);

    saida.addByte(_tcReset);
    saida.addByte(_tcObject);

    // Descritor da classe, com os campos na ordem canônica do Java:
    // objetos em ordem alfabética (caminho, corpo, metodo, token).
    saida.addByte(_tcClassDesc);
    _utf(saida, 'PedidoRequisicao');
    saida.add(_suidUm);
    saida.addByte(_scSerializable);
    _u16(saida, 4);

    _campo(saida, 'L', 'caminho', _tipoString);
    _campo(saida, '[', 'corpo', '[B');
    _campo(saida, 'L', 'metodo', _tipoString);
    _campo(saida, 'L', 'token', _tipoString);

    saida.addByte(_tcEndBlockData);

    // Superclasse Comunicado: sem campos e sem outra superclasse.
    saida.addByte(_tcClassDesc);
    _utf(saida, 'Comunicado');
    saida.add(_suidUm);
    saida.addByte(_scSerializable);
    _u16(saida, 0);
    saida.addByte(_tcEndBlockData);
    saida.addByte(_tcNull);

    // Valores, na mesma ordem dos campos.
    _string(saida, caminho);
    _byteArray(saida, corpo ?? Uint8List(0));
    _string(saida, metodo);
    _string(saida, token);

    return saida.toBytes();
  }

  // Lê a próxima mensagem de [bytes] (sem o cabeçalho do fluxo).
  // Devolve null se a mensagem ainda estiver incompleta.
  static RespostaServidor? lerResposta(Uint8List bytes) {
    final leitura = lerObjeto(bytes);

    if (leitura == null) {
      return null;
    }

    final campos = leitura.campos;
    final status = campos['status'];
    final tipo = campos['tipoConteudo'];
    final corpo = campos['corpo'];

    if (status is! int) {
      throw const FormatoInvalidoException('Resposta sem código de status.');
    }

    return RespostaServidor(
      status: status,
      tipoConteudo: tipo is String ? tipo : '',
      corpo: corpo is Uint8List ? corpo : Uint8List(0),
    );
  }

  // Lê o próximo objeto: devolve seus campos e o total de bytes usados,
  // ou null se faltarem bytes.
  static LeituraObjeto? lerObjeto(Uint8List bytes) {
    final leitor = _Leitor(bytes);

    try {
      int tc = leitor.u8();

      // O servidor envia TC_RESET entre as mensagens.
      while (tc == _tcReset) {
        leitor.handles.clear();
        tc = leitor.u8();
      }

      if (tc != _tcObject) {
        throw FormatoInvalidoException(
          'Mensagem inesperada (código 0x${tc.toRadixString(16)}).',
        );
      }

      final campos = leitor.objeto();

      return LeituraObjeto(campos, leitor.posicao);
    } on _DadosIncompletos {
      return null;
    }
  }

  // ---------------- escrita ----------------

  static void _u16(BytesBuilder saida, int valor) {
    saida.addByte((valor >> 8) & 0xFF);
    saida.addByte(valor & 0xFF);
  }

  static void _i32(BytesBuilder saida, int valor) {
    saida.addByte((valor >> 24) & 0xFF);
    saida.addByte((valor >> 16) & 0xFF);
    saida.addByte((valor >> 8) & 0xFF);
    saida.addByte(valor & 0xFF);
  }

  // Texto curto em ASCII (nomes, método, caminho e token).
  static void _utf(BytesBuilder saida, String texto) {
    final dados = ascii.encode(texto);

    if (dados.length > 0xFFFF) {
      throw const FormatoInvalidoException('Texto grande demais.');
    }

    _u16(saida, dados.length);
    saida.add(dados);
  }

  static void _string(BytesBuilder saida, String texto) {
    saida.addByte(_tcString);
    _utf(saida, texto);
  }

  static void _campo(
    BytesBuilder saida,
    String codigo,
    String nome,
    String tipo,
  ) {
    saida.addByte(codigo.codeUnitAt(0));
    _utf(saida, nome);
    _string(saida, tipo);
  }

  static void _byteArray(BytesBuilder saida, Uint8List dados) {
    saida.addByte(_tcArray);
    saida.addByte(_tcClassDesc);
    _utf(saida, '[B');
    saida.add(_suidByteArray);
    saida.addByte(_scSerializable);
    _u16(saida, 0);
    saida.addByte(_tcEndBlockData);
    saida.addByte(_tcNull);
    _i32(saida, dados.length);
    saida.add(dados);
  }
}

// ---------------- leitura ----------------

class _Descritor {
  _Descritor(this.nome);

  final String nome;
  final List<(int, String)> campos = [];
  _Descritor? superclasse;
}

class _Leitor {
  _Leitor(this._bytes);

  final Uint8List _bytes;
  int posicao = 0;

  // Objetos já lidos, na ordem em que o Java os numera (para TC_REFERENCE).
  final List<Object?> handles = [];

  void _precisa(int n) {
    if (posicao + n > _bytes.length) {
      throw const _DadosIncompletos();
    }
  }

  int u8() {
    _precisa(1);
    return _bytes[posicao++];
  }

  int _u16() {
    _precisa(2);
    final valor = (_bytes[posicao] << 8) | _bytes[posicao + 1];
    posicao += 2;
    return valor;
  }

  int _i32() {
    _precisa(4);
    final valor = ByteData.sublistView(
      _bytes,
      posicao,
      posicao + 4,
    ).getInt32(0, Endian.big);
    posicao += 4;
    return valor;
  }

  // Lê um tamanho de 64 bits (TC_LONGSTRING). Os 4 primeiros bytes
  // precisam ser zero: textos acima de 2 GB não existem aqui.
  int _tamanho64() {
    final alto = _i32();
    final baixo = _i32();

    if (alto != 0 || baixo < 0) {
      throw const FormatoInvalidoException('Tamanho de texto inválido.');
    }

    return baixo;
  }

  Uint8List _copiar(int n) {
    _precisa(n);
    final dados = Uint8List.fromList(
      Uint8List.sublistView(_bytes, posicao, posicao + n),
    );
    posicao += n;
    return dados;
  }

  String _utf() {
    final n = _u16();
    return utf8.decode(_copiar(n), allowMalformed: true);
  }

  _Descritor? _classDesc() {
    final tc = u8();

    if (tc == _tcNull) {
      return null;
    }

    if (tc == _tcReference) {
      final alvo = _referencia();

      if (alvo is! _Descritor) {
        throw const FormatoInvalidoException('Referência inválida.');
      }

      return alvo;
    }

    if (tc != _tcClassDesc) {
      throw FormatoInvalidoException(
        'Descritor inesperado (código 0x${tc.toRadixString(16)}).',
      );
    }

    final descritor = _Descritor(_utf());
    _copiar(8); // serialVersionUID
    handles.add(descritor);

    final flags = u8();

    // Só aceita classes Serializable simples (sem writeObject próprio,
    // Externalizable, enum ou proxy).
    if ((flags & _scSerializable) == 0 || (flags & ~_scSerializable) != 0) {
      throw FormatoInvalidoException(
        'Classe não suportada (flags 0x${flags.toRadixString(16)}).',
      );
    }

    final quantidade = _u16();

    for (var i = 0; i < quantidade; i++) {
      final codigo = u8();
      final nome = _utf();

      // Campos de objeto trazem o tipo como texto (ou referência a ele).
      if (codigo == 0x4C || codigo == 0x5B) {
        valor();
      }

      descritor.campos.add((codigo, nome));
    }

    if (u8() != _tcEndBlockData) {
      throw const FormatoInvalidoException('Dados extras na classe.');
    }

    descritor.superclasse = _classDesc();

    return descritor;
  }

  Object? _referencia() {
    final indice = _i32() - _handleInicial;

    if (indice < 0 || indice >= handles.length) {
      throw const FormatoInvalidoException('Referência fora do fluxo.');
    }

    return handles[indice];
  }

  // Lê um valor de campo de objeto: null, texto, byte[] ou outro objeto.
  Object? valor() {
    final tc = u8();

    switch (tc) {
      case _tcNull:
        return null;

      case _tcReference:
        return _referencia();

      case _tcString:
        final texto = _utf();
        handles.add(texto);
        return texto;

      case _tcLongString:
        final textoLongo = utf8.decode(
          _copiar(_tamanho64()),
          allowMalformed: true,
        );
        handles.add(textoLongo);
        return textoLongo;

      case _tcArray:
        final descritor = _classDesc();

        if (descritor == null || descritor.nome != '[B') {
          throw const FormatoInvalidoException('Array não suportado.');
        }

        final tamanho = _i32();

        if (tamanho < 0) {
          throw const FormatoInvalidoException('Tamanho de array inválido.');
        }

        final dados = _copiar(tamanho);
        handles.add(dados);
        return dados;

      case _tcObject:
        return objeto();

      default:
        throw FormatoInvalidoException(
          'Valor inesperado (código 0x${tc.toRadixString(16)}).',
        );
    }
  }

  // Lê um objeto (o byte TC_OBJECT já foi consumido).
  Map<String, Object?> objeto() {
    final descritor = _classDesc();

    if (descritor == null) {
      throw const FormatoInvalidoException('Objeto sem classe.');
    }

    final campos = <String, Object?>{};
    handles.add(campos);

    // Os campos da superclasse vêm primeiro.
    final cadeia = <_Descritor>[];

    for (_Descritor? d = descritor; d != null; d = d.superclasse) {
      cadeia.insert(0, d);
    }

    for (final d in cadeia) {
      for (final (codigo, nome) in d.campos) {
        switch (codigo) {
          case 0x49: // I (int)
            campos[nome] = _i32();
          case 0x5A: // Z (boolean)
            campos[nome] = u8() != 0;
          case 0x4C: // L (objeto)
          case 0x5B: // [ (array)
            campos[nome] = valor();
          default:
            throw FormatoInvalidoException(
              'Campo não suportado (${String.fromCharCode(codigo)}).',
            );
        }
      }
    }

    return campos;
  }
}
