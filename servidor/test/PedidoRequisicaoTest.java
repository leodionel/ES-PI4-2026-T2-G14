import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InvalidObjectException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

// Testa a validacao do pedido que chega pela rede
class PedidoRequisicaoTest {

    private static final byte[] VAZIO = new byte[0];

    // Serializa e le de volta, como o servidor faz com o que recebe
    private static Object enviarEReceber(Object objeto) throws Exception {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();

        try (ObjectOutputStream saida = new ObjectOutputStream(bytes)) {
            saida.writeObject(objeto);
        }

        try (ObjectInputStream entrada = new ObjectInputStream(
                new ByteArrayInputStream(bytes.toByteArray()))) {
            return entrada.readObject();
        }
    }

    @Test
    void devePreservarOsDadosNaIdaEVolta() throws Exception {
        byte[] corpo = "{\"nome\":\"São José\"}".getBytes(StandardCharsets.UTF_8);

        PedidoRequisicao pedido = (PedidoRequisicao) enviarEReceber(
                new PedidoRequisicao("POST", "/api/talhoes", "abc.def", corpo));

        assertEquals("POST", pedido.getMetodo());
        assertEquals("/api/talhoes", pedido.getCaminho());
        assertEquals("abc.def", pedido.getToken());
        assertArrayEquals(corpo, pedido.getCorpo());
    }

    @Test
    void deveAceitarStatusEParametros() {
        assertDoesNotThrow(() ->
                new PedidoRequisicao("GET", "/status", "", VAZIO));
        assertDoesNotThrow(() ->
                new PedidoRequisicao("GET", "/api/talhoes?page=1&size=10", "", VAZIO));
    }

    @Test
    void deveRecusarMetodoDesconhecido() {
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao("TRACE", "/api/talhoes", "", VAZIO));
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao(null, "/api/talhoes", "", VAZIO));
    }

    @Test
    void deveRecusarCaminhosForaDaApi() {
        String[] invalidos = {
                null,
                "",
                "/actuator/env",
                "/api/../actuator",
                "http://outro.host/api/x",
                "/api/talhoes#frag",
                "/api/a b"
        };

        for (String caminho : invalidos) {
            assertThrows(IllegalArgumentException.class, () ->
                    new PedidoRequisicao("GET", caminho, "", VAZIO),
                    "caminho: " + caminho);
        }
    }

    @Test
    void deveRecusarTokenInvalido() {
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao("GET", "/api/talhoes", "com espaco", VAZIO));
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao("GET", "/api/talhoes", "açúcar", VAZIO));
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao("GET", "/api/talhoes", "a".repeat(5000), VAZIO));
    }

    @Test
    void deveRecusarCorpoGrandeDemais() {
        assertThrows(IllegalArgumentException.class, () ->
                new PedidoRequisicao("POST", "/api/talhoes", "",
                        new byte[600 * 1024]));
    }

    // O construtor nao roda na desserializacao: o readObject valida
    @Test
    void deveRecusarObjetoInvalidoRecebidoPelaRede() throws Exception {
        PedidoRequisicao valido =
                new PedidoRequisicao("GET", "/api/talhoes", "", VAZIO);

        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ObjectOutputStream saida = new ObjectOutputStream(bytes)) {
            saida.writeObject(valido);
        }

        // Troca "/api/talhoes" por "/xxx/talhoes" nos bytes serializados
        byte[] dados = bytes.toByteArray();
        byte[] alvo = "/api/".getBytes(StandardCharsets.US_ASCII);
        byte[] falso = "/xxx/".getBytes(StandardCharsets.US_ASCII);
        boolean trocou = false;

        for (int i = 0; i + alvo.length <= dados.length && !trocou; i++) {
            boolean igual = true;
            for (int j = 0; j < alvo.length; j++) {
                if (dados[i + j] != alvo[j]) {
                    igual = false;
                    break;
                }
            }
            if (igual) {
                System.arraycopy(falso, 0, dados, i, falso.length);
                trocou = true;
            }
        }

        assertTrue(trocou);

        assertThrows(InvalidObjectException.class, () -> {
            try (ObjectInputStream entrada = new ObjectInputStream(
                    new ByteArrayInputStream(dados))) {
                entrada.readObject();
            }
        });
    }
}
