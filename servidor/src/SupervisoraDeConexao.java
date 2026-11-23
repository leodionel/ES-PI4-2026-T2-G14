// Feito por Leonardo Dionel RA:25010092

// Contribuição: Matheus Rosini
// RA: 25015832

import java.io.EOFException;
import java.io.IOException;
import java.net.Socket;
import java.util.List;

// Responsavel por atender cada cliente conectado ao servidor
public class SupervisoraDeConexao extends Thread {

    private final Socket conexao;
    private final List<Parceiro> clientes;
    private final BackendClient backend;

    // Um unico cliente HTTP para todas as conexoes
    private static final BackendClient BACKEND = new BackendClient(
        System.getenv().getOrDefault("BACKEND_URL", "http://localhost:8081")
    );

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

        // Cliente HTTP utilizado para consultar o Spring Boot
        this.backend = BACKEND;
    }

    @Override
    public void run() {

        try (Socket socket = conexao;
             Parceiro cliente = new Parceiro(socket)) {

            // Registra o cliente conectado
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

                // Remove o cliente ao encerrar a conexao
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

    // Recebe e identifica os pedidos do cliente
    private void atender(Parceiro cliente)
            throws IOException, ClassNotFoundException {

        while (true) {

            Comunicado comunicado = cliente.receber();

            // PEDIDO 1 - Encerrar a conexao
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

                if (Thread.currentThread().isInterrupted()) {
                    return;
                }

                continue;
            }

            // PEDIDO 3 - Consultar propriedades ou analises
            if (comunicado instanceof PedidoDeConsulta pedido) {

                System.out.println(
                    "Cliente solicitou uma consulta autenticada."
                );

                consultarDados(cliente, pedido);

                if (Thread.currentThread().isInterrupted()) {
                    return;
                }

                continue;
            }

            // PEDIDO 4 - Encaminhar uma rota da API (usado pelo aplicativo)
            if (comunicado instanceof PedidoRequisicao pedido) {

                encaminhar(cliente, pedido);

                if (Thread.currentThread().isInterrupted()) {
                    return;
                }

                continue;
            }

            // Mensagem desconhecida
            throw new IOException(
                "Tipo de pedido nao suportado: "
                + comunicado.getClass().getSimpleName()
            );
        }
    }

    // Consulta o status do Spring Boot
    private void consultarStatus(Parceiro cliente)
            throws IOException {

        try {

            String resposta = backend.consultarStatus();

            cliente.enviar(
                new RespostaDeStatus(
                    true,
                    resposta
                )
            );

            System.out.println(
                "Status enviado ao cliente."
            );

        } catch (InterruptedException erro) {

            Thread.currentThread().interrupt();

            cliente.enviar(
                new RespostaDeStatus(
                    false,
                    "Consulta interrompida."
                )
            );

        } catch (IOException erro) {

            System.err.println(
                "Falha ao consultar status: "
                + erro.getMessage()
            );

            cliente.enviar(
                new RespostaDeStatus(
                    false,
                    "Nao foi possivel consultar o backend."
                )
            );
        }
    }

    // Consulta propriedades ou analises usando JWT
    private void consultarDados(
            Parceiro cliente,
            PedidoDeConsulta pedido) throws IOException {

        // Verifica se o pedido possui um tipo valido
        if (pedido.getTipo() == null) {

            cliente.enviar(
                new RespostaDeConsulta(
                    false,
                    "Tipo de consulta invalido."
                )
            );

            return;
        }

        String resposta;

        try {

            // Identifica qual endpoint do Spring Boot consultar
            switch (pedido.getTipo()) {

                case PROPRIEDADES:

                    resposta = backend.consultarPropriedades(
                        pedido.getTokenJwt()
                    );

                    break;

                case ANALISES_SOLO:

                    resposta = backend.consultarAnalisesSolo(
                        pedido.getTokenJwt()
                    );

                    break;

                default:

                    cliente.enviar(
                        new RespostaDeConsulta(
                            false,
                            "Consulta nao suportada."
                        )
                    );

                    return;
            }

        } catch (InterruptedException erro) {

            Thread.currentThread().interrupt();

            cliente.enviar(
                new RespostaDeConsulta(
                    false,
                    "Consulta interrompida."
                )
            );

            return;

        } catch (IOException | IllegalArgumentException erro) {

            // Registra a falha sem exibir o token JWT
            System.err.println(
                "Falha na consulta autenticada: "
                + erro.getMessage()
            );

            cliente.enviar(
                new RespostaDeConsulta(
                    false,
                    "Nao foi possivel realizar a consulta. "
                    + "Verifique a autenticacao e a disponibilidade do backend."
                )
            );

            return;
        }

        // Retorna o JSON recebido do Spring Boot
        cliente.enviar(
            new RespostaDeConsulta(
                true,
                resposta
            )
        );

        System.out.println(
            "Resultado da consulta enviado ao cliente."
        );
    }

    // Encaminha a requisicao ao Spring Boot e devolve a resposta como veio
    private void encaminhar(
            Parceiro cliente,
            PedidoRequisicao pedido) throws IOException {

        try {

            BackendClient.Resposta resposta = backend.encaminhar(
                pedido.getMetodo(),
                pedido.getCaminho(),
                pedido.getToken(),
                pedido.getCorpo()
            );

            // Registra rota e codigo, sem token nem corpo
            System.out.println(
                pedido.getMetodo() + " " + pedido.getCaminho()
                + " -> " + resposta.status()
            );

            cliente.enviar(
                new RespostaRequisicao(
                    resposta.status(),
                    resposta.tipoConteudo(),
                    resposta.corpo()
                )
            );

        } catch (InterruptedException erro) {

            Thread.currentThread().interrupt();
            enviarErro(cliente, 503, "Requisicao interrompida.");

        } catch (IOException erro) {

            System.err.println(
                "Falha ao encaminhar " + pedido.getMetodo() + " "
                + pedido.getCaminho() + ": " + Descricao.de(erro)
            );

            enviarErro(cliente, 502, "Nao foi possivel acessar o backend.");
        }
    }

    // Erro do proprio servidor, no mesmo formato JSON da API
    private void enviarErro(
            Parceiro cliente,
            int status,
            String mensagem) throws IOException {

        String json = "{\"title\":\"Servidor indisponivel\",\"status\":"
                + status + ",\"detail\":\"" + mensagem + "\"}";

        cliente.enviar(
            new RespostaRequisicao(
                status,
                "application/json",
                json.getBytes(java.nio.charset.StandardCharsets.UTF_8)
            )
        );
    }
}
