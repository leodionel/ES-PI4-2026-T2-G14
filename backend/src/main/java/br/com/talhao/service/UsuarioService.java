
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

@Service
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioService(
            UsuarioRepository usuarioRepository,
            PasswordEncoder passwordEncoder) {

        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // CADASTRAR USUARIO
    public UsuarioResponse cadastrar(CadastroUsuarioRequest dados) {

        String email = dados.email()
                .trim()
                .toLowerCase(Locale.ROOT);

        if (usuarioRepository.existsByEmail(email)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "E-mail já cadastrado"
            );
        }

        String senhaHash = passwordEncoder.encode(dados.senha());

        Usuario usuario = new Usuario(
                null,
                dados.nome().trim(),
                email,
                dados.telefone(),
                senhaHash,
                Instant.now()
        );

        try {
            Usuario usuarioSalvo = usuarioRepository.save(usuario);

            return converterParaResponse(usuarioSalvo);

        } catch (DuplicateKeyException erro) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "E-mail já cadastrado",
                    erro
            );
        }
    }

    // LOGIN
    public UsuarioResponse login(LoginRequest dados) {

        String email = dados.email()
                .trim()
                .toLowerCase(Locale.ROOT);

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "E-mail ou senha inválidos"
                ));

        boolean senhaCorreta = passwordEncoder.matches(
                dados.senha(),
                usuario.senhaHash()
        );

        if (!senhaCorreta) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "E-mail ou senha inválidos"
            );
        }

        return converterParaResponse(usuario);
    }

    // BUSCAR PERFIL DO USUARIO LOGADO
    public UsuarioResponse buscarPerfil(String usuarioId) {

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Usuário não encontrado"
                ));

        return converterParaResponse(usuario);
    }

    // CONVERTER USUARIO PARA RESPOSTA SEM SENHA
    private UsuarioResponse converterParaResponse(Usuario usuario) {

        return new UsuarioResponse(
                usuario.id(),
                usuario.nome(),
                usuario.email(),
                usuario.telefone(),
                usuario.criadoEm()
        );
    }
}
