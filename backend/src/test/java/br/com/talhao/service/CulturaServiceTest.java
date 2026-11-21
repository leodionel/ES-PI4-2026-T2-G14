package br.com.talhao.service;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.CulturaRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa o catalogo de culturas sem utilizar um MongoDB real
@ExtendWith(MockitoExtension.class)
class CulturaServiceTest {

    @Mock
    private CulturaRepository culturaRepository;

    @InjectMocks
    private CulturaService culturaService;

    private final Cultura soja = new Cultura(
            "soja", "Soja", "Glycine max", "Fabaceae",
            Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    private final Cultura milho = new Cultura(
            "milho", "Milho", "Zea mays", "Poaceae",
            Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS);

    // TESTE 1 - Lista em ordem alfabetica e le o banco uma unica vez
    @Test
    void deveListarEmOrdemAlfabeticaELerOBancoUmaVez() {

        when(culturaRepository.findAll()).thenReturn(List.of(soja, milho));

        List<Cultura> lista = culturaService.listar();
        culturaService.buscar("soja");

        assertEquals("Milho", lista.get(0).nome());
        verify(culturaRepository, times(1)).findAll();
    }

    // TESTE 2 - Cultura fora do catalogo gera erro 400
    @Test
    void deveRecusarCulturaInexistente() {

        when(culturaRepository.findAll()).thenReturn(List.of(soja));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> culturaService.buscar("xyz"));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
    }
}
