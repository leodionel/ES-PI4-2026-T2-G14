package br.com.talhao.controller;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.IntStream;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.AnaliseSoloRepository;
import br.com.talhao.repository.CulturaRepository;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;
import br.com.talhao.repository.UsuarioRepository;
import br.com.talhao.service.AnaliseSoloService;
import br.com.talhao.service.CulturaService;
import br.com.talhao.service.PropriedadeService;
import br.com.talhao.service.RelatorioPdfService;
import br.com.talhao.service.TalhaoService;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Exercita a rota, a autorizacao e a geracao real do PDF; apenas o banco e o JWT sao simulados.
@WebMvcTest(RelatorioController.class)
@Import({RelatorioPdfService.class, TalhaoService.class, PropriedadeService.class,
        AnaliseSoloService.class, CulturaService.class})
class ProntuarioTalhaoControllerTest {

    private static final String ROTA = "/api/relatorios/talhao/talhao-1/pdf";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private JwtDecoder jwtDecoder;
    @MockitoBean
    private TalhaoRepository talhaoRepository;
    @MockitoBean
    private PropriedadeRepository propriedadeRepository;
    @MockitoBean
    private AnaliseSoloRepository analiseSoloRepository;
    @MockitoBean
    private CulturaRepository culturaRepository;
    @MockitoBean
    private UsuarioRepository usuarioRepository;
    @MockitoBean
    private MongoTemplate mongoTemplate;

