
package br.com.talhao.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Talhao;

// Gera prontuarios dos talhoes e relatorios de analises das propriedades
@Service
public class RelatorioPdfService {

    private final PropriedadeService propriedadeService;
    private final AnaliseSoloService analiseSoloService;
    private final TalhaoService talhaoService;
    private final CulturaService culturaService;

    private static final PDFont FONTE_NORMAL =
            new PDType1Font(Standard14Fonts.FontName.HELVETICA);

    private static final PDFont FONTE_NEGRITO =
            new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);

    public RelatorioPdfService(
            PropriedadeService propriedadeService,
            AnaliseSoloService analiseSoloService,
            TalhaoService talhaoService,
            CulturaService culturaService) {

        this.propriedadeService = propriedadeService;
        this.analiseSoloService = analiseSoloService;
        this.talhaoService = talhaoService;
        this.culturaService = culturaService;
    }

    // Autoriza o talhao antes de consultar o historico ou gerar o documento.
    public byte[] gerarProntuarioTalhao(String usuarioId, String talhaoId) {
        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);
        Propriedade propriedade = propriedadeService.buscarPorId(talhao.propriedadeId(), usuarioId);
        List<AnaliseSolo> analises = analiseSoloService
                .listarPorTalhao(usuarioId, propriedade.id(), talhao.id())
                .stream()
                .sorted(Comparator.comparing(AnaliseSolo::dataColeta,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
        List<Plantio> plantios = talhao.plantios().stream()
                .sorted(Comparator.comparing(Plantio::dataPlantio,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
        Map<String, String> culturas = plantios.isEmpty() ? Map.of() : culturaService.listar()
                .stream()
                .collect(Collectors.toMap(Cultura::id, Cultura::nome));

        try (PDDocument documento = new PDDocument()) {
            try (EscritorPdf escritor = new EscritorPdf(documento)) {
                escritor.escrever("PRONTUÁRIO DIGITAL DO TALHÃO", FONTE_NEGRITO, 16);
                escritor.escrever("Histórico de culturas, safras e análises de solo", FONTE_NORMAL, 11);
                escritor.escrever("Data do relatório: " + formatarData(LocalDate.now()), FONTE_NORMAL, 10);
                escritor.espaco(12);

                escritor.escrever("IDENTIFICAÇÃO", FONTE_NEGRITO, 12);
                escritor.escrever("Propriedade: " + textoOuNaoInformado(propriedade.nome()), FONTE_NORMAL, 11);
                escritor.escrever("Localização: " + textoOuNaoInformado(propriedade.localizacao()), FONTE_NORMAL, 11);
                escritor.escrever("Talhão: " + textoOuNaoInformado(talhao.nome()), FONTE_NEGRITO, 12);
                escritor.escrever("ID do talhão: " + talhao.id(), FONTE_NORMAL, 10);
                escritor.escrever("Área: " + formatarNumero(talhao.areaHa()) + " ha", FONTE_NORMAL, 11);
                escritor.espaco(12);

                escritor.reservarEspaco(plantios.isEmpty() ? 95 : 175);
                escritor.escrever("CULTURAS E SAFRAS", FONTE_NEGRITO, 12);
                escritor.escrever("Total de safras: " + plantios.size(), FONTE_NORMAL, 11);
                if (plantios.isEmpty()) {
                    escritor.escrever("Nenhuma safra cadastrada.", FONTE_NORMAL, 11);
                }
                for (int i = 0; i < plantios.size(); i++) {
                    Plantio plantio = plantios.get(i);
                    escritor.reservarEspaco(125);
                    escritor.escrever("Safra " + (i + 1), FONTE_NEGRITO, 12);
                    escritor.escrever("Cultura: " + textoOuNaoInformado(
                            culturas.getOrDefault(plantio.culturaId(), plantio.culturaId())), FONTE_NORMAL, 11);
                    escritor.escrever("ID do plantio: " + textoOuNaoInformado(plantio.plantioId()), FONTE_NORMAL, 10);
                    escritor.escrever("Data do plantio: " + formatarData(plantio.dataPlantio()), FONTE_NORMAL, 11);
                    escritor.escrever("Colheita: " + (plantio.dataColheita() == null
                            ? "Em aberto" : formatarData(plantio.dataColheita())), FONTE_NORMAL, 11);
                    escritor.espaco(8);
                }

                escritor.espaco(12);
                escritor.reservarEspaco(analises.isEmpty() ? 95 : 240);
                escritor.escrever("ANÁLISES DE SOLO", FONTE_NEGRITO, 12);
                escritor.escrever("Total de análises: " + analises.size(), FONTE_NORMAL, 11);
                if (analises.isEmpty()) {
                    escritor.escrever("Nenhuma análise de solo cadastrada.", FONTE_NORMAL, 11);
                }
                for (int i = 0; i < analises.size(); i++) {
                    AnaliseSolo analise = analises.get(i);
                    escritor.reservarEspaco(190);
                    escritor.escrever("Análise " + (i + 1), FONTE_NEGRITO, 12);
                    escritor.escrever("Data da coleta: " + formatarData(analise.dataColeta()), FONTE_NORMAL, 11);
                    escritor.escrever("pH (CaCl2): " + formatarNumero(analise.ph()), FONTE_NORMAL, 11);
                    escritor.escrever("Fósforo (P resina, mg/dm³): " + formatarNumero(analise.fosforo()), FONTE_NORMAL, 11);
                    escritor.escrever("Potássio (mmolc/dm³): " + formatarNumero(analise.potassio()), FONTE_NORMAL, 11);
                    escritor.escrever("Saturação por bases (V%): " + formatarNumero(analise.saturacaoBases()), FONTE_NORMAL, 11);
                    escritor.escrever("Observações: " + textoOuNaoInformado(analise.observacoes()), FONTE_NORMAL, 11);
                    escritor.espaco(8);
                }

                escritor.espaco(12);
                escritor.escrever("Documento gerado automaticamente pelo sistema PI4.", FONTE_NORMAL, 9);
            }
            ByteArrayOutputStream saida = new ByteArrayOutputStream();
            documento.save(saida);
            return saida.toByteArray();
        } catch (IOException erro) {
            throw new IllegalStateException("Nao foi possivel gerar o prontuario PDF", erro);
        }
    }

    private static String textoOuNaoInformado(String texto) {
        return texto == null || texto.isBlank() ? "Não informado" : texto;
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
                                "Saturacao por bases (V%): " +
                                formatarNumero(analise.saturacaoBases()),
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
    private static class EscritorPdf implements AutoCloseable {

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

            for (String palavra : seguro.toString().split(" ")) {
                String tentativa = linha.length() == 0 ? palavra : linha + " " + palavra;
                if (fonte.getStringWidth(tentativa) / 1000 * tamanho <= larguraMaxima) {
                    linha.setLength(0);
                    linha.append(tentativa);
                    continue;
                }
                if (linha.length() > 0) {
                    imprimirLinha(linha.toString(), fonte, tamanho);
                    linha.setLength(0);
                }
                // Divide apenas palavras ou identificadores maiores que uma linha inteira.
                for (int i = 0; i < palavra.length(); i++) {
                    char caractere = palavra.charAt(i);
                    if (fonte.getStringWidth(linha.toString() + caractere) / 1000 * tamanho > larguraMaxima
                            && linha.length() > 0) {
                        imprimirLinha(linha.toString(), fonte, tamanho);
                        linha.setLength(0);
                    }
                    linha.append(caractere);
                }
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

        // Evita deixar o titulo de um registro isolado no fim da pagina.
        public void reservarEspaco(float pontos) throws IOException {
            if (posicaoY - pontos < LIMITE_INFERIOR) {
                novaPagina();
            }
        }

        @Override
        public void close() throws IOException {
            fechar();
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
