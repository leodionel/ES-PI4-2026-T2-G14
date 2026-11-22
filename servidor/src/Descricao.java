// Texto de um erro para o log. Algumas excecoes de rede vem sem mensagem
// (aparecia "Falha ao encaminhar ...: null"), entao inclui o tipo.
final class Descricao {

    private Descricao() {}

    static String de(Throwable erro) {

        String mensagem = erro.getMessage();

        if (mensagem == null || mensagem.isBlank()) {
            return erro.getClass().getSimpleName();
        }

        return erro.getClass().getSimpleName() + ": " + mensagem;
    }
}
