// Feito por Leonardo Dionel RA:25010092

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

/*
 * Porta HTTP do servidor, usada apenas pelo Flutter Web.
 *
 * O navegador nao consegue abrir um socket TCP, entao o app web fala HTTP
 * com esta porta. O pedido passa pelas mesmas validacoes do PedidoRequisicao
 * (metodos e rotas permitidos, tamanho do corpo e do token) e segue para o
 * Spring Boot pelo mesmo BackendClient usado nos sockets.
 * No celular e no emulador o app continua usando o socket da porta 3000.
 */
public class PortaHttp implements AutoCloseable {

    // Apenas o proprio computador: o Flutter Web roda em localhost
    // com uma porta qualquer
    private static final Pattern ORIGEM_PERMITIDA = Pattern.compile(
            "https?://(localhost|127\\.0\\.0\\.1)(:\\d{1,5})?"
    );

    private static final Set<String> METODOS =
            Set.of("GET", "POST", "PUT", "DELETE");

    private static final int MAX_CORPO = 512 * 1024;

    private final HttpServer http;
    private final ExecutorService atendentes;
    private final BackendClient backend;

    public PortaHttp(int porta, InetAddress endereco, BackendClient backend)
            throws IOException {

        if (porta < 0 || porta > 65535) {
            throw new IllegalArgumentException("Porta HTTP invalida.");
        }

        if (backend == null) {
            throw new IllegalArgumentException("Backend ausente.");
        }

        this.backend = backend;
        this.http = HttpServer.create(
                new InetSocketAddress(endereco, porta),
                50
        );

        // Uma thread por pedido, como nas conexoes por socket
        this.atendentes = Executors.newCachedThreadPool(tarefa -> {
            Thread thread = new Thread(tarefa, "porta-http");
            thread.setDaemon(true);
            return thread;
        });

        http.setExecutor(atendentes);
        http.createContext("/", this::atender);
    }

    public void start() {
        http.start();
    }

    // Porta realmente aberta (util quando criada com porta 0)
    public int getPorta() {
        return http.getAddress().getPort();
    }

    @Override
    public void close() {
        http.stop(0);
        atendentes.shutdownNow();
    }

    private void atender(HttpExchange troca) throws IOException {

        try {
            adicionarCors(troca);

            String metodo = troca.getRequestMethod().toUpperCase();

            // Pre-verificacao que o navegador faz antes de POST/PUT/DELETE
            if (metodo.equals("OPTIONS")) {
                responder(troca, 204, null, new byte[0]);
                return;
            }

            if (!METODOS.contains(metodo)) {
                responderErro(troca, 405, "Metodo nao suportado.");
                return;
            }

            String caminho = troca.getRequestURI().getRawPath();

            if (troca.getRequestURI().getRawQuery() != null) {
                caminho += "?" + troca.getRequestURI().getRawQuery();
            }

            byte[] corpo;

            try (InputStream entrada = troca.getRequestBody()) {
                corpo = entrada.readNBytes(MAX_CORPO + 1);
            }

            PedidoRequisicao pedido;

            try {
                // Mesmas regras do socket: rota, metodo, token e tamanho
                pedido = new PedidoRequisicao(
                        metodo,
                        caminho,
                        extrairToken(troca),
                        corpo
                );
            } catch (IllegalArgumentException erro) {
                responderErro(troca, 400, erro.getMessage());
                return;
            }

            encaminhar(troca, pedido);

        } finally {
            troca.close();
        }
    }

    private void encaminhar(HttpExchange troca, PedidoRequisicao pedido)
            throws IOException {

        try {
            BackendClient.Resposta resposta = backend.encaminhar(
                    pedido.getMetodo(),
                    pedido.getCaminho(),
                    pedido.getToken(),
                    pedido.getCorpo()
            );

            // Registra rota e codigo, sem token nem corpo
            System.out.println(
                "HTTP " + pedido.getMetodo() + " " + pedido.getCaminho()
                + " -> " + resposta.status()
            );

            responder(
                    troca,
                    resposta.status(),
                    resposta.tipoConteudo(),
                    resposta.corpo()
            );

        } catch (InterruptedException erro) {

            Thread.currentThread().interrupt();
            responderErro(troca, 503, "Requisicao interrompida.");

        } catch (IOException erro) {

            System.err.println(
                "Falha ao encaminhar HTTP " + pedido.getMetodo() + " "
                + pedido.getCaminho() + ": " + Descricao.de(erro)
            );

            responderErro(troca, 502, "Nao foi possivel acessar o backend.");
        }
    }

    // O app envia o JWT no cabecalho Authorization: Bearer <token>
    private static String extrairToken(HttpExchange troca) {

        String cabecalho = troca.getRequestHeaders().getFirst("Authorization");

        if (cabecalho == null) {
            return "";
        }

        cabecalho = cabecalho.trim();

        if (cabecalho.regionMatches(true, 0, "Bearer ", 0, 7)) {
            return cabecalho.substring(7).trim();
        }

        return cabecalho;
    }

    // Libera apenas paginas do proprio computador
    private static void adicionarCors(HttpExchange troca) {

        String origem = troca.getRequestHeaders().getFirst("Origin");

        troca.getResponseHeaders().add("Vary", "Origin");

        if (origem == null || !ORIGEM_PERMITIDA.matcher(origem).matches()) {
            return;
        }

        troca.getResponseHeaders().set("Access-Control-Allow-Origin", origem);
        troca.getResponseHeaders().set(
                "Access-Control-Allow-Methods",
                "GET, POST, PUT, DELETE, OPTIONS"
        );
        troca.getResponseHeaders().set(
                "Access-Control-Allow-Headers",
                "Authorization, Content-Type"
        );
        troca.getResponseHeaders().set("Access-Control-Max-Age", "600");
    }

    private static void responderErro(
            HttpExchange troca,
            int status,
            String mensagem) throws IOException {

        String json = "{\"title\":\"Servidor indisponivel\",\"status\":"
                + status + ",\"detail\":\""
                + mensagem.replace("\\", "\\\\").replace("\"", "\\\"")
                + "\"}";

        responder(
                troca,
                status,
                "application/json",
                json.getBytes(StandardCharsets.UTF_8)
        );
    }

    private static void responder(
            HttpExchange troca,
            int status,
            String tipoConteudo,
            byte[] corpo) throws IOException {

        if (tipoConteudo != null) {
            troca.getResponseHeaders().set("Content-Type", tipoConteudo);
        }

        // Respostas 1xx, 204 e 304 nao podem ter corpo
        boolean semCorpo = corpo.length == 0
                || status < 200 || status == 204 || status == 304;

        troca.sendResponseHeaders(status, semCorpo ? -1 : corpo.length);

        if (!semCorpo) {
            try (OutputStream saida = troca.getResponseBody()) {
                saida.write(corpo);
            }
        }
    }
}
