import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> exportarProntuarioTalhao() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Prontuário Digital do Talhão', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              pw.SizedBox(height: 8),
              pw.Text('Fazenda Santa Clara', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 24),
              
              pw.Text('Talhão 04 - Soja', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Área: 42,8 hectares'),
              pw.Text('Status: Saudável'),
              pw.SizedBox(height: 24),

              pw.Text('Análise de Solo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('pH do solo: 6,2 (Ideal)'),
              pw.Text('Matéria orgânica: 3,1% (Adequado)'),
              pw.Text('Nitrogênio: Baixo (Atenção na próxima safra)'),
              pw.SizedBox(height: 24),

              pw.Text('Histórico Cronológico', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Bullet(text: '12 JAN 2026 - Praga identificada: Percevejo-marrom (Nível 1,8 insetos/m)'),
              pw.SizedBox(height: 8),
              pw.Bullet(text: '15 NOV 2025 - Plantio de Soja (Cultivar BMX Zeus IPRO)'),
              pw.SizedBox(height: 8),
              pw.Bullet(text: '28 OUT 2025 - Colheita de Milho'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prontuario_Talhao_04.pdf',
    );
  }
}