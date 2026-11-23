// Feito por Leonardo Dionel RA:25010092

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import static org.junit.jupiter.api.Assertions.*;

// Testa a porta HTTP do Flutter Web contra um backend falso
class PortaHttpTest {

    private HttpServer backendFalso;
    private PortaHttp porta;
    private final HttpClient cliente = HttpClient.newHttpClient();

    private volatile String authorizationRecebido;

    @BeforeEach
    void iniciar() throws IOException {

        backendFalso = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);

        backendFalso.createContext("/api/eco", troca -> {
            byte[] recebido = troca.getRequestBody().readAllBytes();
            authorizationRecebido =
                    troca.getRequestHeaders().getFirst("Authorization");
            responder(troca, 201, new String(recebido, StandardCharsets.UTF_8));
        });

        backendFalso.createContext("/api/conflito", troca ->
            responder(troca, 409, "{\"detail\":\"Ja existe\"}"));

        backendFalso.start();

        porta = abrirPorta(backendFalso.getAddress().getPort());
    }

    @AfterEach
    void encerrar() {
        porta.close();
        backendFalso.stop(0);
    }

    private static PortaHttp abrirPorta(int portaBackend) throws IOException {

        PortaHttp nova = new PortaHttp(
                0,
                InetAddress.getByName("127.0.0.1"),
                new BackendClient("http://127.0.0.1:" + portaBackend)
        );

        nova.start();
        return nova;
    }

    private HttpRequest.Builder pedido(String caminho) {
        return HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + porta.getPorta() + caminho)
        );
    }

    private static void responder(HttpExchange troca, int status, String texto)
            throws IOException {

        byte[] corpo = texto.getBytes(StandardCharsets.UTF_8);
        troca.getResponseHeaders().set("Content-Type", "application/json");
        troca.sendResponseHeaders(status, corpo.length);

        try (OutputStream saida = troca.getResponseBody()) {
            saida.write(corpo);
        }
    }

    @Test
    void encaminhaCorpoETokenEDevolveStatusDoBackend() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/api/eco")
                        .header("Authorization", "Bearer abc.def.ghi")
                        .POST(HttpRequest.BodyPublishers.ofString("{\"a\":1}"))
                        .build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(201, resposta.statusCode());
        assertEquals("{\"a\":1}", resposta.body());
        assertEquals("Bearer abc.def.ghi", authorizationRecebido);
    }

    @Test
    void repassaErroDoBackendSemAlterar() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/api/conflito").GET().build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(409, resposta.statusCode());
        assertTrue(resposta.body().contains("Ja existe"));
    }

    @Test
    void respondeAPreVerificacaoDoNavegador() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/api/usuarios/login")
                        .header("Origin", "http://localhost:54321")
                        .header("Access-Control-Request-Method", "POST")
                        .method("OPTIONS", HttpRequest.BodyPublishers.noBody())
                        .build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(204, resposta.statusCode());
        assertEquals(
                "http://localhost:54321",
                resposta.headers()
                        .firstValue("Access-Control-Allow-Origin").orElse(null)
        );
        assertTrue(
                resposta.headers()
                        .firstValue("Access-Control-Allow-Headers")
                        .orElse("").contains("Authorization")
        );
    }

    @Test
    void naoLiberaOrigemDeOutroSite() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/api/conflito")
                        .header("Origin", "https://site-estranho.com")
                        .GET().build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertTrue(
                resposta.headers()
                        .firstValue("Access-Control-Allow-Origin").isEmpty()
        );
    }

    @Test
    void recusaRotaForaDaApi() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/admin").GET().build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(400, resposta.statusCode());
    }

    @Test
    void recusaMetodoNaoSuportado() throws Exception {

        HttpResponse<String> resposta = cliente.send(
                pedido("/api/eco")
                        .method("PATCH", HttpRequest.BodyPublishers.noBody())
                        .build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(405, resposta.statusCode());
    }

    @Test
    void respondeBadGatewayQuandoBackendEstaForaDoAr() throws Exception {

        int portaLivre;

        try (ServerSocket livre = new ServerSocket(0)) {
            portaLivre = livre.getLocalPort();
        }

        try (PortaHttp semBackend = abrirPorta(portaLivre)) {

            HttpResponse<String> resposta = cliente.send(
                    HttpRequest.newBuilder(URI.create(
                            "http://127.0.0.1:" + semBackend.getPorta()
                            + "/api/usuarios/login"))
                            .POST(HttpRequest.BodyPublishers.ofString("{}"))
                            .build(),
                    HttpResponse.BodyHandlers.ofString()
            );

            assertEquals(502, resposta.statusCode());
            assertTrue(resposta.body().contains("backend"));
        }
    }
}
