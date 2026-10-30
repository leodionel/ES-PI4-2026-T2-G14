import java.io.EOFException;
import java.io.IOException;
import java.net.Socket;
import java.util.List;

// Atende as mensagens de um cliente
public class SupervisoraDeConexao extends Thread {
    private final Socket conexao;
    private final List<Parceiro> clientes;

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
    }

    @Override
    public void run() {
        // Fecha a conexão ao terminar, inclusive se ocorrer um erro
        try (Socket socket = conexao;
             Parceiro cliente = new Parceiro(socket)) {

            synchronized (clientes) {
                clientes.add(cliente);
            }

            System.out.println(
                "Cliente conectado: " + socket.getRemoteSocketAddress()
            );

            try {
                atender(cliente);
            } finally {
                // Remove o cliente mesmo em caso de desconexão inesperada
                synchronized (clientes) {
                    clientes.remove(cliente);
                }
            }
        } catch (EOFException erro) {
            System.out.println("O cliente encerrou a conexao.");
        } catch (IOException | ClassNotFoundException erro) {
            System.err.println(
                "Conexao encerrada: " + erro.getMessage()
            );
        }
    }

    private void atender(Parceiro cliente)
            throws IOException, ClassNotFoundException {
        while (true) {
            Comunicado comunicado = cliente.receber();

            if (comunicado instanceof PedidoParaSair) {
                System.out.println("Cliente solicitou a saida.");
                return;
            }

            // Os demais pedidos serão acrescentados nesta etapa
            throw new IOException(
                "Tipo de pedido ainda nao suportado: "
                    + comunicado.getClass().getSimpleName()
            );
        }
    }
}