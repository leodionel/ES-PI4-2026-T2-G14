
package br.com.talhao.service;

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

import br.com.talhao.model.Propriedade;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

// Testes automatizados das regras de negocio das propriedades
@ExtendWith(MockitoExtension.class)
class PropriedadeServiceTest {

    // Simula o repositorio de propriedades
    @Mock
    private PropriedadeRepository propriedadeRepository;

    // Simula o repositorio de usuarios
    @Mock
    private UsuarioRepository usuarioRepository;

    // Service real que sera testado
    @InjectMocks
    private PropriedadeService propriedadeService;

    // Cria uma propriedade ficticia para os testes
    private Propriedade criarPropriedade() {

        return new Propriedade(
                "prop-1",
                "usuario-1",
                "Fazenda Teste",
                "Campinas - SP"
        );
    }

    // TESTE 1
    // Deve cadastrar uma propriedade para um usuario existente
    @Test
    void deveCadastrarPropriedade() {

        when(usuarioRepository.existsById("usuario-1"))
                .thenReturn(true);

        when(propriedadeRepository.save(any(Propriedade.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        Propriedade resultado = propriedadeService.cadastrar(
                "usuario-1",
                "  Fazenda Teste  ",
                "  Campinas - SP  "
        );

        assertNotNull(resultado);
        assertEquals("usuario-1", resultado.usuarioId());
        assertEquals("Fazenda Teste", resultado.nome());
        assertEquals("Campinas - SP", resultado.localizacao());

        // O ID sera gerado pelo MongoDB no cadastro real
        assertNull(resultado.id());

        verify(usuarioRepository).existsById("usuario-1");
        verify(propriedadeRepository).save(any(Propriedade.class));
    }

    // TESTE 2
    // Nao permitir cadastro para usuario inexistente
    @Test
    void deveBloquearCadastroDeUsuarioInexistente() {

        when(usuarioRepository.existsById("usuario-inexistente"))
                .thenReturn(false);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.cadastrar(
                        "usuario-inexistente",
                        "Fazenda Teste",
                        "Campinas - SP"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());

        verifyNoInteractions(propriedadeRepository);
    }

    // TESTE 3
    // Nao permitir cadastro com nome vazio
    @Test
    void deveBloquearCadastroComNomeVazio() {

        when(usuarioRepository.existsById("usuario-1"))
                .thenReturn(true);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.cadastrar(
                        "usuario-1",
                        "   ",
                        "Campinas - SP"
                )
        );

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());

        verifyNoInteractions(propriedadeRepository);
    }

    // TESTE 4
    // Nao permitir cadastro com localizacao vazia
    @Test
    void deveBloquearCadastroComLocalizacaoVazia() {

        when(usuarioRepository.existsById("usuario-1"))
                .thenReturn(true);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.cadastrar(
                        "usuario-1",
                        "Fazenda Teste",
                        ""
                )
        );

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());

        verifyNoInteractions(propriedadeRepository);
    }

    // TESTE 5
    // Listar somente as propriedades do usuario
    @Test
    void deveListarPropriedadesDoUsuario() {

        when(usuarioRepository.existsById("usuario-1"))
                .thenReturn(true);

        List<Propriedade> propriedades =
                List.of(criarPropriedade());

        when(propriedadeRepository.findByUsuarioId("usuario-1"))
                .thenReturn(propriedades);

        List<Propriedade> resultado =
                propriedadeService.listarPorUsuario("usuario-1");

        assertEquals(1, resultado.size());
        assertEquals("prop-1", resultado.get(0).id());
        assertEquals("usuario-1", resultado.get(0).usuarioId());

        // Confirma que o repositorio recebeu o ID correto
        verify(propriedadeRepository).findByUsuarioId("usuario-1");
    }

    // TESTE 6
    // Buscar uma propriedade pertencente ao usuario
    @Test
    void deveBuscarPropriedadePorId() {

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-1"
        )).thenReturn(Optional.of(criarPropriedade()));

        Propriedade resultado = propriedadeService.buscarPorId(
                "prop-1",
                "usuario-1"
        );

        assertEquals("prop-1", resultado.id());
        assertEquals("usuario-1", resultado.usuarioId());
        assertEquals("Fazenda Teste", resultado.nome());

        verify(propriedadeRepository).findByIdAndUsuarioId(
                "prop-1",
                "usuario-1"
        );
    }

    // TESTE 7
    // Impedir acesso a propriedade de outro usuario
    @Test
    void deveBloquearAcessoAPropriedadeDeOutroUsuario() {

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-2"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.buscarPorId(
                        "prop-1",
                        "usuario-2"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
    }

    // TESTE 8
    // Atualizar propriedade mantendo ID e proprietario originais
    @Test
    void deveAtualizarPropriedade() {

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-1"
        )).thenReturn(Optional.of(criarPropriedade()));

        when(propriedadeRepository.save(any(Propriedade.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        Propriedade resultado = propriedadeService.atualizar(
                "prop-1",
                "usuario-1",
                "  Fazenda Atualizada  ",
                "  Itapira - SP  "
        );

        assertEquals("prop-1", resultado.id());
        assertEquals("usuario-1", resultado.usuarioId());
        assertEquals("Fazenda Atualizada", resultado.nome());
        assertEquals("Itapira - SP", resultado.localizacao());

        ArgumentCaptor<Propriedade> captor =
                ArgumentCaptor.forClass(Propriedade.class);

        verify(propriedadeRepository).save(captor.capture());

        Propriedade salva = captor.getValue();

        assertEquals("prop-1", salva.id());
        assertEquals("usuario-1", salva.usuarioId());
    }

    // TESTE 9
    // Impedir atualizacao de propriedade de outro usuario
    @Test
    void deveBloquearAtualizacaoDeOutroUsuario() {

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-2"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.atualizar(
                        "prop-1",
                        "usuario-2",
                        "Nome Alterado",
                        "Outra Localizacao"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());

        verify(propriedadeRepository, never())
                .save(any(Propriedade.class));
    }

    // TESTE 10
    // Excluir uma propriedade pertencente ao usuario
    @Test
    void deveExcluirPropriedade() {

        Propriedade propriedade = criarPropriedade();

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-1"
        )).thenReturn(Optional.of(propriedade));

        propriedadeService.excluir(
                "prop-1",
                "usuario-1"
        );

        verify(propriedadeRepository).delete(propriedade);
    }

    // TESTE 11
    // Impedir exclusao de propriedade de outro usuario
    @Test
    void deveBloquearExclusaoDeOutroUsuario() {

        when(propriedadeRepository.findByIdAndUsuarioId(
                "prop-1",
                "usuario-2"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.excluir(
                        "prop-1",
                        "usuario-2"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());

        verify(propriedadeRepository, never())
                .delete(any(Propriedade.class));
    }

    // TESTE 12
    // Impedir consultas com identificador vazio
    @Test
    void deveBloquearBuscaComIdVazio() {

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> propriedadeService.buscarPorId(
                        "   ",
                        "usuario-1"
                )
        );

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());

        verifyNoInteractions(propriedadeRepository);
    }
}
