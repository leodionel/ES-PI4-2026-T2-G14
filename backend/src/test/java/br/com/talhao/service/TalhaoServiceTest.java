package br.com.talhao.service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.TalhaoRequest;
import br.com.talhao.dto.TalhaoResponse;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

// Testa as regras de negocio dos talhoes sem utilizar um MongoDB real
@ExtendWith(MockitoExtension.class)
class TalhaoServiceTest {

    @Mock
    private TalhaoRepository talhaoRepository;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @Mock
    private MongoTemplate mongoTemplate;

    @InjectMocks
    private TalhaoService talhaoService;

    private final Propriedade propriedadeDoJoao =
            new Propriedade("p1", "u1", "Fazenda Boa Vista", "Campinas");

    private final Propriedade propriedadeDaMaria =
            new Propriedade("p2", "u2", "Sitio Aurora", "Piracicaba");

    // Talhao com 1 safra e 2 analises
    private Talhao talhaoDoJoao() {
        return new Talhao(
                "t1",
                "p1",
                "Talhão 04",
                42.8,
                Instant.now(),
                List.of(new Plantio("pl1", "soja", null, null)),
                List.of(
                        new AnaliseSolo("a1", null, 5.3, 30, 2.0, 55),
                        new AnaliseSolo("a2", null, 5.5, 32, 2.2, 58)
                )
        );
    }

    // TESTE 1 - O talhao nasce na propriedade do usuario autenticado
    @Test
    void deveCriarTalhaoNaPropriedadeDoUsuario() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedadeDoJoao));
        when(talhaoRepository.save(any(Talhao.class)))
                .thenAnswer(chamada -> chamada.getArgument(0));

        TalhaoResponse resposta = talhaoService.criar(
                "u1",
                new TalhaoRequest("  Talhão 04  ", 42.8)
        );

        ArgumentCaptor<Talhao> salvo = ArgumentCaptor.forClass(Talhao.class);
        verify(talhaoRepository).save(salvo.capture());

        assertEquals("p1", salvo.getValue().propriedadeId());
        assertEquals("Talhão 04", salvo.getValue().nome());
        assertEquals(0, resposta.totalPlantios());
        assertEquals(0, resposta.totalAnalises());
    }

    // TESTE 2 - Sem propriedade, nao e possivel criar talhao
    @Test
    void naoDeveCriarTalhaoSemPropriedade() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> talhaoService.criar("u1", new TalhaoRequest("T1", 10.0))
        );

        assertEquals(HttpStatus.CONFLICT, erro.getStatusCode());
        verify(talhaoRepository, never()).save(any());
    }

    // TESTE 3 - A listagem usa apenas a propriedade do usuario
    @Test
    void deveListarSomenteTalhoesDaPropriedadeDoUsuario() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedadeDoJoao));
        when(talhaoRepository.findByPropriedadeId("p1"))
                .thenReturn(List.of(talhaoDoJoao()));

        List<TalhaoResponse> lista = talhaoService.listar("u1");

        assertEquals(1, lista.size());
        verify(talhaoRepository, never()).findByPropriedadeId("p2");
    }

    // TESTE 4 - O detalhe informa quantas safras e analises existem
    @Test
    void deveInformarQuantidadeDeSafrasEAnalises() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedadeDoJoao));
        when(talhaoRepository.findByIdAndPropriedadeId("t1", "p1"))
                .thenReturn(Optional.of(talhaoDoJoao()));

        TalhaoResponse resposta = talhaoService.buscar("t1", "u1");

        assertEquals(1, resposta.totalPlantios());
        assertEquals(2, resposta.totalAnalises());
    }

    // TESTE 5 - Um usuario nao enxerga o talhao de outro
    @Test
    void naoDeveEntregarTalhaoDeOutroUsuario() {

        // A Maria pede o talhao t1, que pertence a propriedade p1 (do Joao)
        when(propriedadeRepository.findByUsuarioId("u2"))
                .thenReturn(List.of(propriedadeDaMaria));
        when(talhaoRepository.findByIdAndPropriedadeId("t1", "p2"))
                .thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> talhaoService.buscar("t1", "u2")
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
    }

    // TESTE 6 - Excluir com o nome errado falha e nada e apagado
    @Test
    void naoDeveExcluirComNomeErrado() {

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedadeDoJoao));
        when(talhaoRepository.findByIdAndPropriedadeId("t1", "p1"))
                .thenReturn(Optional.of(talhaoDoJoao()));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> talhaoService.excluir("t1", "u1", "Talhão 05")
        );

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verify(talhaoRepository, never()).delete(any());
    }

    // TESTE 7 - O nome pode ser digitado em outra caixa e com espacos
    @Test
    void deveExcluirIgnorandoCaixaEEspacos() {

        Talhao talhao = talhaoDoJoao();

        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(propriedadeDoJoao));
        when(talhaoRepository.findByIdAndPropriedadeId("t1", "p1"))
                .thenReturn(Optional.of(talhao));

        talhaoService.excluir("t1", "u1", "  TALHÃO 04 ");

        verify(talhaoRepository).delete(talhao);
    }

    // TESTE 8 - Um usuario nao exclui o talhao de outro
    @Test
    void naoDeveExcluirTalhaoDeOutroUsuario() {

        when(propriedadeRepository.findByUsuarioId("u2"))
                .thenReturn(List.of(propriedadeDaMaria));
        when(talhaoRepository.findByIdAndPropriedadeId("t1", "p2"))
                .thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> talhaoService.excluir("t1", "u2", "Talhão 04")
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
        verify(talhaoRepository, never()).delete(any());
    }
}
