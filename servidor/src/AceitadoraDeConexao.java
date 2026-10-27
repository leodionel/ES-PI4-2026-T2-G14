import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;

// Recebe novas conexões de clientes
public class AceitadoraDeConexao extends Thread
        implements AutoCloseable {

    private final ServerSocket servidor;
    private final List<Parceiro> clientes;

    public AceitadoraDeConexao(
            int porta,
            List<Parceiro> clientes) throws IOException {

        if (porta < 1 || porta > 65535) {
            throw new IllegalArgumentException("Porta invalida.");
        }

        if (clientes == null) {
            throw new IllegalArgumentException(
                "Lista de clientes ausente."
            );
        }

        this.clientes = clientes;
        this.servidor = new ServerSocket(porta);
    }

    @Override
    public void run() {
        // Fecha a porta quando a thread termina
        try (ServerSocket escuta = servidor) {
            while (!escuta.isClosed()) {
                // Aguarda até um cliente se conectar
                Socket conexao = escuta.accept();

                try {
                    SupervisoraDeConexao supervisora =
                        new SupervisoraDeConexao(conexao, clientes);

                    supervisora.start();
                } catch (RuntimeException erro) {
                    // Evita deixar uma conexão sem atendimento
                    try {
                        conexao.close();
                    } catch (IOException erroAoFechar) {
                        erro.addSuppressed(erroAoFechar);
                    }

                    throw erro;
                }
            }
        } catch (IOException erro) {
            // Fechar o servidor também interrompe o accept()
            if (!encerrando) {
                System.err.println(
                    "Erro ao receber conexao: " + erro.getMessage()
                );
            }
        }
    }

    private volatile boolean encerrando = false;

    // Para de aceitar novos clientes
    @Override
    public void close() throws IOException {
        encerrando = true;
        servidor.close();
    }
}