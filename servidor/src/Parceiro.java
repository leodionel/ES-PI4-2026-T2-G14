
import java.io.IOException;
import java.io.ObjectInputFilter;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.Socket;

// Organiza a comunicacao com um cliente conectado
public class Parceiro implements AutoCloseable {

    private final Socket conexao;
    private final ObjectOutputStream transmissor;
    private final ObjectInputStream receptor;

    // Limites de seguranca para objetos recebidos
    private static final long MAX_BYTES = 1024 * 1024;
    private static final long MAX_REFERENCIAS = 1000;
    private static final long MAX_PROFUNDIDADE = 15;

    public Parceiro(Socket conexao) throws IOException {

        if (conexao == null) {
            throw new IllegalArgumentException(
                "Conexao ausente."
            );
        }

        this.conexao = conexao;

        try {

            // Evita aguardar indefinidamente por dados do cliente
            conexao.setSoTimeout(30000);

            // Prepara o canal de envio
            this.transmissor = new ObjectOutputStream(
                conexao.getOutputStream()
            );

            // Envia o cabecalho da serializacao
            transmissor.flush();

            // Prepara o canal de recebimento
            this.receptor = new ObjectInputStream(
                conexao.getInputStream()
            );

            // Restringe os tipos de objetos aceitos
            receptor.setObjectInputFilter(
                Parceiro::filtrarEntrada
            );

        } catch (IOException erro) {

            // Fecha a conexao se a preparacao falhar
            try {
                conexao.close();
            } catch (IOException erroAoFechar) {
                erro.addSuppressed(erroAoFechar);
            }

            throw erro;
        }
    }

    // Verifica os objetos recebidos pelo socket
    private static ObjectInputFilter.Status filtrarEntrada(
            ObjectInputFilter.FilterInfo informacao) {

        // Bloqueia mensagens acima dos limites definidos
        if (informacao.depth() > MAX_PROFUNDIDADE
                || informacao.references() > MAX_REFERENCIAS
                || informacao.streamBytes() > MAX_BYTES) {

            return ObjectInputFilter.Status.REJECTED;
        }

        Class<?> classe = informacao.serialClass();

        // Algumas verificacoes nao possuem uma classe
        if (classe == null) {
            return ObjectInputFilter.Status.UNDECIDED;
        }

        // Nosso protocolo nao utiliza objetos do tipo array
        if (classe.isArray()) {
            return ObjectInputFilter.Status.REJECTED;
        }

        // Permite apenas os tipos utilizados no protocolo
        if (classe == Comunicado.class
                || classe == PedidoParaSair.class
                || classe == ComunicadoDeDesligamento.class
                || classe == PedidoDeStatus.class
                || classe == RespostaDeStatus.class
                || classe == PedidoDeConsulta.class
                || classe == RespostaDeConsulta.class
                || classe == PedidoDeConsulta.TipoConsulta.class
                || classe == Enum.class
                || classe == String.class) {

            return ObjectInputFilter.Status.ALLOWED;
        }

        // Bloqueia todas as demais classes
        return ObjectInputFilter.Status.REJECTED;
    }

    // Envia uma mensagem para o cliente
    public synchronized void enviar(Comunicado comunicado)
            throws IOException {

        if (comunicado == null) {
            throw new IllegalArgumentException(
                "Comunicado ausente."
            );
        }

        transmissor.writeObject(comunicado);

        // Evita reutilizar dados antigos de objetos
        transmissor.reset();
        transmissor.flush();
    }

    // Recebe uma mensagem enviada pelo cliente
    public Comunicado receber()
            throws IOException, ClassNotFoundException {

        Object objeto = receptor.readObject();

        // Garante que o objeto pertence ao protocolo
        if (!(objeto instanceof Comunicado)) {
            throw new IOException(
                "Mensagem recebida em formato invalido."
            );
        }

        return (Comunicado) objeto;
    }

    // Fecha a conexao com o cliente
    @Override
    public void close() throws IOException {
        conexao.close();
    }
}
