import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/app_exception.dart';
import 'serializacao_java.dart';
import 'servidor_socket.dart';

// Responsável pela comunicação com o backend.
//
// O aplicativo não fala HTTP com a API: cada chamada vai por sockets ao
// servidor Java, que encaminha a requisição ao Spring Boot e devolve a
// resposta. A interface (get, post, put, delete) é a mesma de uma API HTTP.
class ApiClient {
  ApiClient({ServidorSocket? servidor})
    : _servidor = servidor ?? ServidorSocket();

  final ServidorSocket _servidor;

  // Busca dados do backend.
  Future<dynamic> get(String caminho, {String? token}) {
    return _chamar('GET', caminho, token: token);
  }

  // Cria um registro.
  Future<Map<String, dynamic>> post(
    String caminho,
    Map<String, dynamic> dados, {
    String? token,
  }) async {
    final resultado = await _chamar(
      'POST',
      caminho,
      dados: dados,
      token: token,
    );

    return _comoMapa(resultado);
  }

  // Altera um registro.
  Future<Map<String, dynamic>> put(
    String caminho,
    Map<String, dynamic> dados, {
    String? token,
  }) async {
    final resultado = await _chamar('PUT', caminho, dados: dados, token: token);

    return _comoMapa(resultado);
  }

  // Exclui um registro. Alguns endpoints exigem confirmação no corpo.
  Future<void> delete(
    String caminho, {
    Map<String, dynamic>? dados,
    String? token,
  }) async {
    await _chamar('DELETE', caminho, dados: dados, token: token);
  }

  Map<String, dynamic> _comoMapa(dynamic resultado) {
    if (resultado is Map<String, dynamic>) {
      return resultado;
    }

    throw const AppException(
      tipo: TipoErro.servidor,
      mensagem: 'Resposta inesperada do servidor.',
    );
  }

  Future<dynamic> _chamar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? dados,
    String? token,
  }) async {
    try {
      final resposta = await _servidor.enviar(
        metodo: metodo,
        caminho: caminho.startsWith('/') ? caminho : '/$caminho',
        token: token ?? '',
        corpo: dados == null
            ? null
            : Uint8List.fromList(utf8.encode(jsonEncode(dados))),
      );

      return _processarResposta(resposta);
    } on TimeoutException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem: 'O servidor demorou para responder. Tente novamente.',
      );
    } on SocketException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem:
            'Não foi possível conectar ao servidor. '
            'Verifique sua conexão.',
      );
    } on FormatoInvalidoException {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou uma resposta inválida.',
      );
    }
  }

  // Analisa o status HTTP e o JSON recebido.
  dynamic _processarResposta(RespostaServidor resposta) {
    final codigo = resposta.status;

    if (codigo == 401) {
      throw const AppException(
        tipo: TipoErro.autenticacao,
        mensagem: 'Credenciais inválidas ou sessão expirada.',
      );
    }

    if (codigo == 400 || codigo == 422) {
      throw const AppException(
        tipo: TipoErro.validacao,
        mensagem: 'Os dados informados são inválidos.',
      );
    }

    if (codigo == 409) {
      throw const AppException(
        tipo: TipoErro.validacao,
        mensagem: 'Já existe um registro com esses dados.',
      );
    }

    if (codigo < 200 || codigo >= 300) {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'Não foi possível concluir a solicitação.',
      );
    }

    if (resposta.corpo.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(utf8.decode(resposta.corpo));
    } on FormatException {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou uma resposta inválida.',
      );
    }
  }

  // Mantido para compatibilidade: não há conexão aberta para liberar.
  void fechar() {}
}
