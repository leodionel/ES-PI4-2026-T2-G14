import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

// Inicia e encerra o servidor
public class Servidor {
    private static final int PORTA_PADRAO = 3000;

    public static void main(String[] args) {
        if (args.length > 1) {
            System.err.println("Uso: java Servidor [porta]");
            return;
        }

        int porta = PORTA_PADRAO;

        if (args.length == 1) {
            try {
                porta = Integer.parseInt(args[0]);
            } catch (NumberFormatException erro) {
                System.err.println("A porta deve ser um numero inteiro.");
                return;
            }
        }

        List<Parceiro> clientes = new ArrayList<>();
        AceitadoraDeConexao aceitadora;

        BackendClient backend =
            new BackendClient("http://localhost:8081");

        try {
            aceitadora = new AceitadoraDeConexao(porta, clientes);
            aceitadora.start();
        } catch (IOException | IllegalArgumentException erro) {
            System.err.println(
                "Nao foi possivel iniciar: " + erro.getMessage()
            );
            return;
        }

        System.out.println("Servidor ativo na porta " + porta);
        System.out.println("Comandos disponiveis: status e desativar.");

        try (Scanner teclado = new Scanner(System.in)) {
            while (teclado.hasNextLine()) {
                String comando = teclado.nextLine().trim();

                if (comando.equalsIgnoreCase("desativar")) {
                    break;
                }

                if (comando.equalsIgnoreCase("status")) {
                    try {
                        String resposta = backend.consultarStatus();

                        System.out.println(
                            "Resposta do backend: " + resposta
                        );
                    } catch (IOException erro) {
                        System.err.println(
                            "Nao foi possivel consultar o backend: "
                                + erro.getMessage()
                        );
                    } catch (InterruptedException erro) {
                        Thread.currentThread().interrupt();
                        System.err.println("Consulta interrompida.");
                        break;
                    }
                } else {
                    System.out.println(
                        "Comando invalido. Digite status ou desativar."
                    );
                }
            }
        } finally {
            desligar(aceitadora, clientes);
        }

        // Encerra também as threads ainda aguardando comunicação
        System.exit(0);
    }

    private static void desligar(
            AceitadoraDeConexao aceitadora,
            List<Parceiro> clientes) {

        // Para de receber novas conexões
        try {
            aceitadora.close();
        } catch (IOException erro) {
            System.err.println(
                "Erro ao fechar a porta: " + erro.getMessage()
            );
        }

        // Copia a lista para liberar o acesso das outras threads
        List<Parceiro> conectados;

        synchronized (clientes) {
            conectados = new ArrayList<>(clientes);
        }

        for (Parceiro cliente : conectados) {
            try {
                cliente.enviar(new ComunicadoDeDesligamento());
            } catch (IOException erro) {
                System.err.println(
                    "Nao foi possivel avisar um cliente."
                );
            } finally {
                try {
                    cliente.close();
                } catch (IOException erro) {
                    System.err.println(
                        "Erro ao fechar a conexao de um cliente."
                    );
                }
            }
        }

        System.out.println("Servidor desativado.");
    }
}