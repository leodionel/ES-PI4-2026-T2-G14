// Tipos de erro que o app pode receber
enum TipoErro { rede, autenticacao, validacao, servidor, desconhecido }

// Guarda o tipo do erro e a mensagem para o usuário
class AppException implements Exception {
  const AppException({required this.tipo, required this.mensagem});

  final TipoErro tipo;
  final String mensagem;

  @override
  String toString() => mensagem;
}
