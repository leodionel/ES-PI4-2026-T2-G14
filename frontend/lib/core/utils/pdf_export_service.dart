// Contribuição de Matheus Azevedo Teixeira RA: 25014927

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> exportarProntuarioTalhao({
    required Map<String, dynamic> talhao,
    required List<Map<String, dynamic>> analises,
    required List<Map<String, dynamic>> plantios,
  }) async {
    final nome = _texto(talhao['nome'], vazio: 'Talh\u00e3o');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text(
            'Prontu\u00e1rio Digital do Talh\u00e3o',
            style: pw.TextStyle(
              color: PdfColors.green800,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'P\u00e1gina ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Prontu\u00e1rio do Talh\u00e3o',
            style: pw.TextStyle(
              color: PdfColors.green800,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Gerado em ${_data(DateTime.now().toIso8601String())}'),
          pw.SizedBox(height: 24),
          _tituloSecao('Dados do talh\u00e3o'),
          _linha('Nome', nome),
          _linha('Identificador', _texto(talhao['id'])),
          _linha('\u00c1rea', _medida(talhao['areaHa'], 'ha')),
          _linha('Cadastrado em', _data(talhao['criadoEm'])),
          _linha('Plantios registrados', _texto(talhao['totalPlantios'])),
          _linha('An\u00e1lises registradas', _texto(talhao['totalAnalises'])),
          pw.SizedBox(height: 20),
          _tituloSecao('Hist\u00f3rico de plantios'),
          if (plantios.isEmpty)
            pw.Text('Nenhum plantio registrado para este talh\u00e3o.')
          else
            ...plantios.map(_blocoPlantio),
          pw.SizedBox(height: 20),
          _tituloSecao('An\u00e1lises de solo'),
          if (analises.isEmpty)
            pw.Text(
              'Nenhuma an\u00e1lise de solo cadastrada para este talh\u00e3o.',
            )
          else
            ...analises.map(_blocoAnalise),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prontuario_${_nomeArquivo(nome)}.pdf',
    );
  }

  static pw.Widget _tituloSecao(String titulo) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      titulo,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _linha(String rotulo, String valor) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            rotulo,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(child: pw.Text(valor)),
      ],
    ),
  );

  static pw.Widget _blocoPlantio(Map<String, dynamic> plantio) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _texto(plantio['culturaNome'], vazio: 'Cultura nao informada'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        _linha('Plantio em', _data(plantio['dataPlantio'])),
        _linha(
          'Colheita em',
          plantio['dataColheita'] == null
              ? 'Em andamento'
              : _data(plantio['dataColheita']),
        ),
      ],
    ),
  );
  static pw.Widget _blocoAnalise(Map<String, dynamic> analise) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Coleta em ${_data(analise['dataColeta'])}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _linha('pH', _numero(analise['ph'])),
        _linha('F\u00f3sforo', _numero(analise['fosforo'])),
        _linha('Pot\u00e1ssio', _numero(analise['potassio'])),
        _linha(
          'Satura\u00e7\u00e3o por bases',
          _medida(analise['saturacaoBases'], '%'),
        ),
        if (_texto(analise['observacoes'], vazio: '').isNotEmpty)
          _linha('Observa\u00e7\u00f5es', _texto(analise['observacoes'])),
      ],
    ),
  );

  static String _texto(dynamic valor, {String vazio = 'N\u00e3o informado'}) {
    if (valor == null || valor.toString().trim().isEmpty) return vazio;
    return valor.toString();
  }

  static String _numero(dynamic valor) {
    if (valor is num) {
      final numero = valor == valor.truncateToDouble()
          ? valor.toInt().toString()
          : valor.toString();
      return numero.replaceAll('.', ',');
    }
    return _texto(valor);
  }

  static String _medida(dynamic valor, String unidade) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'N\u00e3o informado';
    }
    return '${_numero(valor)} $unidade';
  }

  static String _data(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'N\u00e3o informada';
    }
    final texto = valor.toString();
    final data = DateTime.tryParse(texto);
    if (data == null) return texto;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  static String _nomeArquivo(String nome) {
    final seguro = nome
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return seguro.isEmpty ? 'Talhao' : seguro;
  }
}
