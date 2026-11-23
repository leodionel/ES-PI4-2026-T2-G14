// Feito por Leonardo Dionel RA:25010092

import java.io.IOException;
import java.io.InvalidObjectException;
import java.io.ObjectInputStream;
import java.util.Set;
import java.util.regex.Pattern;

/*
 * Requisicao generica do aplicativo para a API REST.
 * O servidor encaminha o pedido ao Spring Boot e devolve a resposta.
 *
 * O corpo e enviado como bytes (JSON em UTF-8), o que evita problemas
 * de codificacao na serializacao de textos.
 */
public class PedidoRequisicao extends Comunicado {

    private static final long serialVersionUID = 1L;

    private static final Set<String> METODOS =
            Set.of("GET", "POST", "PUT", "DELETE");

    // Apenas rotas da API ou o status; sem "%" e sem ".." para
    // impedir que o pedido saia das rotas permitidas
    private static final Pattern CAMINHO = Pattern.compile(
            "/(status|api/[A-Za-z0-9._~/-]*(\\?[A-Za-z0-9._~&=-]*)?)"
    );

    private static final int MAX_CORPO = 512 * 1024;
    private static final int MAX_TOKEN = 4096;

    private final String metodo;
    private final String caminho;
    private final String token;
    private final byte[] corpo;

    public PedidoRequisicao(
            String metodo,
            String caminho,
            String token,
            byte[] corpo) {

        this.metodo = metodo;
        this.caminho = caminho;
        this.token = token == null ? "" : token.trim();
        this.corpo = corpo == null ? new byte[0] : corpo;

        validar();
    }

    // A desserializacao nao chama o construtor: valida os dados
    // recebidos pela rede antes de aceitar o objeto
    private void readObject(ObjectInputStream entrada)
            throws IOException, ClassNotFoundException {

        entrada.defaultReadObject();

        try {
            validar();
        } catch (IllegalArgumentException erro) {
            throw new InvalidObjectException(erro.getMessage());
        }
    }

    private void validar() {

        if (metodo == null || !METODOS.contains(metodo)) {
            throw new IllegalArgumentException("Metodo nao suportado.");
        }

        if (caminho == null
                || !CAMINHO.matcher(caminho).matches()
                || caminho.contains("..")) {
            throw new IllegalArgumentException("Caminho nao permitido.");
        }

        // O token (JWT) so tem caracteres ASCII visiveis
        if (token == null
                || token.length() > MAX_TOKEN
                || !token.chars().allMatch(c -> c > 32 && c < 127)) {
            throw new IllegalArgumentException("Token invalido.");
        }

        if (corpo == null || corpo.length > MAX_CORPO) {
            throw new IllegalArgumentException("Corpo invalido.");
        }
    }

    public String getMetodo() {
        return metodo;
    }

    public String getCaminho() {
        return caminho;
    }

    // Token JWT (vazio nas rotas publicas)
    public String getToken() {
        return token;
    }

    public byte[] getCorpo() {
        return corpo;
    }
}
