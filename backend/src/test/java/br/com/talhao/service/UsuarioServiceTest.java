
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

import br.com.talhao.dto.LoginRequest;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

// Testes das regras de login sem usar MongoDB real
@ExtendWith(MockitoExtension.class)
class UsuarioServiceTest {

    // Simula o repositorio MongoDB
    @Mock
    private UsuarioRepository usuarioRepository;

    // Simula o verificador de senhas
    @Mock
    private PasswordEncoder passwordEncoder;

    // Service que sera testado
    @InjectMocks
    private UsuarioService usuarioService;

    // Teste 1: login com credenciais corretas
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

        when(usuarioRepository.findByEmail("joao@email.com"))
                .thenReturn(Optional.of(usuario));

        when(passwordEncoder.matches("Senha123", "senhaHash"))
                .thenReturn(true);

        LoginRequest dados = new LoginRequest(
                "JOAO@EMAIL.COM",
                "Senha123"
        );

        UsuarioResponse resposta = usuarioService.login(dados);

        assertEquals("123", resposta.id());
        assertEquals("Joao", resposta.nome());
        assertEquals("joao@email.com", resposta.email());
    }

    // Teste 2: senha incorreta
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

        when(passwordEncoder.matches("SenhaErrada", "senhaHash"))
                .thenReturn(false);

        LoginRequest dados = new LoginRequest(
                "joao@email.com",
                "SenhaErrada"
        );

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> usuarioService.login(dados)
        );

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatusCode());
    }

    // Teste 3: email nao cadastrado
    @Test
    void deveRecusarEmailNaoCadastrado() {

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

        // Nao verifica a senha de usuarios inexistentes
        verifyNoInteractions(passwordEncoder);
    }
}
