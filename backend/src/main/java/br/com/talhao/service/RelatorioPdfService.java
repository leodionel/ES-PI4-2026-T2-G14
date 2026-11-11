
package br.com.talhao.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Propriedade;

// Gera relatorios PDF das propriedades e analises de solo
@Service
public class RelatorioPdfService {

    private final PropriedadeService propriedadeService;
    private final AnaliseSoloService analiseSoloService;

    private static final PDFont FONTE_NORMAL =
            new PDType1Font(Standard14Fonts.FontName.HELVETICA);

    private static final PDFont FONTE_NEGRITO =
            new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);

    public RelatorioPdfService(
            PropriedadeService propriedadeService,
            AnaliseSoloService analiseSoloService) {

        this.propriedadeService = propriedadeService;
        this.analiseSoloService = analiseSoloService;
    }

    // Gera o PDF para uma propriedade do usuario autenticado
    public byte[] gerarRelatorio(
            String usuarioId,
            String propriedadeId) {

        // Verifica se a propriedade pertence ao usuario
        Propriedade propriedade = propriedadeService.buscarPorId(
                propriedadeId,
                usuarioId
        );

        // Busca somente as analises dessa propriedade e usuario
        List<AnaliseSolo> analises =
                analiseSoloService.listarPorPropriedade(
                        usuarioId,
                        propriedadeId
                );

        try (PDDocument documento = new PDDocument()) {

            EscritorPdf escritor = new EscritorPdf(documento);

            try {
                // Cabecalho do relatorio
                escritor.escrever(
                        "PRONTUARIO DIGITAL DO TALHAO",
                        FONTE_NEGRITO,
                        16
                );

                escritor.escrever(
                        "Relatorio de Analises de Solo",
                        FONTE_NEGRITO,
                        13
                );

                escritor.espaco(12);

                // Informacoes da propriedade
                escritor.escrever(
                        "INFORMACOES DA PROPRIEDADE",
                        FONTE_NEGRITO,
                        12
                );

                escritor.escrever(
                        "Nome: " + propriedade.nome(),
                        FONTE_NORMAL,
                        11
                );

                escritor.escrever(
                        "Localizacao: " + propriedade.localizacao(),
                        FONTE_NORMAL,
                        11
                );

                escritor.escrever(
                        "ID da propriedade: " + propriedade.id(),
                        FONTE_NORMAL,
                        10
                );

                escritor.escrever(
                        "Data do relatorio: " +
                        formatarData(LocalDate.now()),
                        FONTE_NORMAL,
                        10
                );

                escritor.espaco(15);

                // Resultados das analises
                escritor.escrever(
                        "ANALISES DE SOLO",
                        FONTE_NEGRITO,
                        12
                );

                escritor.escrever(
                        "Total de analises: " + analises.size(),
                        FONTE_NORMAL,
                        11
                );

                escritor.espaco(8);

                if (analises.isEmpty()) {

                    escritor.escrever(
                            "Nenhuma analise de solo cadastrada.",
                            FONTE_NORMAL,
                            11
                    );

                } else {

                    for (int i = 0; i < analises.size(); i++) {

                        AnaliseSolo analise = analises.get(i);

                        escritor.escrever(
                                "Analise " + (i + 1),
                                FONTE_NEGRITO,
                                12
                        );

                        escritor.escrever(
                                "Data da coleta: " +
                                formatarData(analise.dataColeta()),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "Talhao (ID): " + analise.talhaoId(),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "pH: " + formatarNumero(analise.ph()),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "Fosforo: " +
                                formatarNumero(analise.fosforo()),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "Potassio: " +
                                formatarNumero(analise.potassio()),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "Materia organica: " +
                                formatarNumero(analise.materiaOrganica()),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.escrever(
                                "Observacoes: " + analise.observacoes(),
                                FONTE_NORMAL,
                                11
                        );

                        escritor.espaco(12);
                    }
                }

                escritor.espaco(12);

                escritor.escrever(
                        "Documento gerado automaticamente pelo sistema PI4.",
                        FONTE_NORMAL,
                        9
                );

            } finally {
                escritor.fechar();
            }

            // Converte o documento em bytes
            ByteArrayOutputStream saida =
                    new ByteArrayOutputStream();

            documento.save(saida);

            return saida.toByteArray();

        } catch (IOException erro) {
            throw new IllegalStateException(
                    "Nao foi possivel gerar o relatorio PDF",
                    erro
            );
        }
    }

    // Formata datas no padrao brasileiro
    private static String formatarData(LocalDate data) {

        if (data == null) {
            return "Nao informada";
        }

        return data.format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy")
        );
    }

    // Formata valores numericos
    private static String formatarNumero(Double numero) {

        if (numero == null) {
            return "Nao informado";
        }

        return String.format(
                Locale.forLanguageTag("pt-BR"),
                "%.2f",
                numero
        );
    }

    // Escreve o conteudo e cria novas paginas quando necessario
    private static class EscritorPdf {

        private static final float MARGEM = 50;
        private static final float LIMITE_INFERIOR = 60;

        private final PDDocument documento;

        private PDPageContentStream conteudo;
        private float posicaoY;

        public EscritorPdf(PDDocument documento)
                throws IOException {

            this.documento = documento;
            novaPagina();
        }

        // Cria uma pagina A4
        private void novaPagina() throws IOException {

            if (conteudo != null) {
                conteudo.close();
            }

            PDPage pagina = new PDPage(PDRectangle.A4);
            documento.addPage(pagina);

            conteudo = new PDPageContentStream(
                    documento,
                    pagina
            );

            posicaoY = pagina.getMediaBox().getHeight() - MARGEM;
        }

        // Adiciona texto ao documento
        public void escrever(
                String texto,
                PDFont fonte,
                float tamanho) throws IOException {

            String valor = texto == null
                    ? "Nao informado"
                    : texto.replaceAll("\\s+", " ").trim();

            if (valor.isEmpty()) {
                valor = "Nao informado";
            }

            // Substitui caracteres nao suportados pela fonte
            StringBuilder seguro = new StringBuilder();

            for (int i = 0; i < valor.length();) {

                int codigo = valor.codePointAt(i);

                String caractere = new String(
                        Character.toChars(codigo)
                );

                try {
                    fonte.getStringWidth(caractere);
                    seguro.append(caractere);
                } catch (IllegalArgumentException erro) {
                    seguro.append("?");
                }

                i += Character.charCount(codigo);
            }

            // Quebra linhas longas para nao ultrapassar a pagina
            float larguraMaxima =
                    PDRectangle.A4.getWidth() - (2 * MARGEM);

            StringBuilder linha = new StringBuilder();

            for (int i = 0; i < seguro.length(); i++) {

                char caractere = seguro.charAt(i);

                String tentativa = linha.toString() + caractere;

                float largura =
                        fonte.getStringWidth(tentativa) / 1000 * tamanho;

                if (largura > larguraMaxima && linha.length() > 0) {

                    imprimirLinha(linha.toString(), fonte, tamanho);
                    linha.setLength(0);
                }

                linha.append(caractere);
            }

            if (linha.length() > 0) {
                imprimirLinha(linha.toString(), fonte, tamanho);
            }

            posicaoY -= 5;
        }

        // Imprime uma linha na posicao atual
        private void imprimirLinha(
                String texto,
                PDFont fonte,
                float tamanho) throws IOException {

            if (posicaoY < LIMITE_INFERIOR) {
                novaPagina();
            }

            conteudo.beginText();
            conteudo.setFont(fonte, tamanho);
            conteudo.newLineAtOffset(MARGEM, posicaoY);
            conteudo.showText(texto);
            conteudo.endText();

            posicaoY -= tamanho + 5;
        }

        // Adiciona espacamento vertical
        public void espaco(float pontos) throws IOException {

            posicaoY -= pontos;

            if (posicaoY < LIMITE_INFERIOR) {
                novaPagina();
            }
        }

        // Finaliza a escrita do PDF
        public void fechar() throws IOException {

            if (conteudo != null) {
                conteudo.close();
                conteudo = null;
            }
        }
    }
}
