import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Responsável por armazenar o token JWT do usuário.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _chaveToken = 'talhao_token_jwt';

  // Salva o token após o login.
  Future<void> salvarToken(String token) async {
    await _storage.write(key: _chaveToken, value: token);
  }

  // Recupera o token salvo.
  Future<String?> lerToken() async {
    return _storage.read(key: _chaveToken);
  }

  // Remove o token quando o usuário sair.
  Future<void> apagarToken() async {
    await _storage.delete(key: _chaveToken);
  }
}
