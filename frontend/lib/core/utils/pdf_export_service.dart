import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/repositories/dados_repository.dart';
import '../widgets/pagina_dados.dart';

class PdfExportService {
  static Future<Uint8List> gerar(DadosTalhao dados) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        maxPages: 20 + dados.plantios.length + dados.analises.length * 2,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) =>
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}'),
        build: (_) => [
          pw.Header(level: 0, text: 'Prontuário Digital do Talhão'),
          pw.Text(
            'Propriedade: ${dados.propriedade?['nome'] ?? 'Não informada'}',
          ),
          pw.Text(
            'Localização: ${dados.propriedade?['localizacao'] ?? 'Não informada'}',
          ),
          pw.Header(level: 1, text: dados.nome),
          pw.Text('Área: ${numeroDado(dados.talhao['areaHa'])} ha'),
          pw.Text('Cultura atual: ${dados.culturaAtual}'),
          pw.Text('Status do solo: ${statusDado(dados.status['status'])}'),
          for (final motivo in dados.status['motivos'] as List? ?? [])
            pw.Text('$motivo'),
          pw.Header(level: 1, text: 'Culturas e safras'),
          if (dados.plantios.isEmpty) pw.Text('Nenhuma safra cadastrada.'),
          for (final p in dados.plantios)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                '${p['culturaNome']} | Plantio: ${dataDado(p['dataPlantio'])} | Colheita: ${p['dataColheita'] == null ? 'Em aberto' : dataDado(p['dataColheita'])}',
              ),
            ),
          pw.Header(level: 1, text: 'Análises de solo'),
          if (dados.analises.isEmpty) pw.Text('Nenhuma análise cadastrada.'),
          for (final a in dados.analises.reversed)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Coleta: ${dataDado(a['dataColeta'])}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'pH (CaCl2): ${numeroDado(a['ph'])} | P resina: ${numeroDado(a['fosforo'])} mg/dm³',
                  ),
                  pw.Text(
                    'K: ${numeroDado(a['potassio'])} mmolc/dm³ | V: ${numeroDado(a['saturacaoBases'])}%',
                  ),
                  pw.Text(
                    'Observações: ${a['observacoes'] ?? 'Não informadas'}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<void> exportarProntuarioTalhao(DadosTalhao dados) async {
    final bytes = await gerar(dados);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Prontuario_${dados.id}.pdf',
    );
  }
}
