import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

// Comunicação HTTP com o backend Spring Boot
public class BackendClient {
    private final HttpClient cliente;
    private final URI enderecoStatus;

    public BackendClient(String enderecoBase) {
        if (enderecoBase == null || enderecoBase.isBlank()) {
            throw new IllegalArgumentException(
                "Endereco do backend ausente."
            );
        }

        URI base = URI.create(enderecoBase);

        if (base.getHost() == null
                || (!"http".equalsIgnoreCase(base.getScheme())
                && !"https".equalsIgnoreCase(base.getScheme()))) {
            throw new IllegalArgumentException(
                "Endereco do backend invalido."
            );
        }

        this.enderecoStatus = base.resolve("/status");

        this.cliente = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    }

    public String consultarStatus()
            throws IOException, InterruptedException {

        HttpRequest pedido = HttpRequest.newBuilder()
            .uri(enderecoStatus)
            .timeout(Duration.ofSeconds(5))
            .header("Accept", "application/json")
            .GET()
            .build();

        HttpResponse<String> resposta = cliente.send(
            pedido,
            HttpResponse.BodyHandlers.ofString()
        );

        if (resposta.statusCode() != 200) {
            throw new IOException(
                "Backend respondeu com HTTP " + resposta.statusCode()
            );
        }

        return resposta.body();
    }
}