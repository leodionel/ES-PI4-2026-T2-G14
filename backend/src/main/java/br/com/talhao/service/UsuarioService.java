
package br.com.talhao.service;

import java.time.Instant;
import java.util.Locale;

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

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    // Recebe as dependencias pelo construtor
    public UsuarioService(
            UsuarioRepository usuarioRepository,
            PasswordEncoder passwordEncoder) {

        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // Realiza o cadastro de um novo usuario
    public UsuarioResponse cadastrar(CadastroUsuarioRequest dados) {

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
                dados.nome().trim(),
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
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "E-mail ou senha inválidos"
                ));

        // Compara a senha digitada com o hash salvo no banco
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
