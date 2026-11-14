
package br.com.talhao.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CadastroAnaliseSoloRequest;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.AnaliseSoloRepository;
import br.com.talhao.repository.TalhaoRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

// Testa as regras de negocio das analises de solo
@ExtendWith(MockitoExtension.class)
class AnaliseSoloServiceTest {

    // Simula o acesso ao MongoDB
    @Mock
    private AnaliseSoloRepository analiseSoloRepository;

    // Simula a verificacao das propriedades do usuario
    @Mock
    private PropriedadeService propriedadeService;

    // Simula o acesso aos talhoes
    @Mock
    private TalhaoRepository talhaoRepository;

    // Cria o Service com as dependencias simuladas
    @InjectMocks
    private AnaliseSoloService analiseSoloService;

    // Cria dados validos para os testes
    private CadastroAnaliseSoloRequest criarDados() {
        return new CadastroAnaliseSoloRequest(
                "propriedade-1",
                "talhao-1",
                LocalDate.of(2026, 10, 20),
                5.8,
                12.0,
                4.0,
                60.0,
                "Amostra de teste"
        );
    }

    // Simula uma analise existente no banco
    private AnaliseSolo criarAnalise() {
        return new AnaliseSolo(
                "analise-1",
                "usuario-1",
                "propriedade-1",
                "talhao-1",
                LocalDate.of(2026, 10, 20),
                5.8,
                12.0,
                4.0,
                60.0,
                "Amostra de teste"
        );
    }

    // Simula um talhao existente na propriedade
    private void simularTalhaoExistente() {
        when(talhaoRepository.findByIdAndPropriedadeId(
                "talhao-1",
                "propriedade-1"
        )).thenReturn(Optional.of(new Talhao(
                "talhao-1",
                "propriedade-1",
                "Talhao 01",
                10.0,
                Instant.now(),
                List.of()
        )));
    }

    // TESTE 1 - Cadastrar analise de solo
    @Test
    void deveCadastrarAnaliseSolo() {

        CadastroAnaliseSoloRequest dados = criarDados();

        simularTalhaoExistente();

        // Simula o MongoDB salvando a analise
        when(analiseSoloRepository.save(any(AnaliseSolo.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        AnaliseSolo resultado =
                analiseSoloService.cadastrar("usuario-1", dados);

        assertNotNull(resultado);
        assertEquals("usuario-1", resultado.usuarioId());
        assertEquals("propriedade-1", resultado.propriedadeId());
        assertEquals("talhao-1", resultado.talhaoId());
        assertEquals(5.8, resultado.ph());
        assertEquals(60.0, resultado.saturacaoBases());

        // Verifica se o acesso a propriedade foi conferido
        verify(propriedadeService).buscarPorId(
                "propriedade-1",
                "usuario-1"
        );

        verify(analiseSoloRepository).save(any(AnaliseSolo.class));
    }

    // TESTE 2 - Impedir cadastro em propriedade de outro usuario
    @Test
    void deveRecusarCadastroEmPropriedadeDeOutroUsuario() {

        CadastroAnaliseSoloRequest dados = criarDados();

        // Simula uma propriedade inacessivel ao usuario
        doThrow(new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "Propriedade nao encontrada"
        )).when(propriedadeService).buscarPorId(
                "propriedade-1",
                "usuario-1"
        );

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> analiseSoloService.cadastrar("usuario-1", dados)
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());

        // Nenhuma analise pode ser salva
        verify(analiseSoloRepository, never())
                .save(any(AnaliseSolo.class));
    }

    // TESTE 3 - Listar analises do usuario
    @Test
    void deveListarAnalisesDoUsuario() {

        when(analiseSoloRepository
                .findByUsuarioIdOrderByDataColetaDesc("usuario-1"))
                .thenReturn(List.of(criarAnalise()));

        List<AnaliseSolo> resultado =
                analiseSoloService.listarPorUsuario("usuario-1");

        assertEquals(1, resultado.size());
        assertEquals("usuario-1", resultado.get(0).usuarioId());

        verify(analiseSoloRepository)
                .findByUsuarioIdOrderByDataColetaDesc("usuario-1");
    }

    // TESTE 4 - Listar historico de um talhao
    @Test
    void deveListarAnalisesPorTalhao() {

        when(analiseSoloRepository
                .findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                        "usuario-1",
                        "propriedade-1",
                        "talhao-1"
                ))
                .thenReturn(List.of(criarAnalise()));

        List<AnaliseSolo> resultado =
                analiseSoloService.listarPorTalhao(
                        "usuario-1",
                        "propriedade-1",
                        "talhao-1"
                );

        assertEquals(1, resultado.size());
        assertEquals("talhao-1", resultado.get(0).talhaoId());

        verify(propriedadeService).buscarPorId(
                "propriedade-1",
                "usuario-1"
        );
    }

