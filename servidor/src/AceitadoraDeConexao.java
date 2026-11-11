
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;

// Recebe novas conexoes de clientes
public class AceitadoraDeConexao extends Thread
        implements AutoCloseable {

    private final ServerSocket servidor;
    private final List<Parceiro> clientes;

    private volatile boolean encerrando = false;

    public AceitadoraDeConexao(
            int porta,
            List<Parceiro> clientes) throws IOException {

        // Verifica se a porta informada e valida
        if (porta < 1 || porta > 65535) {
            throw new IllegalArgumentException("Porta invalida.");
        }

        // Verifica se a lista de clientes existe
        if (clientes == null) {
            throw new IllegalArgumentException(
                "Lista de clientes ausente."
            );
        }

        this.clientes = clientes;

        // Permite conexoes somente deste computador
        InetAddress enderecoLocal =
                InetAddress.getByName(
                    System.getenv().getOrDefault("BIND_ADDRESS", "127.0.0.1")
                );

        // Abre a porta TCP apenas na interface local
        this.servidor = new ServerSocket(
                porta,
                50,
                enderecoLocal
        );
    }

    @Override
    public void run() {

        // Fecha a porta quando a thread terminar
        try (ServerSocket escuta = servidor) {

            while (!escuta.isClosed()) {

                // Aguarda a conexao de um cliente local
                Socket conexao = escuta.accept();

                try {

                    // Cria uma thread para atender o cliente
                    SupervisoraDeConexao supervisora =
                            new SupervisoraDeConexao(
                                    conexao,
                                    clientes
                            );

                    supervisora.start();

                } catch (RuntimeException erro) {

                    // Fecha a conexao caso ocorra uma falha
                    try {
                        conexao.close();
                    } catch (IOException erroAoFechar) {
                        erro.addSuppressed(erroAoFechar);
                    }

                    throw erro;
                }
            }

        } catch (IOException erro) {

            // O fechamento normal tambem interrompe accept()
            if (!encerrando) {
                System.err.println(
                    "Erro ao receber conexao: "
                    + erro.getMessage()
                );
            }
        }
    }

    // Para de aceitar novas conexoes
    @Override
    public void close() throws IOException {

        encerrando = true;
        servidor.close();
    }
}
