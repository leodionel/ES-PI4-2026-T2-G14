/*
 * Resposta do Spring Boot a uma PedidoRequisicao.
 * Repassa o codigo HTTP, o tipo do conteudo e o corpo sem alterar.
 */
public class RespostaRequisicao extends Comunicado {

    private static final long serialVersionUID = 1L;

    private final int status;
    private final String tipoConteudo;
    private final byte[] corpo;

    public RespostaRequisicao(
            int status,
            String tipoConteudo,
            byte[] corpo) {

        this.status = status;
        this.tipoConteudo = tipoConteudo == null ? "" : tipoConteudo;
        this.corpo = corpo == null ? new byte[0] : corpo;
    }

    // Codigo HTTP devolvido pela API (ex.: 200, 401, 409)
    public int getStatus() {
        return status;
    }

    public String getTipoConteudo() {
        return tipoConteudo;
    }

    public byte[] getCorpo() {
        return corpo;
    }
}
