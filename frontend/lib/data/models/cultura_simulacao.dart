//Representa uma cultura agricola que pode ser selecionada na simulacao de rotacao
class CulturaSimulacao {

    const CulturaSimulacao({
        required this.id,
        required this.nome,
        this.familiaBotanica,
        this.descricao,
        this.fixacaoNitrogenio,
        this.impactoSolo,
        this.repeticaoFamilia,
    });

    // Identificador da cultura
    final String id;

    //Nome da cultura agrícola
    final String nome;

    //Familia botanica da cultura
    final String? familiaBotanica;

    //Indicador de impacto no solo 
    final double? impactoSolo;

    //Indicador relacionado a repeticao da familia botanica
    final double? repeticaoFamilia;
}