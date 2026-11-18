package br.com.talhao.dto;

import java.util.List;

// Dados da tela inicial (RF14, RF15 e RF16)
public record DashboardResponse(

    // Nulo enquanto o produtor nao cadastrou a propriedade
    String propriedadeNome,

    int totalTalhoes,

    // Soma da area de todos os talhoes, em hectares
    double areaTotalHa,

    // Sempre os quatro status, nesta ordem:
    // RISCO, ATENCAO, SAUDAVEL e SEM_ANALISE
    List<DistribuicaoStatus> distribuicao,

    // Talhoes em RISCO primeiro, depois ATENCAO, cada grupo por nome
    List<TalhaoEmAlerta> talhoesEmAlerta

) {}
