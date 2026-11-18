import java.io.IOException;
import java.net.InetSocketAddress;
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
}
