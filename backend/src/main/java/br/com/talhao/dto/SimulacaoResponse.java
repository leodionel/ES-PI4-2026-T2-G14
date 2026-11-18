package br.com.talhao.dto;

import java.util.List;

// Resposta da simulacao: cenarios lado a lado e o contexto usado
public record SimulacaoResponse(

        String talhaoId,

        // Status do solo na data da simulacao
        StatusSoloResponse statusSolo,

        // Nomes das ultimas safras consideradas, da mais recente para a mais antiga
        List<String> historicoConsiderado,

        List<CenarioResponse> cenarios,

        // Verdadeiro quando as regras nao diferenciam os cenarios (RN10)
        boolean opcoesEquivalentes,
        String mensagemEquivalencia,

        // Aviso de apoio a decisao (RF21)
        String aviso
) {}
