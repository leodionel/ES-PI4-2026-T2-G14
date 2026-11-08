public class RespostaDeStatus extends Comunicado {

    private static final long serialVersionUID = 1L;

    // Indica se a consulta foi realizada com sucesso
    private final boolean sucesso;

    // Armazena a resposta do backend ou mensagem de erro
    private final String mensagem;

    // Construtor da resposta
    public RespostaDeStatus(boolean sucesso, String mensagem) {

        this.sucesso = sucesso;
        this.mensagem = mensagem == null ? "" : mensagem;
    }

    // Informa se a consulta funcionou
    public boolean isSucesso() {
        return sucesso;
    }

    // Retorna o conteudo da resposta
    public String getMensagem() {
        return mensagem;
    }
}
