import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.sun.net.httpserver.HttpServer;

import static org.junit.jupiter.api.Assertions.*;

// Testa o BackendClient contra um servidor HTTP falso (nao usa o backend real)
class BackendClientTest {

    private HttpServer backendFalso;
    private BackendClient cliente;

    // Ultimo cabecalho Authorization recebido pelo servidor falso
    private volatile String authorizationRecebido;

    @BeforeEach
    void iniciarBackendFalso() throws IOException {

        // Porta 0: o sistema escolhe uma porta livre
        backendFalso = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);

        backendFalso.createContext("/status", troca -> {
            responder(troca, 200, "{\"status\":\"ativo\"}");
        });

        backendFalso.createContext("/api/propriedades", troca -> {
            authorizationRecebido =
                    troca.getRequestHeaders().getFirst("Authorization");

            if (authorizationRecebido == null) {
                responder(troca, 401, "");
            } else {
                responder(troca, 200, "[]");
            }
        });

        backendFalso.createContext("/api/analises-solo", troca -> {
            responder(troca, 500, "erro");
        });

        backendFalso.createContext("/api/eco", troca -> {
            byte[] recebido = troca.getRequestBody().readAllBytes();
            authorizationRecebido =
                    troca.getRequestHeaders().getFirst("Authorization");
            responder(troca, 201, new String(recebido, StandardCharsets.UTF_8));
        });

        backendFalso.createContext("/api/conflito", troca -> {
            responder(troca, 409, "{\"title\":\"Conflito\"}");
        });

        backendFalso.start();

        cliente = new BackendClient(
                "http://127.0.0.1:" + backendFalso.getAddress().getPort());
    }

    @AfterEach
    void pararBackendFalso() {
        backendFalso.stop(0);
    }

    private void responder(
            com.sun.net.httpserver.HttpExchange troca,
            int codigo,
            String corpo) throws IOException {

        byte[] bytes = corpo.getBytes(StandardCharsets.UTF_8);
        troca.sendResponseHeaders(codigo, bytes.length == 0 ? -1 : bytes.length);

        if (bytes.length > 0) {
            troca.getResponseBody().write(bytes);
        }
        troca.close();
    }

    // O status publico devolve o JSON do backend
    @Test
    void deveConsultarOStatus() throws Exception {

        assertEquals("{\"status\":\"ativo\"}", cliente.consultarStatus());
    }

    // O token JWT e repassado no cabecalho Authorization
    @Test
    void deveRepassarOTokenJwt() throws Exception {

        String resposta = cliente.consultarPropriedades("  meu-token  ");

        assertEquals("[]", resposta);
        assertEquals("Bearer meu-token", authorizationRecebido);
    }

    // Sem token, o cliente recusa antes de chamar o backend
    @Test
    void deveExigirToken() {

        assertThrows(IllegalArgumentException.class,
                () -> cliente.consultarPropriedades(" "));
        assertThrows(IllegalArgumentException.class,
                () -> cliente.consultarAnalisesSolo(null));
    }

    // Resposta diferente de HTTP 200 vira erro
    @Test
    void deveFalharQuandoOBackendNaoRespondeOk() {

        IOException erro = assertThrows(IOException.class,
                () -> cliente.consultarAnalisesSolo("token"));

        assertTrue(erro.getMessage().contains("500"));
    }

    // Endereco ausente ou invalido e recusado na criacao
    @Test
    void deveRecusarEnderecoInvalido() {

        assertThrows(IllegalArgumentException.class, () -> new BackendClient(" "));
        assertThrows(IllegalArgumentException.class, () -> new BackendClient("ftp://localhost"));
    }

    // POST: corpo e token seguem para o backend e o codigo volta intacto
    @Test
    void deveEncaminharCorpoETokenNoPost() throws Exception {
        byte[] corpo = "{\"nome\":\"São José\"}".getBytes(StandardCharsets.UTF_8);

        BackendClient.Resposta resposta =
                cliente.encaminhar("POST", "/api/eco", "tok", corpo);

        assertEquals(201, resposta.status());
        assertArrayEquals(corpo, resposta.corpo());
        assertEquals("Bearer tok", authorizationRecebido);
    }

    // Codigos de erro do backend nao viram excecao: o app decide o que fazer
    @Test
    void deveRepassarCodigosDeErro() throws Exception {
        BackendClient.Resposta resposta =
                cliente.encaminhar("GET", "/api/conflito", "", null);

        assertEquals(409, resposta.status());
        assertEquals("{\"title\":\"Conflito\"}",
                new String(resposta.corpo(), StandardCharsets.UTF_8));
    }

    // Servidor que aceita e fecha a primeira conexao sem responder (como
    // acontece quando o backend ainda esta subindo) e atende as seguintes
    @Test
    void deveTentarDeNovoQuandoAConexaoCaiSemResposta() throws Exception {

        try (ServerSocket servidor = new ServerSocket(
                0, 50, InetAddress.getByName("127.0.0.1"))) {

            int[] conexoes = {0};

            Thread atendente = new Thread(() -> {
                try {
                    while (true) {
                        Socket conexao = servidor.accept();
                        conexoes[0]++;

                        if (conexoes[0] == 1) {
                            conexao.close();
                            continue;
                        }

                        InputStream entrada = conexao.getInputStream();
                        byte[] lixo = new byte[8192];
                        entrada.read(lixo);
                        conexao.setSoTimeout(200);

                        try {
                            entrada.read(lixo);
                        } catch (SocketTimeoutException esperado) {
                            // Fim da requisicao
                        }

                        conexao.getOutputStream().write((
                                "HTTP/1.1 201 Created\r\n"
                                + "Content-Length: 2\r\n"
                                + "Connection: close\r\n\r\nok"
                        ).getBytes(StandardCharsets.US_ASCII));
                        conexao.close();
                    }
                } catch (IOException encerrado) {
                    // O teste fechou o servidor
                }
            });
            atendente.setDaemon(true);
            atendente.start();

            BackendClient clienteTeste = new BackendClient(
                    "http://127.0.0.1:" + servidor.getLocalPort());

            BackendClient.Resposta resposta = clienteTeste.encaminhar(
                    "POST", "/api/usuarios/login", "",
                    "{}".getBytes(StandardCharsets.UTF_8));

            assertEquals(201, resposta.status());
            assertEquals(2, conexoes[0]);
        }
    }

    // Backend fora do ar: tenta duas vezes e entao informa a falha
    @Test
    void deveFalharQuandoOBackendContinuaForaDoAr() throws Exception {

        int portaLivre;

        try (ServerSocket reserva = new ServerSocket(0)) {
            portaLivre = reserva.getLocalPort();
        }

        BackendClient clienteTeste =
                new BackendClient("http://127.0.0.1:" + portaLivre);

        assertThrows(IOException.class, () ->
                clienteTeste.encaminhar("GET", "/status", "", null));
    }

    // Conexoes paradas nao ficam guardadas por muito tempo
    @Test
    void deveReduzirOTempoDeConexaoParada() {

        assertNotNull(
                System.getProperty("jdk.httpclient.keepalive.timeout"));
    }
}
