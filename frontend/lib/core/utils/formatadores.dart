// Datas e números no padrão brasileiro.
class Formatadores {
  // 2026-11-20 -> 20/11/2026
  static String data(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // Lê a data enviada pelo servidor (yyyy-MM-dd) e formata; vazio se inválida.
  static String dataDoServidor(Object? valor) {
    final lida = DateTime.tryParse((valor ?? '').toString());

    return lida == null ? '' : data(lida);
  }

  // Data no formato aceito pelo servidor (yyyy-MM-dd).
  static String dataParaServidor(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '${data.year}-$mes-$dia';
  }

  // Aceita vírgula ou ponto como separador decimal.
  static double? numero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  // 12.5 -> 12,5
  static String decimal(double valor, {int casas = 1}) =>
      valor.toStringAsFixed(casas).replaceAll('.', ',');
}
