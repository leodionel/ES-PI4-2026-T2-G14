
package br.com.talhao.service;

import java.time.Instant;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CadastroUsuarioRequest;
import br.com.talhao.dto.LoginRequest;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testa as regras de negocio sem utilizar um MongoDB real
@ExtendWith(MockitoExtension.class)
class UsuarioServiceTest {

    // Simula o repositorio de usuarios
    @Mock
    private UsuarioRepository usuarioRepository;

    // Simula a protecao e verificacao das senhas
    @Mock
    private PasswordEncoder passwordEncoder;

    // Service que sera testado
    @InjectMocks
    private UsuarioService usuarioService;

    // TESTE 1 - Login com credenciais corretas
    @Test
    void deveRealizarLoginComSucesso() {

        Usuario usuario = new Usuario(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                "senhaHash",
                Instant.now()
        );

        // Simula um usuario encontrado no MongoDB
        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(usuario));

        // Simula a verificacao de uma senha correta
        when(passwordEncoder.matches("Senha123", "senhaHash"))
                .thenReturn(true);

        LoginRequest dados = new LoginRequest(
                "JOAO@EMAIL.COM",
                "Senha123"
        );

        UsuarioResponse resposta = usuarioService.login(dados);

        // Confere os dados retornados
        assertEquals("123", resposta.id());
        assertEquals("Joao", resposta.nome());
        assertEquals("joao@email.com", resposta.email());
    }

    // TESTE 2 - Login com senha incorreta
    @Test
    void deveRecusarSenhaIncorreta() {

        Usuario usuario = new Usuario(
                "123",
                "Joao",
                "joao@email.com",
                "19999999999",
                "senhaHash",
                Instant.now()
        );

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(usuario));

        // Simula uma senha incorreta
        when(passwordEncoder.matches("SenhaErrada", "senhaHash"))
                .thenReturn(false);

        LoginRequest dados = new LoginRequest(
                "joao@email.com",
                "SenhaErrada"
        );

        // Espera um erro HTTP 401
        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> usuarioService.login(dados)
        );

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatusCode());
    }

    // TESTE 3 - Login com email nao cadastrado
    @Test
    void deveRecusarEmailNaoCadastrado() {

        // Simula um usuario inexistente
        when(usuarioRepository.findByEmail("inexistente@email.com"))
                .thenReturn(Optional.empty());

        LoginRequest dados = new LoginRequest(
                "inexistente@email.com",
                "Senha123"
        );

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> usuarioService.login(dados)
        );

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatusCode());

        // Nao verifica a senha se o usuario nao existir
        verifyNoInteractions(passwordEncoder);
    }

    // TESTE 4 - Cadastro realizado com sucesso
    @Test
    void deveCadastrarUsuarioComSucesso() {

        CadastroUsuarioRequest dados = new CadastroUsuarioRequest(
                "Joao",
                "JOAO@EMAIL.COM",
                "19999999999",
                "Senha123"
        );

        // Simula a criacao do hash da senha
        when(passwordEncoder.encode("Senha123"))
                .thenReturn("senhaHash");

        // Simula o salvamento do usuario no MongoDB
        when(usuarioRepository.save(any(Usuario.class)))
                .thenAnswer(invocacao -> {

                    Usuario usuario = invocacao.getArgument(0);

                    return new Usuario(
                            "123",
                            usuario.nome(),
                            usuario.email(),
                            usuario.telefone(),
                            usuario.senhaHash(),
                            usuario.criadoEm()
                    );
                });

        // Executa o cadastro
        UsuarioResponse resposta = usuarioService.cadastrar(dados);

        // Confere os dados retornados
        assertEquals("123", resposta.id());
        assertEquals("Joao", resposta.nome());
        assertEquals("joao@email.com", resposta.email());

        // Confere se a senha foi protegida
        verify(passwordEncoder).encode("Senha123");

        // Confere os dados enviados ao repositorio
        verify(usuarioRepository).save(argThat(usuario ->
                usuario.senhaHash().equals("senhaHash")
                && usuario.email().equals("joao@email.com")
        ));
    }

    // TESTE 5 - Impedir cadastro com email duplicado
    @Test
    void deveRecusarEmailJaCadastrado() {

        CadastroUsuarioRequest dados = new CadastroUsuarioRequest(
                "Joao",
                "JOAO@EMAIL.COM",
                "19999999999",
                "Senha123"
        );

        // Simula um email que ja existe no banco
        when(usuarioRepository.existsByEmail("joao@email.com"))
                .thenReturn(true);

        // Espera um erro ao tentar cadastrar
        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> usuarioService.cadastrar(dados)
        );

        // Confere o erro HTTP 409
        assertEquals(HttpStatus.CONFLICT, erro.getStatusCode());

        // Confere que o usuario nao foi salvo
        verify(usuarioRepository, never())
                .save(any(Usuario.class));

        // Nao gera hash se o email ja estiver cadastrado
        verifyNoInteractions(passwordEncoder);
    }
}
