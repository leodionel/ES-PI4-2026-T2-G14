package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;

import static org.junit.jupiter.api.Assertions.*;

// Testa a escolha do plantio atual de um talhao
class HistoricoTalhaoPlantioAtualTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 6, 15);

    private final Map<String, Cultura> catalogo = Map.of(
            "soja", new Cultura(
                    "soja", "Soja", "Glycine max", "Fabaceae",
                    Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            "milho", new Cultura(
                    "milho", "Milho", "Zea mays", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS));

    private Talhao talhaoCom(Plantio... plantios) {
        return new Talhao(
                "t1", "p1", "Talhao 1", 10, Instant.now(), List.of(plantios));
    }

    private Plantio plantio(
            String id, String cultura, LocalDate plantio, LocalDate colheita) {
        return new Plantio(id, cultura, plantio, colheita);
    }

    // TESTE 1 - Sem plantios nao ha cultura atual
    @Test
    void naoDeveTerCulturaAtualSemPlantios() {

        assertTrue(HistoricoTalhao
                .plantioAtual(talhaoCom(), catalogo, HOJE).isEmpty());
    }

    // TESTE 2 - Plantio sem colheita e a cultura atual
    @Test
    void deveEscolherPlantioSemColheita() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(plantio("a", "soja", LocalDate.of(2026, 1, 10), null)),
                catalogo, HOJE);

        assertEquals("a", atual.orElseThrow().plantioId());
    }

    // TESTE 3 - Plantio ja colhido nao e mais atual
    @Test
    void naoDeveEscolherPlantioJaColhido() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(plantio("a", "soja",
                        LocalDate.of(2026, 1, 10), LocalDate.of(2026, 5, 1))),
                catalogo, HOJE);

        assertTrue(atual.isEmpty());
    }

    // TESTE 4 - Entre dois plantios abertos vence o mais recente
    @Test
    void deveEscolherOPlantioAbertoMaisRecente() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("antigo", "soja", LocalDate.of(2026, 1, 10), null),
                        plantio("novo", "milho", LocalDate.of(2026, 3, 1), null)),
                catalogo, HOJE);

        assertEquals("novo", atual.orElseThrow().plantioId());
    }

    // TESTE 5 - A ordem em que foram registrados nao importa
    @Test
    void deveIgnorarAOrdemDeRegistro() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("novo", "milho", LocalDate.of(2026, 3, 1), null),
                        plantio("antigo", "soja", LocalDate.of(2026, 1, 10), null)),
                catalogo, HOJE);

        assertEquals("novo", atual.orElseThrow().plantioId());
    }

    // TESTE 6 - Com a mesma data, vale o registrado por ultimo
    @Test
    void deveDesempatarPeloUltimoRegistrado() {

        LocalDate data = LocalDate.of(2026, 3, 1);

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("primeiro", "soja", data, null),
                        plantio("segundo", "milho", data, null)),
                catalogo, HOJE);

        assertEquals("segundo", atual.orElseThrow().plantioId());
    }

    // TESTE 7 - Plantio com data futura ainda nao e atual
    @Test
    void naoDeveEscolherPlantioComDataFutura() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("futuro", "milho", HOJE.plusDays(10), null),
                        plantio("atual", "soja", LocalDate.of(2026, 1, 10), null)),
                catalogo, HOJE);

        assertEquals("atual", atual.orElseThrow().plantioId());
    }

    // TESTE 8 - Plantio iniciado hoje ja conta
    @Test
    void deveEscolherPlantioIniciadoHoje() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(plantio("hoje", "soja", HOJE, null)),
                catalogo, HOJE);

        assertEquals("hoje", atual.orElseThrow().plantioId());
    }

    // TESTE 9 - Cultura que saiu do catalogo e ignorada
    @Test
    void deveIgnorarCulturaForaDoCatalogo() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("sumiu", "trigo-inexistente",
                                LocalDate.of(2026, 3, 1), null),
                        plantio("valido", "soja", LocalDate.of(2026, 1, 10), null)),
                catalogo, HOJE);

        assertEquals("valido", atual.orElseThrow().plantioId());
    }

    // TESTE 10 - Colhido recente nao esconde um plantio aberto mais antigo
    @Test
    void deveEscolherAbertoMesmoComColhidoMaisRecente() {

        Optional<Plantio> atual = HistoricoTalhao.plantioAtual(
                talhaoCom(
                        plantio("aberto", "soja", LocalDate.of(2026, 1, 10), null),
                        plantio("colhido", "milho",
                                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 4, 1))),
                catalogo, HOJE);

        assertEquals("aberto", atual.orElseThrow().plantioId());
    }
}