    @Test
    void deveExportarDadosDoTalhaoComCulturasSafrasEAnalisesEmOrdem() throws Exception {
        configurarTalhao(List.of(
                new Plantio("plantio-aberto", "soja", LocalDate.of(2026, 10, 1), null),
                new Plantio("plantio-colhido", "milho", LocalDate.of(2025, 11, 15), LocalDate.of(2026, 3, 20))));
        configurarAnalises(List.of(analise(2, "Laudo recente"), analise(1, "Laudo anterior")));

        try (PDDocument pdf = Loader.loadPDF(baixarPdf())) {
            String texto = new PDFTextStripper().getText(pdf);
            assertAll(
                    () -> assertTrue(texto.contains("PRONTUÁRIO DIGITAL DO TALHÃO")),
                    () -> assertTrue(texto.contains("Fazenda São José")),
                    () -> assertTrue(texto.contains("Campinas - SP")),
                    () -> assertTrue(texto.contains("Talhão: Talhão das Águas")),
                    () -> assertTrue(texto.contains("ID do talhão: talhao-1")),
                    () -> assertTrue(texto.contains("Área: 42,80 ha")),
                    () -> assertTrue(texto.contains("Total de safras: 2")),
                    () -> assertTrue(texto.contains("Cultura: Milho")),
                    () -> assertTrue(texto.contains("Cultura: Soja")),
                    () -> assertTrue(texto.contains("Data do plantio: 15/11/2025")),
                    () -> assertTrue(texto.contains("Colheita: 20/03/2026")),
                    () -> assertTrue(texto.contains("Colheita: Em aberto")),
                    () -> assertTrue(texto.contains("Total de análises: 2")),
                    () -> assertTrue(texto.contains("Data da coleta: 01/04/2026")),
                    () -> assertTrue(texto.contains("pH (CaCl2): 5,80")),
                    () -> assertTrue(texto.contains("Fósforo (P resina, mg/dm³): 12,00")),
                    () -> assertTrue(texto.contains("Potássio (mmolc/dm³): 4,00")),
                    () -> assertTrue(texto.contains("Saturação por bases (V%): 60,00")),
                    () -> assertTrue(texto.indexOf("Cultura: Milho") < texto.indexOf("Cultura: Soja")),
                    () -> assertTrue(texto.indexOf("Laudo anterior") < texto.indexOf("Laudo recente")));
        }
        verify(talhaoRepository).findByIdAndPropriedadeId("talhao-1", "prop-1");
        verify(analiseSoloRepository).findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                "usuario-1", "prop-1", "talhao-1");
        verifyNoMoreInteractions(analiseSoloRepository);
    }

    @Test
    void deveExportarTalhaoSemHistorico() throws Exception {
        configurarTalhao(List.of());
        configurarAnalises(List.of());

        try (PDDocument pdf = Loader.loadPDF(baixarPdf())) {
            String texto = new PDFTextStripper().getText(pdf);
            assertEquals(1, pdf.getNumberOfPages());
            assertTrue(texto.contains("Total de safras: 0"));
            assertTrue(texto.contains("Nenhuma safra cadastrada."));
            assertTrue(texto.contains("Total de análises: 0"));
            assertTrue(texto.contains("Nenhuma análise de solo cadastrada."));
        }
        verifyNoInteractions(culturaRepository);
    }

    @Test
    void devePreservarCulturaForaDoCatalogoECamposOpcionaisVazios() throws Exception {
        configurarTalhao(List.of(new Plantio("plantio-antigo", "cultura-antiga", null, null)));
        configurarAnalises(List.of(new AnaliseSolo("analise-antiga", "usuario-1", "prop-1", "talhao-1",
                null, null, null, null, null, null)));

        try (PDDocument pdf = Loader.loadPDF(baixarPdf())) {
            String texto = new PDFTextStripper().getText(pdf);
            assertTrue(texto.contains("Cultura: cultura-antiga"));
            assertTrue(texto.contains("Data do plantio: Nao informada"));
            assertTrue(texto.contains("pH (CaCl2): Nao informado"));
            assertTrue(texto.contains("Observações: Não informado"));
            assertFalse(texto.contains("null"));
        }
    }

    @Test
    void devePaginarSemPerderRegistrosNemUltrapassarMargens() throws Exception {
        configurarTalhao(IntStream.rangeClosed(1, 25)
                .mapToObj(i -> new Plantio("plantio-" + i, "milho", LocalDate.of(2026, 1, i), null))
                .toList());
        configurarAnalises(IntStream.rangeClosed(1, 25)
                .mapToObj(i -> analise(i, "Laudo " + i + " - " + "observação extensa ".repeat(30) + "fim-" + i))
                .toList());

        try (PDDocument pdf = Loader.loadPDF(baixarPdf())) {
            PDFTextStripper verificador = new PDFTextStripper() {
                @Override
                protected void writeString(String texto, List<TextPosition> posicoes) throws IOException {
                    for (TextPosition posicao : posicoes) {
                        assertTrue(posicao.getXDirAdj() >= 49);
                        assertTrue(posicao.getXDirAdj() + posicao.getWidthDirAdj() <= PDRectangle.A4.getWidth() - 49);
                        assertTrue(posicao.getYDirAdj() >= 49);
                        assertTrue(posicao.getYDirAdj() <= PDRectangle.A4.getHeight() - 59);
                    }
                    super.writeString(texto, posicoes);
                }
            };
            String texto = verificador.getText(pdf);
            assertTrue(pdf.getNumberOfPages() > 1);
            for (int i = 1; i <= 25; i++) {
                assertTrue(texto.contains("ID do plantio: plantio-" + i));
                assertTrue(texto.contains("Laudo " + i + " -"));
                assertTrue(texto.replaceAll("\\s+", "").contains("fim-" + i));
            }
        }
    }

    @Test
    void deveQuebrarObservacoesEntrePalavrasEConservarTextoLongoSemEspacos() throws Exception {
        configurarTalhao(List.of());
        String observacoes = "Amostras coletadas após a colheita, em pontos distribuídos pelo talhão. "
                + "Resultado registrado pelo produtor para acompanhamento do histórico da área. "
                + "X".repeat(300);
        configurarAnalises(List.of(analise(1, observacoes)));

        try (PDDocument pdf = Loader.loadPDF(baixarPdf())) {
            String texto = new PDFTextStripper().getText(pdf);
            assertTrue(texto.replaceAll("\\s+", " ").contains("Resultado registrado pelo produtor"));
            assertTrue(texto.replaceAll("\\s+", "").contains("X".repeat(300)));
        }
    }

    @Test
    void deveBloquearDownloadSemToken() throws Exception {
        mockMvc.perform(get(ROTA)).andExpect(status().isUnauthorized());
        verifyNoInteractions(talhaoRepository, propriedadeRepository, analiseSoloRepository, culturaRepository);
    }

    @ParameterizedTest
    @ValueSource(strings = {"token-invalido", "token-expirado"})
    void deveBloquearTokenRejeitado(String token) throws Exception {
        when(jwtDecoder.decode(token)).thenThrow(new JwtException("JWT rejeitado"));
        mockMvc.perform(get(ROTA).header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(talhaoRepository, propriedadeRepository, analiseSoloRepository, culturaRepository);
    }

    @ParameterizedTest
    @ValueSource(strings = {"talhao-inexistente", "talhao-de-outro-usuario"})
    void deveRetornar404ParaTalhaoForaDaPropriedade(String talhaoId) throws Exception {
        configurarJwt("usuario-1");
        when(propriedadeRepository.findByUsuarioId("usuario-1")).thenReturn(List.of(propriedade()));

        mockMvc.perform(get("/api/relatorios/talhao/{id}/pdf", talhaoId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer token-teste"))
                .andExpect(status().isNotFound());

        verify(talhaoRepository).findByIdAndPropriedadeId(talhaoId, "prop-1");
        verifyNoInteractions(analiseSoloRepository, culturaRepository);
    }

    @Test
    void deveUsarUsuarioDoJwtMesmoQuandoParametroTentaTrocarODono() throws Exception {
        configurarJwt("usuario-2");
        when(propriedadeRepository.findByUsuarioId("usuario-2"))
                .thenReturn(List.of(new Propriedade("prop-2", "usuario-2", "Outra fazenda", "Outro local")));

        mockMvc.perform(get(ROTA).param("usuarioId", "usuario-1").param("propriedadeId", "prop-1")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer token-teste"))
                .andExpect(status().isNotFound());

        verify(talhaoRepository).findByIdAndPropriedadeId("talhao-1", "prop-2");
        verifyNoInteractions(analiseSoloRepository, culturaRepository);
    }

    @Test
    void deveRetornar404ParaUsuarioSemPropriedade() throws Exception {
        configurarJwt("usuario-sem-propriedade");
        mockMvc.perform(get(ROTA).header(HttpHeaders.AUTHORIZATION, "Bearer token-teste"))
                .andExpect(status().isNotFound());
        verifyNoInteractions(talhaoRepository, analiseSoloRepository, culturaRepository);
    }

    private void configurarTalhao(List<Plantio> plantios) {
        configurarJwt("usuario-1");
        when(propriedadeRepository.findByUsuarioId("usuario-1")).thenReturn(List.of(propriedade()));
        when(propriedadeRepository.findByIdAndUsuarioId("prop-1", "usuario-1"))
                .thenReturn(Optional.of(propriedade()));
        when(talhaoRepository.findByIdAndPropriedadeId("talhao-1", "prop-1"))
                .thenReturn(Optional.of(new Talhao("talhao-1", "prop-1", "Talhão das Águas", 42.8,
                        Instant.parse("2025-10-01T00:00:00Z"), plantios)));
        when(culturaRepository.findAll()).thenReturn(List.of(
                new Cultura("milho", "Milho", "Zea mays", "Poaceae", Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
                new Cultura("soja", "Soja", "Glycine max", "Fabaceae", Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS)));
    }

    private void configurarAnalises(List<AnaliseSolo> analises) {
        when(analiseSoloRepository.findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                "usuario-1", "prop-1", "talhao-1")).thenReturn(analises);
    }

    private void configurarJwt(String usuarioId) {
        when(jwtDecoder.decode("token-teste")).thenReturn(Jwt.withTokenValue("token-teste")
                .header("alg", "HS256").claim("iss", "talhao-api").subject(usuarioId).build());
    }

    private Propriedade propriedade() {
        return new Propriedade("prop-1", "usuario-1", "Fazenda São José", "Campinas - SP");
    }

    private AnaliseSolo analise(int dia, String observacoes) {
        return new AnaliseSolo("analise-" + dia, "usuario-1", "prop-1", "talhao-1",
                LocalDate.of(2026, 4, dia), 5.8, 12.0, 4.0, 60.0, observacoes);
    }

    private byte[] baixarPdf() throws Exception {
        var resposta = mockMvc.perform(get(ROTA).header(HttpHeaders.AUTHORIZATION, "Bearer token-teste"))
                .andExpect(status().isOk())
                .andExpect(content().contentType("application/pdf"))
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"prontuario-talhao.pdf\""))
                .andReturn().getResponse();
        byte[] pdf = resposta.getContentAsByteArray();
        assertEquals(String.valueOf(pdf.length), resposta.getHeader(HttpHeaders.CONTENT_LENGTH));
        return pdf;
    }
}
