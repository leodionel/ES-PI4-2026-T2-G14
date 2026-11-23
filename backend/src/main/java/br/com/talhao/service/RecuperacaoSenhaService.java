package br.com.talhao.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;

import jakarta.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.RecuperacaoSenhaResponse;
import br.com.talhao.model.RecuperacaoSenha;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

// Recuperacao de senha (RF03) em modo simulado: o sistema gera um codigo
// de 6 digitos, mas nao envia e-mail. O codigo aparece no log do backend e,
// se app.recuperacao.exibir-codigo estiver ligado, tambem na resposta.
@Service
public class RecuperacaoSenhaService {

    private static final Logger LOG =
            LoggerFactory.getLogger(RecuperacaoSenhaService.class);

    private static final Duration VALIDADE = Duration.ofMinutes(15);
    private static final int MAX_TENTATIVAS = 5;

    private static final String MENSAGEM_PEDIDO =
            "Se o e-mail estiver cadastrado, um código de recuperação foi gerado.";

    private static final String MENSAGEM_CODIGO_INVALIDO =
            "Código inválido ou expirado. Peça um novo código.";

    private final SecureRandom aleatorio = new SecureRandom();

    private final UsuarioRepository usuarioRepository;
    private final MongoTemplate mongoTemplate;
    private final PasswordEncoder passwordEncoder;
    private final boolean exibirCodigo;

    // Hash de um codigo qualquer, para gastar o mesmo tempo quando o
    // e-mail ou o pedido nao existem
    private String hashFalso;

    public RecuperacaoSenhaService(
            UsuarioRepository usuarioRepository,
            MongoTemplate mongoTemplate,
            PasswordEncoder passwordEncoder,
            @Value("${app.recuperacao.exibir-codigo:true}")
            boolean exibirCodigo) {

        this.usuarioRepository = usuarioRepository;
        this.mongoTemplate = mongoTemplate;
        this.passwordEncoder = passwordEncoder;
        this.exibirCodigo = exibirCodigo;
    }

    @PostConstruct
    void prepararHashFalso() {
        this.hashFalso = passwordEncoder.encode("000000");
    }

    // PEDIR O CODIGO. A resposta e igual para e-mail cadastrado ou nao,
    // para nao revelar quais e-mails existem.
    public RecuperacaoSenhaResponse solicitar(String emailInformado) {

        String email = normalizar(emailInformado);
        String codigo = gerarCodigo();

        Optional<Usuario> usuario = usuarioRepository.findByEmail(email);

        // O hash e calculado nos dois casos (mesmo tempo de resposta)
        String hash = passwordEncoder.encode(codigo);

        if (usuario.isPresent()) {

            // Um pedido por usuario: o novo substitui o anterior
            mongoTemplate.upsert(
                    new Query(Criteria.where("usuarioId")
                            .is(usuario.get().id())),
                    new Update()
                            .set("codigoHash", hash)
                            .set("expiraEm", Instant.now().plus(VALIDADE))
                            .set("tentativas", 0),
                    RecuperacaoSenha.class
            );

            LOG.info("[RECUPERACAO SIMULADA] Codigo para {}: {} (valido por {} min)",
                    email, codigo, VALIDADE.toMinutes());
        }

        return new RecuperacaoSenhaResponse(
                MENSAGEM_PEDIDO,
                exibirCodigo ? codigo : null
        );
    }

    // TROCAR A SENHA com o codigo recebido
    public void redefinir(
            String emailInformado,
            String codigo,
            String novaSenha) {

        String email = normalizar(emailInformado);

        Optional<Usuario> usuario = usuarioRepository.findByEmail(email);

        RecuperacaoSenha pedido = usuario.isEmpty()
                ? null
                : consumirTentativa(usuario.get().id());

        if (pedido == null) {
            // Mesmo tempo de uma conferencia real
            passwordEncoder.matches(codigo, hashFalso);
            throw codigoInvalido();
        }

        if (!passwordEncoder.matches(codigo, pedido.codigoHash())) {
            throw codigoInvalido();
        }

        Usuario atual = usuario.get();

        usuarioRepository.save(new Usuario(
                atual.id(),
                atual.nome(),
                atual.email(),
                atual.telefone(),
                passwordEncoder.encode(novaSenha),
                atual.criadoEm()
        ));

        // O codigo vale uma vez so
        mongoTemplate.remove(
                new Query(Criteria.where("usuarioId").is(atual.id())),
                RecuperacaoSenha.class
        );
    }

    // Conta a tentativa ANTES de conferir o codigo, numa unica operacao
    // do Mongo. Pedidos simultaneos nao conseguem passar do limite.
    // Devolve null se nao ha pedido, se expirou ou se acabaram as tentativas.
    private RecuperacaoSenha consumirTentativa(String usuarioId) {

        return mongoTemplate.findAndModify(
                new Query(Criteria.where("usuarioId").is(usuarioId)
                        .and("expiraEm").gt(Instant.now())
                        .and("tentativas").lt(MAX_TENTATIVAS)),
                new Update().inc("tentativas", 1),
                FindAndModifyOptions.options().returnNew(true),
                RecuperacaoSenha.class
        );
    }

    private ResponseStatusException codigoInvalido() {
        return new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                MENSAGEM_CODIGO_INVALIDO
        );
    }

    private String gerarCodigo() {
        return String.format("%06d", aleatorio.nextInt(1_000_000));
    }

    private String normalizar(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
