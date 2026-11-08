
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

// Responsavel pela comunicacao HTTP com o backend Spring Boot
public class BackendClient {

    private final HttpClient cliente;
    private final URI enderecoStatus;

    // Recebe o endereco do backend
    public BackendClient(String enderecoBase) {

        if (enderecoBase == null || enderecoBase.isBlank()) {
            throw new IllegalArgumentException(
                "Endereco do backend ausente."
            );
        }

        URI base = URI.create(enderecoBase);

        // Verifica se o endereco utiliza HTTP ou HTTPS
        if (base.getHost() == null
                || (!"http".equalsIgnoreCase(base.getScheme())
                && !"https".equalsIgnoreCase(base.getScheme()))) {

            throw new IllegalArgumentException(
                "Endereco do backend invalido."
            );
        }

        // Define o endpoint de verificacao do backend
        this.enderecoStatus = base.resolve("/status");

        // Configura o cliente HTTP
        this.cliente = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    // Consulta o status do backend Spring Boot
    public String consultarStatus()
            throws IOException, InterruptedException {

        // Monta a requisicao HTTP GET
        HttpRequest pedido = HttpRequest.newBuilder()
                .uri(enderecoStatus)
                .timeout(Duration.ofSeconds(5))
                .header("Accept", "application/json")
                .GET()
                .build();

        // Envia a requisicao e recebe a resposta
        HttpResponse<String> resposta = cliente.send(
                pedido,
                HttpResponse.BodyHandlers.ofString()
        );

        // Verifica se o backend respondeu corretamente
        if (resposta.statusCode() != 200) {
            throw new IOException(
                "Backend respondeu com HTTP "
                + resposta.statusCode()
            );
        }

        // Retorna o corpo da resposta
        return resposta.body();
    }
}
