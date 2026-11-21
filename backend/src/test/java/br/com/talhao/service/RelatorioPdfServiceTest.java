
package br.com.talhao.service;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.IntStream;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Propriedade;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testes automatizados do servico de geracao de PDF
@ExtendWith(MockitoExtension.class)
class RelatorioPdfServiceTest {

    // Simula a consulta de propriedades
    @Mock
    private PropriedadeService propriedadeService;

    // Simula a consulta de analises de solo
    @Mock
    private AnaliseSoloService analiseSoloService;

    // Servico real que sera testado
    @InjectMocks
    private RelatorioPdfService relatorioPdfService;

    // Cria uma propriedade ficticia
    private Propriedade criarPropriedade() {

        return new Propriedade(
                "prop-1",
                "usuario-1",
                "Fazenda Teste PI4",
                "Campinas - SP"
        );
    }

    // Cria uma analise de solo ficticia
    private AnaliseSolo criarAnalise(int numero) {

        return new AnaliseSolo(
                "analise-" + numero,
                "usuario-1",
                "prop-1",
                "talhao-1",
                LocalDate.of(2026, 10, 20),
                5.8,
                12.0,
                4.0,
                60.0,
                "Observacoes da analise " + numero
        );
    }

    // Configura os dados simulados da propriedade
    private void configurarPropriedade() {

        when(propriedadeService.buscarPorId(
                "prop-1",
                "usuario-1"
        )).thenReturn(criarPropriedade());
    }

    // TESTE 1 - Gerar um PDF valido
    @Test
    void deveGerarPdfValido() throws Exception {

        configurarPropriedade();

        when(analiseSoloService.listarPorPropriedade(
                "usuario-1",
                "prop-1"
        )).thenReturn(List.of(criarAnalise(1)));

        byte[] pdf = relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        );

        assertNotNull(pdf);
        assertTrue(pdf.length > 100);

        // Todo arquivo PDF possui essa assinatura
        String assinatura = new String(
                pdf,
                0,
                5,
                StandardCharsets.US_ASCII
        );

        assertEquals("%PDF-", assinatura);

        // Confirma que o PDF pode ser aberto pelo PDFBox
        try (PDDocument documento = Loader.loadPDF(pdf)) {

            assertTrue(documento.getNumberOfPages() >= 1);
        }
    }

    // TESTE 2 - Verificar as informacoes do PDF
    @Test
    void deveIncluirDadosDaPropriedadeEAnalise() throws Exception {

        configurarPropriedade();

        when(analiseSoloService.listarPorPropriedade(
                "usuario-1",
                "prop-1"
        )).thenReturn(List.of(criarAnalise(1)));

        byte[] pdf = relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        );

        try (PDDocument documento = Loader.loadPDF(pdf)) {

            String texto = new PDFTextStripper()
                    .getText(documento);

            assertTrue(texto.contains("Fazenda Teste PI4"));
            assertTrue(texto.contains("Campinas - SP"));
            assertTrue(texto.contains("Analise 1"));
            assertTrue(texto.contains("Talhao (ID): talhao-1"));
            assertTrue(texto.contains("Observacoes da analise 1"));

            // Confirma os resultados da analise
            assertTrue(texto.contains("5,80"));
            assertTrue(texto.contains("12,00"));
            assertTrue(texto.contains("4,00"));
            assertTrue(texto.contains("Saturacao por bases (V%): 60,00"));
        }

        verify(propriedadeService).buscarPorId(
                "prop-1",
                "usuario-1"
        );

        verify(analiseSoloService).listarPorPropriedade(
                "usuario-1",
                "prop-1"
        );
    }

    // TESTE 3 - Gerar relatorio sem analises
    @Test
    void deveGerarPdfSemAnalises() throws Exception {

        configurarPropriedade();

        when(analiseSoloService.listarPorPropriedade(
                "usuario-1",
                "prop-1"
        )).thenReturn(List.of());

        byte[] pdf = relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        );

        try (PDDocument documento = Loader.loadPDF(pdf)) {

            String texto = new PDFTextStripper()
                    .getText(documento);

            assertTrue(texto.contains("Fazenda Teste PI4"));
            assertTrue(texto.contains("Total de analises: 0"));
            assertTrue(texto.contains(
                    "Nenhuma analise de solo cadastrada."
            ));
        }
    }

    // TESTE 4 - Criar varias paginas quando houver muitas analises
    @Test
    void deveGerarPdfComMultiplasPaginas() throws Exception {

        configurarPropriedade();

        List<AnaliseSolo> analises = IntStream.rangeClosed(1, 25)
                .mapToObj(this::criarAnalise)
                .toList();

        when(analiseSoloService.listarPorPropriedade(
                "usuario-1",
                "prop-1"
        )).thenReturn(analises);

        byte[] pdf = relatorioPdfService.gerarRelatorio(
                "usuario-1",
                "prop-1"
        );

        try (PDDocument documento = Loader.loadPDF(pdf)) {

            assertTrue(documento.getNumberOfPages() > 1);

            String texto = new PDFTextStripper()
                    .getText(documento);

            assertTrue(texto.contains("Total de analises: 25"));
            assertTrue(texto.contains("Analise 25"));
            assertTrue(texto.contains("Observacoes da analise 25"));
        }
    }

    // TESTE 5 - Bloquear propriedade de outro usuario
    @Test
    void deveBloquearRelatorioDeOutroUsuario() {

        when(propriedadeService.buscarPorId(
                "prop-1",
                "usuario-2"
        )).thenThrow(new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "Propriedade nao encontrada"
        ));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> relatorioPdfService.gerarRelatorio(
                        "usuario-2",
                        "prop-1"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());

        // Nao deve buscar analises de uma propriedade inacessivel
        verifyNoInteractions(analiseSoloService);
    }
}
