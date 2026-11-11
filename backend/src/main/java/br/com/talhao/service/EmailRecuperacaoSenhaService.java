
package br.com.talhao.service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

// Responsável pelo envio real de e-mails de recuperação.
@Service
public class EmailRecuperacaoSenhaService {

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final String remetente;
    private final String urlRecuperacao;

    public EmailRecuperacaoSenhaService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.mail.remetente:}") String remetente,
            @Value("${app.recuperacao.url:}") String urlRecuperacao) {

        this.mailSenderProvider = mailSenderProvider;
        this.remetente = remetente;
        this.urlRecuperacao = urlRecuperacao;
    }

    // Envia um link de recuperação ao e-mail cadastrado.
    public void enviarLinkRecuperacao(
            String destinatario,
            String token) {

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();

        // Não simula o envio quando o SMTP não está configurado.
        if (mailSender == null) {
            throw new IllegalStateException(
                    "O serviço SMTP não está configurado."
            );
        }

        if (remetente.isBlank() || urlRecuperacao.isBlank()) {
            throw new IllegalStateException(
                    "Remetente ou URL de recuperação não configurados."
            );
        }

        // O token fica na URL, sem ser armazenado no banco em texto puro.
        String separador = urlRecuperacao.contains("?") ? "&" : "?";

        String link = urlRecuperacao
                + separador
                + "token="
                + URLEncoder.encode(
                        token,
                        StandardCharsets.UTF_8
                );

        // Prepara a mensagem.
        SimpleMailMessage mensagem = new SimpleMailMessage();

        mensagem.setFrom(remetente);
        mensagem.setTo(destinatario);

        mensagem.setSubject(
                "Recuperação de senha - Prontuário Digital do Talhão"
        );

        mensagem.setText(
                "Olá!\n\n"
                + "Recebemos uma solicitação para redefinir sua senha.\n\n"
                + "Acesse o link abaixo:\n\n"
                + link
                + "\n\n"
                + "Este link é válido por 15 minutos "
                + "e pode ser utilizado uma única vez.\n\n"
                + "Se você não solicitou a recuperação, "
                + "ignore este e-mail.\n\n"
                + "Equipe Prontuário Digital do Talhão"
        );

        // Envio real pelo servidor SMTP.
        mailSender.send(mensagem);
    }
}
