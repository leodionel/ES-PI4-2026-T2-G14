package br.com.talhao.service;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;

import br.com.talhao.dto.IndicadorSolo;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.TipoUso;

import static org.junit.jupiter.api.Assertions.*;

// Testa o status do solo com os casos T5 a T7 do documento 02
class ClassificadorSoloTest {

    private final Cultura soja = new Cultura(
            "soja", "Soja", "Glycine max", "Fabaceae",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private final Cultura batata = new Cultura(
            "batata", "Batata", "Solanum tuberosum", "Solanaceae",
            Grupo.OUTRAS, TipoUso.COMERCIAL, GrupoP.HORTALICAS);

    private AnaliseSolo analise(double ph, double p, double k, double v) {
        return new AnaliseSolo("a1", "u1", "p1", "t1",
                LocalDate.of(2026, 10, 20), ph, p, k, v, null);
    }

    private String classe(StatusSoloResponse r, String parametro) {
        return r.indicadores().stream()
                .filter(i -> i.parametro().equals(parametro))
                .map(IndicadorSolo::classe)
                .findFirst()
                .orElse(null);
    }

    // T5 - pH e V% criticos, P e K em atencao: Risco
    @Test
    void deveClassificarComoRisco() {

        StatusSoloResponse r = ClassificadorSolo.classificar(
                analise(4.2, 10, 1.0, 22), soja);

        assertEquals(StatusSolo.RISCO, r.status());
        assertEquals(4, r.motivos().size());
        assertNull(r.aviso());
    }

    // T6 - Nenhum alerta: Saudavel
    @Test
    void deveClassificarComoSaudavel() {

        StatusSoloResponse r = ClassificadorSolo.classificar(
                analise(5.3, 30, 2.0, 55), soja);

        assertEquals(StatusSolo.SAUDAVEL, r.status());
        assertTrue(r.motivos().isEmpty());
    }

    // T7 - Limites das classes (cultura anual)
    @Test
    void deveRespeitarOsLimitesDasClasses() {

        StatusSoloResponse a = ClassificadorSolo.classificar(
                analise(4.3, 15, 1.5, 25), soja);
        StatusSoloResponse b = ClassificadorSolo.classificar(
                analise(4.4, 16, 1.6, 26), soja);

        assertEquals("Acidez muito alta", classe(a, "pH"));
        assertEquals("Acidez alta", classe(b, "pH"));
        assertEquals("Muito baixa", classe(a, "V%"));
        assertEquals("Baixa", classe(b, "V%"));
        assertEquals("Baixo", classe(a, "P"));
        assertEquals("Médio", classe(b, "P"));
        assertEquals("Baixo", classe(a, "K"));
        assertEquals("Médio", classe(b, "K"));
    }

    // Sem nenhuma analise o status e Sem analise
    @Test
    void deveRetornarSemAnaliseQuandoNaoHaLaudo() {

        StatusSoloResponse r = ClassificadorSolo.classificar(null, soja);

        assertEquals(StatusSolo.SEM_ANALISE, r.status());
        assertTrue(r.indicadores().isEmpty());
    }

    // Hortalicas usam outra faixa de fosforo: 25 e baixo, 26 e medio
    @Test
    void deveUsarFaixaDeFosforoDeHortalicas() {

        StatusSoloResponse baixo = ClassificadorSolo.classificar(
                analise(5.3, 25, 2.0, 55), batata);
        StatusSoloResponse medio = ClassificadorSolo.classificar(
                analise(5.3, 26, 2.0, 55), batata);

        assertEquals("Baixo", classe(baixo, "P"));
        assertEquals(StatusSolo.ATENCAO, baixo.status());
        assertEquals("Médio", classe(medio, "P"));
        assertEquals(StatusSolo.SAUDAVEL, medio.status());
    }

    // Sem cultura comercial o fosforo fica de fora e o sistema avisa
    @Test
    void deveIgnorarFosforoSemCulturaComercial() {

        StatusSoloResponse r = ClassificadorSolo.classificar(
                analise(5.3, 5, 2.0, 55), null);

        assertEquals(StatusSolo.SAUDAVEL, r.status());
        assertNull(classe(r, "P"));
        assertNotNull(r.aviso());
    }

    // K muito alto e atencao (possivel desequilibrio)
    @Test
    void deveSinalizarPotassioMuitoAlto() {

        StatusSoloResponse r = ClassificadorSolo.classificar(
                analise(5.3, 30, 6.1, 55), soja);

        assertEquals("Muito alto", classe(r, "K"));
        assertEquals(StatusSolo.ATENCAO, r.status());
    }

    // Analises antigas podem ter campo vazio: o sistema nao quebra
    @Test
    void deveToleraCampoSemValor() {

        AnaliseSolo antiga = new AnaliseSolo("a1", "u1", "p1", "t1",
                LocalDate.of(2026, 10, 20), 5.3, 30.0, 2.0, null, null);

        StatusSoloResponse r = ClassificadorSolo.classificar(antiga, soja);

        assertEquals(StatusSolo.SAUDAVEL, r.status());
        assertTrue(r.aviso().contains("V%"));
    }
}
