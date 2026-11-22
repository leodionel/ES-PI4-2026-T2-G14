import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/app_exception.dart';
import 'criar_transporte.dart';
import 'serializacao_java.dart';
import 'servidor_transporte.dart';

// Responsável pela comunicação com o backend.
//
// O aplicativo não chama a API direto: cada chamada vai ao servidor Java,
// que encaminha a requisição ao Spring Boot e devolve a resposta. No celular
// e no emulador a conversa é por sockets; no navegador (Flutter Web), por
// HTTP na porta 3001 do mesmo servidor. A interface (get, post, put, delete)
// é a mesma de uma API HTTP.
class ApiClient {
  ApiClient({ServidorTransporte? servidor})
    : _servidor = servidor ?? criarTransporte();

  final ServidorTransporte _servidor;

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
    } on ConexaoFalhouException {
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

  // Lê a mensagem de erro enviada pelo servidor (campo "detail" do
  // ProblemDetail). Se não houver, usa o texto padrão.
  String _mensagemDoServidor(RespostaServidor resposta, String padrao) {
    try {
      final json = jsonDecode(utf8.decode(resposta.corpo));

      if (json is Map) {
        final detalhe = json['detail'] ?? json['mensagem'] ?? json['message'];

        if (detalhe is String && detalhe.trim().isNotEmpty) {
          return detalhe.trim();
        }
      }
    } catch (_) {
      // Corpo vazio ou fora do formato esperado.
    }

    return padrao;
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
      throw AppException(
        tipo: TipoErro.validacao,
        mensagem: _mensagemDoServidor(
          resposta,
          'Os dados informados são inválidos.',
        ),
      );
    }

    if (codigo == 409) {
      throw AppException(
        tipo: TipoErro.validacao,
        mensagem: _mensagemDoServidor(
          resposta,
          'Já existe um registro com esses dados.',
        ),
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
