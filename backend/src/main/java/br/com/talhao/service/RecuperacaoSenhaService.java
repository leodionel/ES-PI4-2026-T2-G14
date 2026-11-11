package br.com.talhao.service;

import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

// Coordena a solicitação e a redefinição da senha.
@Service
public class RecuperacaoSenhaService {

    private final UsuarioRepository usuarioRepository;
    private final TokenRecuperacaoSenhaService tokenService;
    private final EmailRecuperacaoSenhaService emailService;
    private final PasswordEncoder passwordEncoder;

    public RecuperacaoSenhaService(
            UsuarioRepository usuarioRepository,
            TokenRecuperacaoSenhaService tokenService,
            EmailRecuperacaoSenhaService emailService,
            PasswordEncoder passwordEncoder) {

        this.usuarioRepository = usuarioRepository;
        this.tokenService = tokenService;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
    }

    // Solicita o envio de um link de recuperação.
    public void solicitarRecuperacao(String email) {

        // Padroniza o endereço de e-mail.
        String emailNormalizado = email
                .trim()
                .toLowerCase(Locale.ROOT);

        // Procura o usuário cadastrado.
        var usuarioOptional =
                usuarioRepository.findByEmail(emailNormalizado);

        // Não revela se o e-mail existe no sistema.
        if (usuarioOptional.isEmpty()) {
            return;
        }

        Usuario usuario = usuarioOptional.get();

        // Gera o token temporário e salva seu hash.
        String token = tokenService.gerarToken(usuario.id());

        // Solicita o envio do link ao serviço de e-mail.
        // Esse serviço será criado no próximo passo.
        emailService.enviarLinkRecuperacao(
                usuario.email(),
                token
        );
    }

    // Redefine a senha utilizando um token válido.
    public void redefinirSenha(String token, String novaSenha) {

        // Mantém a mesma regra de tamanho do cadastro.
        if (novaSenha == null
                || novaSenha.length() < 8
                || novaSenha.length() > 128) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A senha deve ter entre 8 e 128 caracteres."
            );
        }

        // Valida o token e o consome uma única vez.
        String usuarioId = tokenService.consumirToken(token);

        // Localiza o usuário associado ao token.
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Link de recuperação inválido ou expirado."
                ));

        // Gera o hash BCrypt da nova senha.
        String novoHash = passwordEncoder.encode(novaSenha);

        // Como Usuario é um record, criamos uma nova
        // instância preservando os dados existentes.
        Usuario usuarioAtualizado = new Usuario(
                usuario.id(),
                usuario.nome(),
                usuario.email(),
                usuario.telefone(),
                novoHash,
                usuario.criadoEm()
        );

        // Atualiza a senha no MongoDB.
        usuarioRepository.save(usuarioAtualizado);
    }
}
