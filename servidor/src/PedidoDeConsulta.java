
/*
 * Representa uma solicitacao autenticada
 * enviada pelo cliente ao servidor Java puro.
 */
public class PedidoDeConsulta extends Comunicado {

    private static final long serialVersionUID = 1L;

    // Tipos de consulta permitidos
    public enum TipoConsulta {
        PROPRIEDADES,
        ANALISES_SOLO
    }

    private final TipoConsulta tipo;
    private final String tokenJwt;

    // Cria um pedido de consulta autenticado
    public PedidoDeConsulta(
            TipoConsulta tipo,
            String tokenJwt) {

        if (tipo == null) {
            throw new IllegalArgumentException(
                "Tipo de consulta obrigatorio."
            );
        }

        if (tokenJwt == null || tokenJwt.isBlank()) {
            throw new IllegalArgumentException(
                "Token JWT obrigatorio."
            );
        }

        this.tipo = tipo;
        this.tokenJwt = tokenJwt.trim();
    }

    // Retorna o tipo da consulta
    public TipoConsulta getTipo() {
        return tipo;
    }

    // Retorna o JWT para encaminhamento ao Spring Boot
    public String getTokenJwt() {
        return tokenJwt;
    }
}
