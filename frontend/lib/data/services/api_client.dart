import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_exception.dart';

// Responsável pela comunicação HTTP com o backend Java.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_URL',
                    defaultValue: 'http://localhost:8081',
                  ))
              .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const Duration _tempoLimite = Duration(seconds: 15);

  // Monta o endereço completo da API.
  Uri _criarUri(String caminho) {
    final rota = caminho.startsWith('/') ? caminho : '/$caminho';

    return Uri.parse('$_baseUrl$rota');
  }

  // Monta os cabeçalhos da requisição.
  Map<String, String> _cabecalhos(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Envia requisições POST para o backend.
  Future<Map<String, dynamic>> post(
    String caminho,
    Map<String, dynamic> dados, {
    String? token,
  }) async {
    try {
      final resposta = await _client
          .post(
            _criarUri(caminho),
            headers: _cabecalhos(token),
            body: jsonEncode(dados),
          )
          .timeout(_tempoLimite);

      final resultado = _processarResposta(resposta);

      if (resultado is Map<String, dynamic>) {
        return resultado;
      }

      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'Resposta inesperada do servidor.',
      );
    } on TimeoutException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem:
            'O servidor demorou para responder. '
            'Tente novamente.',
      );
    } on http.ClientException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem:
            'Não foi possível conectar ao servidor. '
            'Verifique sua conexão.',
      );
    }
  }

  // Busca dados do backend.
  Future<dynamic> get(String caminho, {String? token}) async {
    try {
      final resposta = await _client
          .get(_criarUri(caminho), headers: _cabecalhos(token))
          .timeout(_tempoLimite);

      return _processarResposta(resposta);
    } on TimeoutException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem: 'O servidor demorou para responder.',
      );
    } on http.ClientException {
      throw const AppException(
        tipo: TipoErro.rede,
        mensagem: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  // Analisa o status HTTP e o JSON recebido.
  dynamic _processarResposta(http.Response resposta) {
    final codigo = resposta.statusCode;

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

    if (resposta.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw const AppException(
        tipo: TipoErro.servidor,
        mensagem: 'O servidor retornou uma resposta inválida.',
      );
    }
  }

  // Libera os recursos HTTP.
  void fechar() {
    _client.close();
  }
}
