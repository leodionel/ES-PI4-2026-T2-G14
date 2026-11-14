package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.UpdateDefinition;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.mongodb.client.result.UpdateResult;

import br.com.talhao.dto.PlantioResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

// Testa as regras dos plantios sem utilizar um MongoDB real
@ExtendWith(MockitoExtension.class)
class PlantioServiceTest {

    @Mock
    private TalhaoService talhaoService;

    @Mock
    private CulturaService culturaService;

    @Mock
    private MongoTemplate mongoTemplate;

    @InjectMocks
    private PlantioService plantioService;

    private final Cultura soja = new Cultura(
            "soja", "Soja", "Glycine max", "Fabaceae",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private final Cultura milho = new Cultura(
            "milho", "Milho", "Zea mays", "Poaceae",
            Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private Talhao talhaoCom(List<Plantio> plantios) {
        return new Talhao("t1", "p1", "Talhão 04", 10.0,
                Instant.now(), plantios);
    }

    private void simularAtualizacao(long encontrados) {
        when(mongoTemplate.updateFirst(
                any(Query.class),
                any(UpdateDefinition.class),
                eq(Talhao.class)))
                .thenReturn(UpdateResult.acknowledged(encontrados, encontrados, null));
    }

    // TESTE 1 - Registra o plantio com o nome da cultura
    @Test
    void deveRegistrarPlantio() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of()));
        when(culturaService.buscar("soja")).thenReturn(soja);
        simularAtualizacao(1);

        PlantioResponse resposta = plantioService.registrar(
                "t1", "u1", "soja", LocalDate.of(2026, 11, 15));

        assertEquals("Soja", resposta.culturaNome());
        assertNull(resposta.dataColheita());
        assertNotNull(resposta.plantioId());
        verify(mongoTemplate).updateFirst(
                any(Query.class), any(UpdateDefinition.class), eq(Talhao.class));
    }

    // TESTE 2 - Cultura fora do catalogo e recusada
    @Test
    void naoDeveRegistrarCulturaInexistente() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of()));
        when(culturaService.buscar("xyz"))
                .thenThrow(new ResponseStatusException(HttpStatus.BAD_REQUEST));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrar(
                        "t1", "u1", "xyz", LocalDate.of(2026, 11, 15)));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verifyNoInteractions(mongoTemplate);
    }

    // TESTE 3 - Talhao de outro usuario nao recebe plantio
    @Test
    void naoDeveRegistrarEmTalhaoDeOutroUsuario() {

        when(talhaoService.buscarEntidade("t1", "u2"))
                .thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrar(
                        "t1", "u2", "soja", LocalDate.of(2026, 11, 15)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
        verifyNoInteractions(mongoTemplate);
    }

    // TESTE 4 - A lista sai do mais antigo ao mais recente
    @Test
    void deveListarPlantiosEmOrdemCronologica() {

        Plantio recente = new Plantio("b", "soja",
                LocalDate.of(2025, 11, 15), null);
        Plantio antigo = new Plantio("a", "milho",
                LocalDate.of(2025, 3, 10), LocalDate.of(2025, 8, 2));

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of(recente, antigo)));
        when(culturaService.listar()).thenReturn(List.of(milho, soja));

        List<PlantioResponse> lista = plantioService.listar("t1", "u1");

        assertEquals("a", lista.get(0).plantioId());
        assertEquals("Milho", lista.get(0).culturaNome());
        assertEquals("b", lista.get(1).plantioId());
    }

    // TESTE 5 - Registra a colheita de um plantio aberto
    @Test
    void deveRegistrarColheita() {

        Plantio aberto = new Plantio("a", "soja",
                LocalDate.of(2025, 11, 15), null);

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of(aberto)));
        when(culturaService.listar()).thenReturn(List.of(soja));
        simularAtualizacao(1);

        PlantioResponse resposta = plantioService.registrarColheita(
                "t1", "a", "u1", LocalDate.of(2026, 3, 20));

        assertEquals(LocalDate.of(2026, 3, 20), resposta.dataColheita());
    }

    // TESTE 6 - Plantio ja colhido nao pode ser colhido de novo
    @Test
    void naoDeveRegistrarColheitaDuasVezes() {

        Plantio fechado = new Plantio("a", "soja",
                LocalDate.of(2025, 11, 15), LocalDate.of(2026, 3, 20));

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of(fechado)));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrarColheita(
                        "t1", "a", "u1", LocalDate.of(2026, 4, 1)));

        assertEquals(HttpStatus.CONFLICT, erro.getStatusCode());
        verifyNoInteractions(mongoTemplate);
    }

    // TESTE 7 - A colheita nao pode ser antes do plantio
    @Test
    void naoDeveAceitarColheitaAnteriorAoPlantio() {

        Plantio aberto = new Plantio("a", "soja",
                LocalDate.of(2025, 11, 15), null);

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of(aberto)));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrarColheita(
                        "t1", "a", "u1", LocalDate.of(2025, 10, 1)));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verifyNoInteractions(mongoTemplate);
    }

    // TESTE 8 - Plantio inexistente responde 404
    @Test
    void deveRetornar404ParaPlantioInexistente() {

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of()));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrarColheita(
                        "t1", "nao-existe", "u1", LocalDate.of(2026, 3, 20)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
    }

    // TESTE 9 - Se outro pedido fechou o plantio no meio, responde 409
    @Test
    void deveRetornar409SeOPlantioFoiFechadoNoMeioDoCaminho() {

        Plantio aberto = new Plantio("a", "soja",
                LocalDate.of(2025, 11, 15), null);

        when(talhaoService.buscarEntidade("t1", "u1"))
                .thenReturn(talhaoCom(List.of(aberto)));
        simularAtualizacao(0);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> plantioService.registrarColheita(
                        "t1", "a", "u1", LocalDate.of(2026, 3, 20)));

        assertEquals(HttpStatus.CONFLICT, erro.getStatusCode());
    }
}
