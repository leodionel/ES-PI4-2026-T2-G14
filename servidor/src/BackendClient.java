// Contribuição: Matheus Rosini
// RA: 25015832


import java.io.IOException;
import java.net.ConnectException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

// Responsavel pela comunicacao HTTP com o Spring Boot
public class BackendClient {

    // O cliente HTTP guarda conexoes abertas para reaproveitar. Se o backend
    // ou o Docker fecham uma conexao parada, o primeiro pedido seguinte falha.
    // Manter a conexao por pouco tempo evita esse caso. Precisa ser definido
    // antes de o primeiro HttpClient ser criado.
    static {
        if (System.getProperty("jdk.httpclient.keepalive.timeout") == null) {
            System.setProperty("jdk.httpclient.keepalive.timeout", "5");
        }
    }

    // Espera antes de repetir um pedido que falhou ao conectar
    private static final long PAUSA_NOVA_TENTATIVA_MS = 300;

    private final HttpClient cliente;

    // Endereco base da API (usado no encaminhamento generico)
    private final URI base;

    private final URI enderecoStatus;
    private final URI enderecoPropriedades;
    private final URI enderecoAnalisesSolo;

    // Configura a conexao com o backend
    public BackendClient(String enderecoBase) {

        if (enderecoBase == null || enderecoBase.isBlank()) {
            throw new IllegalArgumentException(
                "Endereco do backend ausente."
            );
        }

        URI base = URI.create(enderecoBase);
        this.base = base;

        if (base.getHost() == null
                || (!"http".equalsIgnoreCase(base.getScheme())
                && !"https".equalsIgnoreCase(base.getScheme()))) {

            throw new IllegalArgumentException(
                "Endereco do backend invalido."
            );
        }

        // Endpoints do Spring Boot
        this.enderecoStatus =
                base.resolve("/status");

        this.enderecoPropriedades =
                base.resolve("/api/propriedades");

        this.enderecoAnalisesSolo =
                base.resolve("/api/analises-solo");

        // Configuracao do cliente HTTP
        // HTTP/1.1 evita a tentativa de atualizar para HTTP/2
        this.cliente = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    // Consulta o status publico do backend
    public String consultarStatus()
            throws IOException, InterruptedException {

        HttpRequest pedido = HttpRequest.newBuilder()
                .uri(enderecoStatus)
                .timeout(Duration.ofSeconds(8))
                .header("Accept", "application/json")
                .GET()
                .build();

        return executarConsulta(pedido);
    }

    // Lista propriedades do usuario autenticado
    public String consultarPropriedades(String tokenJwt)
            throws IOException, InterruptedException {

        HttpRequest pedido = criarPedidoAutenticado(
                enderecoPropriedades,
                tokenJwt
        );

        return executarConsulta(pedido);
    }

    // Lista analises de solo do usuario autenticado
    public String consultarAnalisesSolo(String tokenJwt)
            throws IOException, InterruptedException {

        HttpRequest pedido = criarPedidoAutenticado(
                enderecoAnalisesSolo,
                tokenJwt
        );

        return executarConsulta(pedido);
    }

    // Resposta HTTP repassada sem interpretacao
    public record Resposta(int status, String tipoConteudo, byte[] corpo) {}

    // Encaminha qualquer rota da API e devolve o codigo HTTP, o tipo
    // do conteudo e o corpo, inclusive quando o codigo nao e 200
    public Resposta encaminhar(
            String metodo,
            String caminho,
            String tokenJwt,
            byte[] corpo)
            throws IOException, InterruptedException {

        HttpRequest.BodyPublisher conteudo =
                (corpo == null || corpo.length == 0)
                        ? HttpRequest.BodyPublishers.noBody()
                        : HttpRequest.BodyPublishers.ofByteArray(corpo);

        HttpRequest.Builder pedido = HttpRequest.newBuilder()
                .uri(base.resolve(caminho))
                .timeout(Duration.ofSeconds(20))
                .header("Accept", "*/*")
                .method(metodo, conteudo);

        if (corpo != null && corpo.length > 0) {
            pedido.header("Content-Type", "application/json");
        }

        if (tokenJwt != null && !tokenJwt.isBlank()) {
            pedido.header("Authorization", "Bearer " + tokenJwt.trim());
        }

        HttpResponse<byte[]> resposta = enviar(
                pedido.build(),
                HttpResponse.BodyHandlers.ofByteArray()
        );

        return new Resposta(
                resposta.statusCode(),
                resposta.headers()
                        .firstValue("Content-Type")
                        .orElse("application/json"),
                resposta.body()
        );
    }

    // Envia o pedido. Se a conexao falhar antes de qualquer resposta
    // (backend ainda subindo ou conexao derrubada), tenta mais uma vez.
    // Nesses casos o backend nao chegou a responder, e por isso a repeticao
    // e aceitavel mesmo em POST. Tempo esgotado nao e repetido.
    private <T> HttpResponse<T> enviar(
            HttpRequest pedido,
            HttpResponse.BodyHandler<T> tratador)
            throws IOException, InterruptedException {

        try {
            return cliente.send(pedido, tratador);
        } catch (IOException erro) {

            if (!falhouAntesDaResposta(erro)) {
                throw erro;
            }

            Thread.sleep(PAUSA_NOVA_TENTATIVA_MS);

            return cliente.send(pedido, tratador);
        }
    }

    // Conexao recusada ou fechada sem enviar nenhum byte de resposta
    private static boolean falhouAntesDaResposta(IOException erro) {

        if (erro instanceof ConnectException) {
            return true;
        }

        String mensagem = erro.getMessage();

        return mensagem != null && mensagem.contains("received no bytes");
    }

    // Cria uma requisicao HTTP com autenticacao JWT
    private HttpRequest criarPedidoAutenticado(
            URI endereco,
            String tokenJwt) {

        if (tokenJwt == null || tokenJwt.isBlank()) {
            throw new IllegalArgumentException(
                "Token JWT obrigatorio."
            );
        }

        return HttpRequest.newBuilder()
                .uri(endereco)
                .timeout(Duration.ofSeconds(8))
                .header("Accept", "application/json")
                .header(
                    "Authorization",
                    "Bearer " + tokenJwt.trim()
                )
                .GET()
                .build();
    }

    // Executa a requisicao e retorna a resposta JSON
    private String executarConsulta(HttpRequest pedido)
            throws IOException, InterruptedException {

        HttpResponse<String> resposta = enviar(
                pedido,
                HttpResponse.BodyHandlers.ofString()
        );

        // Aceita somente respostas HTTP 200
        if (resposta.statusCode() != 200) {

            throw new IOException(
                "Backend respondeu com HTTP "
                + resposta.statusCode()
            );
        }

        return resposta.body();
    }
}
