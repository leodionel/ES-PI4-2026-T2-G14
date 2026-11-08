
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;

// Cliente utilizado para testar a comunicacao por sockets
public class ClienteTeste {

    private static final String HOST = "127.0.0.1";
    private static final int PORTA = 3000;

    public static void main(String[] args) {

        System.out.println("Iniciando teste de comunicacao...");

        try (Socket socket = new Socket()) {

            // Conecta ao servidor Java puro
            socket.connect(
                    new InetSocketAddress(HOST, PORTA),
                    5000
            );

            // Tempo maximo para receber uma resposta
            socket.setSoTimeout(10000);

            System.out.println(
                    "1. Conectado ao servidor na porta " + PORTA
            );

            // Prepara os canais de comunicacao
            try (Parceiro parceiro = new Parceiro(socket)) {

                // Solicita o status do backend
                parceiro.enviar(new PedidoDeStatus());

                System.out.println(
                        "2. Pedido de status enviado!"
                );

                // Aguarda a resposta do servidor
                Comunicado comunicado = parceiro.receber();

                if (!(comunicado instanceof RespostaDeStatus)) {
                    throw new IOException(
                            "O servidor retornou uma mensagem inesperada."
                    );
                }

                RespostaDeStatus resposta =
                        (RespostaDeStatus) comunicado;

                if (resposta.isSucesso()) {

                    System.out.println(
                            "3. SUCESSO: resposta recebida!"
                    );

                    System.out.println(
                            "Resposta do Spring Boot: "
                            + resposta.getMensagem()
                    );

                } else {

                    System.err.println(
                            "3. FALHA: " + resposta.getMensagem()
                    );

                    throw new IOException(
                            "O backend nao respondeu corretamente."
                    );
                }

                // Solicita o encerramento da conexao
                parceiro.enviar(new PedidoParaSair());

                System.out.println(
                        "4. Desconexao solicitada."
                );
            }

            System.out.println(
                    "TESTE FINALIZADO COM SUCESSO!"
            );

        } catch (IOException | ClassNotFoundException erro) {

            System.err.println(
                    "ERRO NO TESTE: " + erro.getMessage()
            );
        }
    }
}