    // TESTE 5 - Bloquear consulta de analise de outro usuario
    @Test
    void deveRecusarAcessoAAnaliseDeOutroUsuario() {

        // O repository nao encontra uma analise
        // pertencente ao usuario informado
        when(analiseSoloRepository.findByIdAndUsuarioId(
                "analise-1",
                "usuario-2"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> analiseSoloService.buscarPorId(
                        "analise-1",
                        "usuario-2"
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
    }

    // TESTE 6 - Atualizar analise do proprio usuario
    @Test
    void deveAtualizarAnaliseSolo() {

        CadastroAnaliseSoloRequest dados = criarDados();

        simularTalhaoExistente();

        when(analiseSoloRepository.findByIdAndUsuarioId(
                "analise-1",
                "usuario-1"
        )).thenReturn(Optional.of(criarAnalise()));

        when(analiseSoloRepository.save(any(AnaliseSolo.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        AnaliseSolo resultado = analiseSoloService.atualizar(
                "analise-1",
                "usuario-1",
                dados
        );

        assertEquals("analise-1", resultado.id());
        assertEquals("usuario-1", resultado.usuarioId());
        assertEquals(5.8, resultado.ph());

        verify(propriedadeService).buscarPorId(
                "propriedade-1",
                "usuario-1"
        );

        verify(analiseSoloRepository).save(any(AnaliseSolo.class));
    }

    // TESTE 7 - Excluir analise do proprio usuario
    @Test
    void deveExcluirAnaliseSolo() {

        AnaliseSolo analise = criarAnalise();

        when(analiseSoloRepository.findByIdAndUsuarioId(
                "analise-1",
                "usuario-1"
        )).thenReturn(Optional.of(analise));

        analiseSoloService.excluir(
                "analise-1",
                "usuario-1"
        );

        // Confirma que o MongoDB recebeu a exclusao
        verify(analiseSoloRepository).delete(analise);
    }

    // TESTE 8 - Nao cadastrar analise em talhao inexistente
    // ou que pertence a outra propriedade
    @Test
    void deveRecusarCadastroEmTalhaoInexistente() {

        // O talhao nao e encontrado nessa propriedade
        when(talhaoRepository.findByIdAndPropriedadeId(
                "talhao-1",
                "propriedade-1"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> analiseSoloService.cadastrar(
                        "usuario-1",
                        criarDados()
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
        verify(analiseSoloRepository, never())
                .save(any(AnaliseSolo.class));
    }

    // TESTE 9 - Nao mover analise para um talhao invalido
    @Test
    void deveRecusarAtualizacaoParaTalhaoInexistente() {

        when(analiseSoloRepository.findByIdAndUsuarioId(
                "analise-1",
                "usuario-1"
        )).thenReturn(Optional.of(criarAnalise()));

        when(talhaoRepository.findByIdAndPropriedadeId(
                "talhao-1",
                "propriedade-1"
        )).thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> analiseSoloService.atualizar(
                        "analise-1",
                        "usuario-1",
                        criarDados()
                )
        );

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatusCode());
        verify(analiseSoloRepository, never())
                .save(any(AnaliseSolo.class));
    }
}
