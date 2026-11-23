// Contribuição: Matheus Rosini
// RA: 25015832

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
            new BackendClient(
                System.getenv().getOrDefault("BACKEND_URL", "http://localhost:8081")
            );

        try {
            aceitadora = new AceitadoraDeConexao(porta, clientes);
            aceitadora.start();
        } catch (java.net.BindException erro) {
            System.err.println(
                "A porta " + porta + " ja esta em uso."
            );
            System.err.println(
                "Ja existe um servidor rodando (talvez o do comando "
                + "run-backend, em outro terminal). Use so um deles."
            );
            System.err.println(
                "Se ficou um container antigo ligado: docker rm -f servidor-talhao"
            );
            return;
        } catch (IOException | IllegalArgumentException erro) {
            System.err.println(
                "Nao foi possivel iniciar: " + erro.getMessage()
            );
            return;
        }

        System.out.println("Servidor ativo na porta " + porta);

        // Porta HTTP usada so pelo Flutter Web (o navegador nao abre socket)
        PortaHttp portaHttp = iniciarPortaHttp(backend);
        System.out.println("Comandos disponiveis: status e desativar.");

        // Fica falso quando nao ha teclado (ex.: container sem terminal)
        boolean desativar = false;

        try (Scanner teclado = new Scanner(System.in)) {
            while (teclado.hasNextLine()) {
                String comando = teclado.nextLine().trim();

                if (comando.equalsIgnoreCase("desativar")) {
                    desativar = true;
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
                                + Descricao.de(erro)
                        );
                    } catch (InterruptedException erro) {
                        Thread.currentThread().interrupt();
                        System.err.println("Consulta interrompida.");
                        desativar = true;
                        break;
                    }
                } else {
                    System.out.println(
                        "Comando invalido. Digite status ou desativar."
                    );
                }
            }

            // Sem teclado o servidor nao deve encerrar: continua atendendo
            // ate o processo ser parado
            if (!desativar) {
                try {
                    aceitadora.join();
                } catch (InterruptedException erro) {
                    Thread.currentThread().interrupt();
                }
            }
        } finally {
            if (portaHttp != null) {
                portaHttp.close();
            }

            desligar(aceitadora, clientes);
        }

        // Encerra também as threads ainda aguardando comunicação
        System.exit(0);
    }

    // HTTP_PORT define a porta (padrao 3001); 0 desativa. Se a porta estiver
    // ocupada, avisa e segue: o socket, que e o principal, continua valendo.
    private static PortaHttp iniciarPortaHttp(BackendClient backend) {

        int portaHttp;

        try {
            portaHttp = Integer.parseInt(
                System.getenv().getOrDefault("HTTP_PORT", "3001")
            );
        } catch (NumberFormatException erro) {
            System.err.println("HTTP_PORT invalida. Porta HTTP desativada.");
            return null;
        }

        if (portaHttp == 0) {
            return null;
        }

        try {
            PortaHttp porta = new PortaHttp(
                portaHttp,
                java.net.InetAddress.getByName(
                    System.getenv().getOrDefault("BIND_ADDRESS", "127.0.0.1")
                ),
                backend
            );

            porta.start();
            System.out.println(
                "Porta HTTP para o Flutter Web ativa na porta " + portaHttp
            );

            return porta;

        } catch (IOException | IllegalArgumentException erro) {
            System.err.println(
                "Porta HTTP " + portaHttp + " indisponivel ("
                + Descricao.de(erro) + "). O Flutter Web nao vai conectar; "
                + "o app no celular continua funcionando."
            );

            return null;
        }
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