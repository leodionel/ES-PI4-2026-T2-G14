package br.com.talhao.service;

import java.time.Instant;
import java.util.Optional;

import org.bson.Document;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.data.mongodb.core.query.UpdateDefinition;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.RecuperacaoSenhaResponse;
import br.com.talhao.model.RecuperacaoSenha;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

// Testa a recuperacao de senha simulada sem MongoDB real
@ExtendWith(MockitoExtension.class)
class RecuperacaoSenhaServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private MongoTemplate mongoTemplate;

    @Mock
    private PasswordEncoder passwordEncoder;

    private RecuperacaoSenhaService servico;

    private final Usuario joao = new Usuario(
            "u1", "Joao", "joao@email.com", "19999999999",
            "senhaAntiga", Instant.parse("2026-01-10T10:00:00Z"));

    @BeforeEach
    void preparar() {
        servico = new RecuperacaoSenhaService(
                usuarioRepository, mongoTemplate, passwordEncoder, true);
    }

    private RecuperacaoSenha pedido(int tentativas) {
        return new RecuperacaoSenha(
                "r1", "u1", "hashDoCodigo",
                Instant.now().plusSeconds(600), tentativas);
    }

    private void simularPedidoAtivo(RecuperacaoSenha pedido) {
        when(mongoTemplate.findAndModify(
                any(Query.class),
                any(UpdateDefinition.class),
                any(FindAndModifyOptions.class),
                eq(RecuperacaoSenha.class)))
                .thenReturn(pedido);
    }

    // TESTE 1 - E-mail cadastrado: guarda so o hash do codigo
    @Test
    void deveGerarCodigoEGuardarApenasOHash() {

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(joao));
        when(passwordEncoder.encode(anyString())).thenReturn("hashDoCodigo");

        RecuperacaoSenhaResponse resposta =
                servico.solicitar("  JOAO@email.com ");

        assertTrue(resposta.codigoSimulado().matches("\\d{6}"));

        ArgumentCaptor<Update> update = ArgumentCaptor.forClass(Update.class);
        verify(mongoTemplate).upsert(
                any(Query.class), update.capture(),
                eq(RecuperacaoSenha.class));

        Document gravado = update.getValue()
                .getUpdateObject().get("$set", Document.class);

        assertEquals("hashDoCodigo", gravado.get("codigoHash"));
        assertEquals(0, gravado.get("tentativas"));
        assertNotEquals(resposta.codigoSimulado(), gravado.get("codigoHash"));
    }

    // TESTE 2 - E-mail inexistente: mesma resposta, nada e gravado
    @Test
    void naoDeveRevelarSeOEmailExiste() {

        when(usuarioRepository.findByEmail("naoexiste@email.com"))
                .thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hash");

        RecuperacaoSenhaResponse resposta =
                servico.solicitar("naoexiste@email.com");

        assertNotNull(resposta.mensagem());
        assertTrue(resposta.codigoSimulado().matches("\\d{6}"));
        verifyNoInteractions(mongoTemplate);
    }

    // TESTE 3 - Com a exibicao desligada o codigo nao vai na resposta
    @Test
    void naoDeveDevolverOCodigoComAExibicaoDesligada() {

        RecuperacaoSenhaService semExibir = new RecuperacaoSenhaService(
                usuarioRepository, mongoTemplate, passwordEncoder, false);

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(joao));
        when(passwordEncoder.encode(anyString())).thenReturn("hash");

        RecuperacaoSenhaResponse resposta =
                semExibir.solicitar("joao@email.com");

        assertNull(resposta.codigoSimulado());
    }

    // TESTE 4 - Codigo certo troca a senha e apaga o pedido
    @Test
    void deveTrocarASenhaComOCodigoCerto() {

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(joao));
        simularPedidoAtivo(pedido(1));
        when(passwordEncoder.matches("123456", "hashDoCodigo"))
                .thenReturn(true);
        when(passwordEncoder.encode("NovaSenha1")).thenReturn("hashNovo");

        servico.redefinir("JOAO@email.com", "123456", "NovaSenha1");

        verify(usuarioRepository).save(argThat(usuario ->
                usuario.id().equals("u1")
                && usuario.senhaHash().equals("hashNovo")
                && usuario.email().equals("joao@email.com")
                && usuario.criadoEm().equals(joao.criadoEm())));
        verify(mongoTemplate).remove(any(Query.class),
                eq(RecuperacaoSenha.class));
    }

    // TESTE 5 - Codigo errado: 400, senha igual e pedido mantido
    @Test
    void deveRecusarCodigoErrado() {

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(joao));
        simularPedidoAtivo(pedido(1));
        when(passwordEncoder.matches("999999", "hashDoCodigo"))
                .thenReturn(false);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> servico.redefinir(
                        "joao@email.com", "999999", "NovaSenha1"));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verify(usuarioRepository, never()).save(any(Usuario.class));
        verify(mongoTemplate, never()).remove(any(Query.class),
                eq(RecuperacaoSenha.class));
    }

    // TESTE 6 - Sem pedido valido (nao existe, expirou ou acabaram as
    // tentativas): 400, com a mesma mensagem do codigo errado
    @Test
    void deveRecusarQuandoNaoHaPedidoValido() {

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(joao));
        simularPedidoAtivo(null);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> servico.redefinir(
                        "joao@email.com", "123456", "NovaSenha1"));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        // Confere um hash mesmo assim, para o tempo ser o mesmo
        verify(passwordEncoder).matches(eq("123456"), any());
        verify(usuarioRepository, never()).save(any(Usuario.class));
    }

    // TESTE 7 - E-mail inexistente na troca: 400 sem consultar pedidos
    @Test
    void deveRecusarEmailInexistenteNaTroca() {

        when(usuarioRepository.findByEmail("naoexiste@email.com"))
                .thenReturn(Optional.empty());

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> servico.redefinir(
                        "naoexiste@email.com", "123456", "NovaSenha1"));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verifyNoInteractions(mongoTemplate);
        verify(usuarioRepository, never()).save(any(Usuario.class));
    }
}
