
/*
 * Representa a resposta de uma consulta autenticada
 * realizada pelo servidor Java puro no Spring Boot.
 *
 * O conteudo pode ser:
 * - JSON com as propriedades do usuario;
 * - JSON com as analises de solo;
 * - Mensagem de erro caso a consulta falhe.
 */
public class RespostaDeConsulta extends Comunicado {

    private static final long serialVersionUID = 1L;

    // Indica se a consulta foi realizada com sucesso
    private final boolean sucesso;

    // Armazena o JSON retornado ou uma mensagem de erro
    private final String conteudo;

    // Construtor da resposta
    public RespostaDeConsulta(
            boolean sucesso,
            String conteudo) {

        this.sucesso = sucesso;
        this.conteudo = conteudo == null ? "" : conteudo;
    }

    // Informa se a consulta foi bem-sucedida
    public boolean isSucesso() {
        return sucesso;
    }

    // Retorna os dados da consulta ou mensagem de erro
    public String getConteudo() {
        return conteudo;
    }
}
