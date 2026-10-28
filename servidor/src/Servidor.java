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
        System.out.println("Digite desativar para encerrar.");

        try (Scanner teclado = new Scanner(System.in)) {
            while (teclado.hasNextLine()) {
                String comando = teclado.nextLine().trim();

                if (comando.equalsIgnoreCase("desativar")) {
                    break;
                }

                System.out.println(
                    "Comando invalido. Digite desativar."
                );
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

        // Copia a lista para não bloquear sua atualização durante os envios
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