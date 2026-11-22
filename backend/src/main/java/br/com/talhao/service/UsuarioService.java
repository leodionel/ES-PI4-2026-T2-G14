// #Matheus Azevedo Teixeira, RA:25014927

package br.com.talhao.service;

import java.time.Instant;
import java.util.Locale;

import jakarta.annotation.PostConstruct;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CadastroUsuarioRequest;
import br.com.talhao.dto.LoginRequest;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

// Responsavel pelas regras de negocio dos usuarios
@Service
public class UsuarioService {

    private static final int NOME_MINIMO = 3;

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    // Hash de uma senha qualquer, usado so para gastar o mesmo tempo de
    // uma verificacao real quando o e-mail nao existe
    private String hashFalso;

    // Recebe as dependencias pelo construtor
    public UsuarioService(
            UsuarioRepository usuarioRepository,
            PasswordEncoder passwordEncoder) {

        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // Calculado uma vez na subida, com o mesmo custo do BCrypt das senhas
    @PostConstruct
    void prepararHashFalso() {
        this.hashFalso = passwordEncoder.encode("senha-que-ninguem-usa");
    }

    // Realiza o cadastro de um novo usuario
    public UsuarioResponse cadastrar(CadastroUsuarioRequest dados) {

        // A validacao do DTO conta os espacos das pontas; aqui conta so o nome
        String nome = dados.nome().trim();

        if (nome.length() < NOME_MINIMO) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "O nome deve ter pelo menos " + NOME_MINIMO
                            + " caracteres"
            );
        }

        // Remove espacos e padroniza o email em minusculo
        String email = dados.email()
                .trim()
                .toLowerCase(Locale.ROOT);

        // Impede o cadastro de um email ja utilizado
        if (usuarioRepository.existsByEmail(email)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "E-mail já cadastrado"
            );
        }

        // Protege a senha utilizando BCrypt
        String senhaHash = passwordEncoder.encode(dados.senha());

        // Cria o usuario com os dados recebidos
        Usuario usuario = new Usuario(
                null,
                nome,
                email,
                dados.telefone(),
                senhaHash,
                Instant.now()
        );

        try {
            // Salva o usuario no MongoDB
            Usuario usuarioSalvo = usuarioRepository.save(usuario);

            // Retorna os dados permitidos, sem a senha
            return new UsuarioResponse(
                    usuarioSalvo.id(),
                    usuarioSalvo.nome(),
                    usuarioSalvo.email(),
                    usuarioSalvo.telefone(),
                    usuarioSalvo.criadoEm()
            );

        } catch (DuplicateKeyException erro) {

            // Trata cadastros simultaneos com o mesmo email
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "E-mail já cadastrado",
                    erro
            );
        }
    }

    // Verifica as credenciais de login do usuario
    public UsuarioResponse login(LoginRequest dados) {

        // Padroniza o email recebido
        String email = dados.email()
                .trim()
                .toLowerCase(Locale.ROOT);

        // Busca o usuario no MongoDB pelo email
        Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);

        // E-mail inexistente tambem confere um hash: sem isso a resposta
        // seria bem mais rapida e mostraria quais e-mails tem conta
        if (usuario == null) {
            passwordEncoder.matches(dados.senha(), hashFalso);

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "E-mail ou senha inválidos"
            );
        }

        boolean senhaCorreta = passwordEncoder.matches(
                dados.senha(),
                usuario.senhaHash()
        );

        // Impede o login quando a senha estiver incorreta
        if (!senhaCorreta) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "E-mail ou senha inválidos"
            );
        }

        // Retorna os dados do usuario sem expor a senha
        return new UsuarioResponse(
                usuario.id(),
                usuario.nome(),
                usuario.email(),
                usuario.telefone(),
                usuario.criadoEm()
        );
    }
}
