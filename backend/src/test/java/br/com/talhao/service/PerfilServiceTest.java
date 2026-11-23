// Feito por Leonardo Dionel RA:25010092

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

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.AtualizacaoPerfilRequest;
import br.com.talhao.dto.PerfilResponse;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

// Testes das regras de negocio do perfil
@ExtendWith(MockitoExtension.class)
class PerfilServiceTest {

    private static final Instant CRIADO_EM =
            Instant.parse("2026-01-10T12:00:00Z");

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private PropriedadeRepository propriedadeRepository;

    @InjectMocks
    private PerfilService perfilService;

    private Usuario criarUsuario() {

        return new Usuario(
                "u1",
                "Maria Silva",
                "maria@email.com",
                "19999999999",
                "hash-secreto",
                CRIADO_EM
        );
    }

    // TESTE 1 - Retorna o usuario e a propriedade dele
    @Test
    void deveBuscarPerfilComPropriedade() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.of(criarUsuario()));
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of(new Propriedade(
                        "p1", "u1", "Sitio Boa Vista", "Campinas - SP")));

        PerfilResponse perfil = perfilService.buscar("u1");

        assertEquals("u1", perfil.usuario().id());
        assertEquals("Maria Silva", perfil.usuario().nome());
        assertEquals("maria@email.com", perfil.usuario().email());
        assertEquals(CRIADO_EM, perfil.usuario().criadoEm());
        assertEquals("p1", perfil.propriedade().id());
        assertEquals("Sitio Boa Vista", perfil.propriedade().nome());
        assertEquals("Campinas - SP", perfil.propriedade().localizacao());
    }

    // TESTE 2 - Sem propriedade cadastrada, ela vem nula
    @Test
    void devePermitirPerfilSemPropriedade() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.of(criarUsuario()));
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        PerfilResponse perfil = perfilService.buscar("u1");

        assertNotNull(perfil.usuario());
        assertNull(perfil.propriedade());
    }

    // TESTE 3 - Usuario que nao existe mais perde a sessao
    @Test
    void deveRetornar401QuandoOUsuarioNaoExiste() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> perfilService.buscar("u1")
        );

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatusCode());
        verifyNoInteractions(propriedadeRepository);
    }

    // TESTE 4 - Atualiza nome e telefone e preserva o resto
    @Test
    void deveAtualizarNomeETelefonePreservandoOsDemaisCampos() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.of(criarUsuario()));
        when(usuarioRepository.save(any(Usuario.class)))
                .thenAnswer(chamada -> chamada.getArgument(0));
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        PerfilResponse perfil = perfilService.atualizar(
                "u1",
                new AtualizacaoPerfilRequest("Maria Souza", "1933334444")
        );

        ArgumentCaptor<Usuario> captor =
                ArgumentCaptor.forClass(Usuario.class);
        verify(usuarioRepository).save(captor.capture());

        Usuario salvo = captor.getValue();
        assertEquals("u1", salvo.id());
        assertEquals("Maria Souza", salvo.nome());
        assertEquals("1933334444", salvo.telefone());
        assertEquals("maria@email.com", salvo.email());
        assertEquals("hash-secreto", salvo.senhaHash());
        assertEquals(CRIADO_EM, salvo.criadoEm());

        assertEquals("Maria Souza", perfil.usuario().nome());
        assertEquals("1933334444", perfil.usuario().telefone());
    }

    // TESTE 5 - Espacos nas pontas do nome sao removidos
    @Test
    void deveRemoverEspacosDoNome() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.of(criarUsuario()));
        when(usuarioRepository.save(any(Usuario.class)))
                .thenAnswer(chamada -> chamada.getArgument(0));
        when(propriedadeRepository.findByUsuarioId("u1"))
                .thenReturn(List.of());

        perfilService.atualizar(
                "u1",
                new AtualizacaoPerfilRequest("  Maria Souza  ", "19999999999")
        );

        ArgumentCaptor<Usuario> captor =
                ArgumentCaptor.forClass(Usuario.class);
        verify(usuarioRepository).save(captor.capture());

        assertEquals("Maria Souza", captor.getValue().nome());
    }

    // TESTE 6 - Nome curto demais depois de remover os espacos
    @Test
    void deveRecusarNomeCurtoDepoisDeRemoverEspacos() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.of(criarUsuario()));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> perfilService.atualizar(
                        "u1",
                        new AtualizacaoPerfilRequest("  ab  ", "19999999999"))
        );

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verify(usuarioRepository, never()).save(any());
    }

    // TESTE 7 - Atualizar com usuario inexistente nao grava nada
    @Test
    void naoDeveAtualizarUsuarioInexistente() {

        when(usuarioRepository.findById("u1"))
                .thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> perfilService.atualizar(
                        "u1",
                        new AtualizacaoPerfilRequest("Maria Souza", "19999999999"))
        );

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatusCode());
        verify(usuarioRepository, never()).save(any());
    }
}
