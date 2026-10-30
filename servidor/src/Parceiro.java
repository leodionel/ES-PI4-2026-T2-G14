import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;

// Organiza a comunicação com um cliente conectado
public class Parceiro implements AutoCloseable {
    private final Socket conexao;
    private final ObjectOutputStream transmissor;
    private final ObjectInputStream receptor;

    public Parceiro(Socket conexao) throws IOException {
        if (conexao == null) {
            throw new IllegalArgumentException("Conexao ausente.");
        }

        this.conexao = conexao;

        try {
            // Envia o cabeçalho antes de esperar o cabeçalho do cliente
            this.transmissor =
                new ObjectOutputStream(conexao.getOutputStream());
            this.transmissor.flush();

            this.receptor =
                new ObjectInputStream(conexao.getInputStream());
        } catch (IOException erro) {
            // Fecha a conexão se a preparação falhar
            try {
                conexao.close();
            } catch (IOException erroAoFechar) {
                erro.addSuppressed(erroAoFechar);
            }

            throw erro;
        }
    }

    // Envia uma mensagem para o cliente
    public synchronized void enviar(Comunicado comunicado)
            throws IOException {
        if (comunicado == null) {
            throw new IllegalArgumentException("Comunicado ausente.");
        }

        transmissor.writeObject(comunicado);

        // Evita reaproveitar uma versão antiga de um objeto enviado
        transmissor.reset();
        transmissor.flush();
    }

    // Aguarda a próxima mensagem enviada pelo cliente
    public Comunicado receber()
            throws IOException, ClassNotFoundException {
        Object objeto = receptor.readObject();

        if (!(objeto instanceof Comunicado)) {
            throw new IOException("Mensagem recebida em formato invalido.");
        }

        return (Comunicado) objeto;
    }

    // Fecha o socket e os fluxos associados à conexão
    @Override
    public void close() throws IOException {
        conexao.close();
    }
}