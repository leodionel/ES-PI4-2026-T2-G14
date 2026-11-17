class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
  });
  final String id;
  final String nome;
  final String email;
  final String telefone;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['nome'] is! String ||
        (json['id'] as String).isEmpty) {
      throw const FormatException('Dados do usuário inválidos.');
    }
    return Usuario(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
    );
  }
}
