
import java.io.EOFException;
import java.io.IOException;
import java.net.Socket;
import java.util.List;

// Atende as mensagens de cada cliente conectado
public class SupervisoraDeConexao extends Thread {

    private final Socket conexao;
    private final List<Parceiro> clientes;
    private final BackendClient backend;

    public SupervisoraDeConexao(
            Socket conexao,
            List<Parceiro> clientes) {

        if (conexao == null || clientes == null) {
            throw new IllegalArgumentException(
                "Conexao e lista de clientes sao obrigatorias."
            );
        }

        this.conexao = conexao;
        this.clientes = clientes;

        // Cliente HTTP que se comunica com o Spring Boot
        this.backend = new BackendClient(
                "http://localhost:8081"
        );
    }

    @Override
    public void run() {

        // Fecha automaticamente a conexao ao terminar
        try (Socket socket = conexao;
             Parceiro cliente = new Parceiro(socket)) {

            synchronized (clientes) {
                clientes.add(cliente);
            }

            System.out.println(
                "Cliente conectado: "
                + socket.getRemoteSocketAddress()
            );

            try {
                atender(cliente);
            } finally {

                // Remove o cliente da lista ao desconectar
                synchronized (clientes) {
                    clientes.remove(cliente);
                }
            }

        } catch (EOFException erro) {

            System.out.println(
                "O cliente encerrou a conexao."
            );

        } catch (IOException | ClassNotFoundException erro) {

            System.err.println(
                "Conexao encerrada: " + erro.getMessage()
            );
        }
    }

    // Recebe e processa as mensagens enviadas pelo cliente
    private void atender(Parceiro cliente)
            throws IOException, ClassNotFoundException {

        while (true) {

            Comunicado comunicado = cliente.receber();

            // PEDIDO 1 - Encerrar conexao
            if (comunicado instanceof PedidoParaSair) {

                System.out.println(
                    "Cliente solicitou a saida."
                );

                return;
            }

            // PEDIDO 2 - Consultar status do backend
            if (comunicado instanceof PedidoDeStatus) {

                System.out.println(
                    "Cliente solicitou o status do backend."
                );

                consultarStatus(cliente);
                continue;
            }

            // Impede processamento de mensagens desconhecidas
            throw new IOException(
                "Tipo de pedido ainda nao suportado: "
                + comunicado.getClass().getSimpleName()
            );
        }
    }

    // Consulta o Spring Boot e envia a resposta pelo socket
    private void consultarStatus(Parceiro cliente)
            throws IOException {

        try {

            // Consulta o endpoint GET /status
            String resposta = backend.consultarStatus();

            // Devolve o resultado para o cliente conectado
            cliente.enviar(
                new RespostaDeStatus(
                    true,
                    resposta
                )
            );

            System.out.println(
                "Status do backend enviado ao cliente."
            );

        } catch (InterruptedException erro) {

            Thread.currentThread().interrupt();

            cliente.enviar(
                new RespostaDeStatus(
                    false,
                    "Consulta ao backend interrompida."
                )
            );

        } catch (IOException erro) {

            System.err.println(
                "Erro ao consultar o backend: "
                + erro.getMessage()
            );

            // Informa a falha sem encerrar a conexao
            cliente.enviar(
                new RespostaDeStatus(
                    false,
                    "Nao foi possivel consultar o backend."
                )
            );
        }
    }
}
