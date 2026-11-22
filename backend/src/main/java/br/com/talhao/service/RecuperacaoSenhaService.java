package br.com.talhao.service;

import br.com.talhao.dto.RedefinirSenhaRequest;
import br.com.talhao.model.Usuario;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.*;
import org.springframework.http.HttpStatus;
import org.springframework.mail.*;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RecuperacaoSenhaService {
    private final MongoTemplate mongo;
    private final PasswordEncoder encoder;
    private final ObjectProvider<JavaMailSender> emailSender;
    private final String remetente;
    private final SecureRandom random = new SecureRandom();

    public RecuperacaoSenhaService(MongoTemplate mongo, PasswordEncoder encoder,
            ObjectProvider<JavaMailSender> emailSender,
            @Value("${app.recuperacao.remetente:}") String remetente) {
        this.mongo = mongo;
        this.encoder = encoder;
        this.emailSender = emailSender;
        this.remetente = remetente;
    }

    private Criteria conta(String email) {
        return Criteria.where("email").is(email.trim().toLowerCase(Locale.ROOT));
    }

    private String hash(String codigo) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(codigo.getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    public void solicitar(String email) {
        JavaMailSender sender = emailSender.getIfAvailable();
        if (sender == null || remetente.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE);
        }
        byte[] bytes = new byte[24];
        random.nextBytes(bytes);
        String codigo = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        String digest = hash(codigo);
        Instant agora = Instant.now();
        Criteria disponivel = new Criteria().orOperator(
                Criteria.where("recuperacao.reenvio").exists(false),
                Criteria.where("recuperacao.reenvio").lte(agora));
        Query query = Query.query(conta(email).andOperator(disponivel));
        Update atualizar = new Update().set("recuperacao.hash", digest)
                .set("recuperacao.expira", agora.plusSeconds(900))
                .set("recuperacao.reenvio", agora.plusSeconds(60));
        if (mongo.updateFirst(query, atualizar, Usuario.class).getModifiedCount() == 0) return;

        SimpleMailMessage mensagem = new SimpleMailMessage();
        mensagem.setFrom(remetente);
        mensagem.setTo(email.trim().toLowerCase(Locale.ROOT));
        mensagem.setSubject("Recuperação de senha do Prontuário Digital do Talhão");
        mensagem.setText("Cole este código no aplicativo em até 15 minutos:\n\n" + codigo);
        try {
            sender.send(mensagem);
        } catch (MailException e) {
            mongo.updateFirst(Query.query(conta(email).and("recuperacao.hash").is(digest)),
                    new Update().unset("recuperacao"), Usuario.class);
            // Mantém a mesma resposta pública para contas cadastradas e desconhecidas.
            org.slf4j.LoggerFactory.getLogger(getClass()).warn("Falha na entrega SMTP da recuperação de senha");
        }
    }

    public void redefinir(RedefinirSenhaRequest dados) {
        if (dados.novaSenha().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Senha excede 72 bytes.");
        }
        Query query = Query.query(conta(dados.email()).and("recuperacao.hash").is(hash(dados.codigo()))
                .and("recuperacao.expira").gt(Instant.now()));
        if (!mongo.exists(query, Usuario.class)) throw codigoInvalido();
        Update atualizar = new Update().set("senhaHash", encoder.encode(dados.novaSenha()))
                .unset("recuperacao");
        if (mongo.updateFirst(query, atualizar, Usuario.class).getModifiedCount() == 0) throw codigoInvalido();
    }

    private ResponseStatusException codigoInvalido() {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, "Código inválido ou expirado.");
    }
}
