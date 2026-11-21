// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.util.List;

import org.junit.jupiter.api.Test;

import br.com.talhao.dto.CenarioResponse;
import br.com.talhao.dto.RegraAplicada;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Classificacao;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Efeito;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.TipoUso;

import static org.junit.jupiter.api.Assertions.*;

// Testa as regras R1 a R7 com os casos T1 a T4 do documento 02
class RegrasRotacaoTest {

    private final Cultura soja = cultura("soja", "Soja", Grupo.LEGUMINOSA);
    private final Cultura feijao = cultura("feijao", "Feijão-comum", Grupo.LEGUMINOSA);
    private final Cultura milho = cultura("milho", "Milho", Grupo.GRAMINEA);
    private final Cultura trigo = cultura("trigo", "Trigo", Grupo.GRAMINEA);
    private final Cultura sorgo = cultura("sorgo", "Sorgo", Grupo.GRAMINEA);

    private final StatusSoloResponse solo = new StatusSoloResponse(
            StatusSolo.SAUDAVEL, null, List.of(), List.of(), null);

    private Cultura cultura(String id, String nome, Grupo grupo) {
        return new Cultura(id, nome, "", "", grupo,
                TipoUso.COMERCIAL, GrupoP.ANUAIS);
    }

    // Monta os cenarios como o SimulacaoService faz
    private List<CenarioResponse> simular(
            List<Cultura> historico,
            Cultura... candidatas) {

        return List.of(candidatas).stream()
                .map(c -> {
                    List<RegraAplicada> regras =
                            RegrasRotacao.avaliar(c, historico, solo);
                    return new CenarioResponse(c.id(), c.nome(),
                            RegrasRotacao.classificar(regras), regras);
                })
                .toList();
    }

    private boolean tem(CenarioResponse c, String regraId) {
        return c.regras().stream().anyMatch(r -> r.regraId().equals(regraId));
    }

    // T1 - Historico: soja
    @Test
    void t1_sojaNoHistorico() {

        List<CenarioResponse> r = simular(List.of(soja), milho, feijao, soja);

        assertEquals(Classificacao.RECOMENDADO, r.get(0).classificacao());
        assertTrue(tem(r.get(0), "R3"));

        assertEquals(Classificacao.ACEITAVEL, r.get(1).classificacao());
        assertTrue(tem(r.get(1), "R5"));

        assertEquals(Classificacao.NAO_RECOMENDADO, r.get(2).classificacao());
        assertTrue(tem(r.get(2), "R1"));

        assertFalse(RegrasRotacao.equivalentes(r));
    }

    // T2 - Historico (mais recente primeiro): milho, soja
    @Test
    void t2_milhoESoja() {

        List<CenarioResponse> r =
                simular(List.of(milho, soja), soja, feijao, trigo);

        // Soja: R4 favoravel, mas R2 alerta
        assertEquals(Classificacao.ACEITAVEL, r.get(0).classificacao());
        assertTrue(tem(r.get(0), "R4"));
        assertTrue(tem(r.get(0), "R2"));

        assertEquals(Classificacao.RECOMENDADO, r.get(1).classificacao());
        assertTrue(tem(r.get(1), "R4"));

        assertEquals(Classificacao.ACEITAVEL, r.get(2).classificacao());
        assertTrue(r.get(2).regras().isEmpty());
    }

    // T3 - Historico vazio: tudo aceitavel e equivalente (R7)
    @Test
    void t3_historicoVazio() {

        List<CenarioResponse> r = simular(List.of(), soja, milho);

        assertEquals(Classificacao.ACEITAVEL, r.get(0).classificacao());
        assertEquals(Classificacao.ACEITAVEL, r.get(1).classificacao());
        assertTrue(tem(r.get(0), "R7"));
        assertTrue(RegrasRotacao.equivalentes(r));
    }

    // T4 - Historico: milho; duas gramineas candidatas
    @Test
    void t4_graminea() {

        List<CenarioResponse> r = simular(List.of(milho), trigo, sorgo);

        assertEquals(Classificacao.ACEITAVEL, r.get(0).classificacao());
        assertEquals(Classificacao.ACEITAVEL, r.get(1).classificacao());
        assertTrue(RegrasRotacao.equivalentes(r));
    }

    // R2 so vale quando a cultura de duas safras atras difere da anterior
    @Test
    void r2_naoSeAplicaQuandoAAnteriorEIgual() {

        List<CenarioResponse> r = simular(List.of(soja, soja), soja);

        assertTrue(tem(r.get(0), "R1"));
        assertFalse(tem(r.get(0), "R2"));
    }

    // R7 nao aparece com duas safras no historico
    @Test
    void r7_naoApareceComDuasSafras() {

        List<CenarioResponse> r = simular(List.of(milho, soja), trigo);

        assertFalse(tem(r.get(0), "R7"));
    }

    // R6 vale para todos os cenarios e nao muda a classificacao
    @Test
    void r6_soloEmRiscoNaoMudaClassificacao() {

        StatusSoloResponse risco = new StatusSoloResponse(
                StatusSolo.RISCO, null, List.of(),
                List.of("pH (acidez muito alta)", "V% (muito baixa)"), null);

        List<RegraAplicada> regras = RegrasRotacao.avaliar(
                milho, List.of(soja), risco);

        RegraAplicada r6 = regras.stream()
                .filter(r -> r.regraId().equals("R6")).findFirst().orElseThrow();

        assertEquals(Efeito.NEUTRA, r6.efeito());
        assertTrue(r6.mensagem().contains("pH (acidez muito alta), V% (muito baixa)"));
        assertEquals(Classificacao.RECOMENDADO, RegrasRotacao.classificar(regras));
    }

    // Cada regra traz a fonte tecnica
    @Test
    void regrasTrazemFonte() {

        List<RegraAplicada> regras = RegrasRotacao.avaliar(
                milho, List.of(soja), solo);

        RegraAplicada r3 = regras.stream()
                .filter(r -> r.regraId().equals("R3")).findFirst().orElseThrow();

        assertEquals(List.of("F2", "F7"),
                r3.fontes().stream().map(f -> f.id()).toList());
    }
}
