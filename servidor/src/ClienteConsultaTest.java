
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

// Testa consultas autenticadas pelo servidor Java puro
public class ClienteConsultaTeste {

    private static final String HOST = "127.0.0.1";
    private static final int PORTA = 3000;

    public static void main(String[] args) {

        System.out.println(
                "Iniciando teste de consultas autenticadas..."
        );

        String tokenJwt;

        // Recebe o JWT pelo terminal, sem salva-lo no codigo
        try {

            BufferedReader entrada = new BufferedReader(
                    new InputStreamReader(
                            System.in,
                            StandardCharsets.UTF_8
                    )
            );

            tokenJwt = entrada.readLine();

            if (tokenJwt == null || tokenJwt.isBlank()) {
                System.err.println("Token JWT nao informado.");
                return;
            }

            tokenJwt = tokenJwt.trim();

        } catch (IOException erro) {

            System.err.println(
                    "Erro ao receber o token: " + erro.getMessage()
            );

            return;
        }

        // Conecta ao servidor Java puro
        try (Socket socket = new Socket()) {

            socket.connect(
                    new InetSocketAddress(HOST, PORTA),
                    5000
            );

            socket.setSoTimeout(30000);

            System.out.println(
                    "1. Conectado ao servidor na porta " + PORTA
            );

            try (Parceiro parceiro = new Parceiro(socket)) {

                // TESTE 1 - Consultar propriedades
                consultar(
                        parceiro,
                        PedidoDeConsulta.TipoConsulta.PROPRIEDADES,
                        tokenJwt
                );

                // TESTE 2 - Consultar analises de solo
                consultar(
                        parceiro,
                        PedidoDeConsulta.TipoConsulta.ANALISES_SOLO,
                        tokenJwt
                );

                // Encerra a conexao
                parceiro.enviar(new PedidoParaSair());

                System.out.println(
                        "4. Desconexao solicitada."
                );
            }

            System.out.println(
                    "TESTES AUTENTICADOS CONCLUIDOS COM SUCESSO!"
            );

        } catch (IOException | ClassNotFoundException erro) {

            System.err.println(
                    "ERRO NO TESTE: " + erro.getMessage()
            );
        }
    }

    // Consulta um endpoint autenticado por meio do socket
    private static void consultar(
            Parceiro parceiro,
            PedidoDeConsulta.TipoConsulta tipo,
            String tokenJwt)
            throws IOException, ClassNotFoundException {

        // Envia a solicitacao com o token JWT
        parceiro.enviar(
                new PedidoDeConsulta(tipo, tokenJwt)
        );

        // Recebe a resposta do servidor
        Comunicado comunicado = parceiro.receber();

        if (!(comunicado instanceof RespostaDeConsulta resposta)) {
            throw new IOException(
                    "O servidor retornou uma mensagem inesperada."
            );
        }

        // Verifica se a consulta funcionou
        if (!resposta.isSucesso()) {

            throw new IOException(
                    "Falha na consulta " + tipo + ": "
                    + resposta.getConteudo()
            );
        }

        // Identifica a consulta realizada
        if (tipo == PedidoDeConsulta.TipoConsulta.PROPRIEDADES) {

            System.out.println(
                    "2. Propriedades consultadas com sucesso!"
            );

        } else {

            System.out.println(
                    "3. Analises de solo consultadas com sucesso!"
            );
        }

        // Exibe o JSON retornado pelo Spring Boot
        System.out.println(
                "Resposta JSON: " + resposta.getConteudo()
        );
    }
}
