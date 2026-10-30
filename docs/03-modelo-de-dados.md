# Modelo de Dados (MongoDB) — Prontuário Digital do Talhão

**Equipe G-14** **Issues relacionadas:** #3 (banco de dados) e #10 (regras agronômicas) **Documentos base:** `01-mvp-e-requisitos.md`, `02-regras-agronomicas.md` (seção 9) e `03-guia-frontend.md` (seção 5) **Status:** proposta revisada (v2). Stack: Spring Boot com Spring Data MongoDB (D1, a confirmar com o professor).

## 1. Onde o modelo fica

O MongoDB não guarda esquema: qualquer documento entra em qualquer coleção. O contrato dos dados fica **no código do backend**, como uma classe Java por coleção.

- `record` com `@Document` para coleções; `record` simples para subdocumentos; `enum` para valores fixos (o Spring Data grava enum como texto, sem custo).
- Classes em um pacote `model`, versionadas no Git. Se este documento e as classes divergirem, valem as classes.

## 2. Decisões de modelagem

1. **O histórico mora dentro do talhão.** Plantios e análises são listas embutidas. A linha do tempo, a simulação, o PDF, o status e a contagem do aviso de exclusão (RF22) leem **um** documento, e excluir o talhão apaga o histórico junto (RN12).
2. **Só o dado bruto é guardado.** Tudo que dá para calcular fica fora do banco, para nunca ficar desatualizado.



|O app mostra|Vem de|
|---|---|
|`statusSolo` e `motivosStatus`|Última análise, `faixas_solo` e a regra do `02` (seção 4.6)|
|`culturaAtual`|Plantio mais recente sem `dataColheita` (D2)|
|`ultimaAnalise`|Análise de data mais recente|
|`culturaNome`|Catálogo `culturas`, pelo `culturaId`|
|`leituraMo`|Valor de `mo`, pelas faixas de textura do `02` (seção 4.5)|

## 3. Coleções

|Coleção|Um documento por|Campos|Índices|
|---|---|---|---|
|`usuarios`|produtor|`nome`, `email`, `telefone`, `senhaHash`, `criadoEm`|`email` único|
|`propriedades`|propriedade|`usuarioId`, `nome`, `localizacao`|`usuarioId`|
|`talhoes`|talhão, com histórico|`propriedadeId`, `nome`, `areaHa`, `criadoEm`, `plantios[]`, `analises[]`|`propriedadeId`|
|`culturas`|cultura do catálogo|`nome`, `nomeCientifico`, `familia`, `grupo`, `tipoUso`, `fixaNitrogenio`, `grupoP`, `nota`|só `_id`|
|`faixas_solo`|classe de interpretação|`parametro`, `grupoP`, `classe`, `limiteMin`, `limiteMax`, `tratamento`, `fonteId`, `versao`|só `_id`|
|`regras_rotacao`|regra|`efeito`, `condicao`, `mensagem`, `fonteId`, `escopoRegional`, `statusValidacao`|só `_id`|
|`fontes_tecnicas`|fonte|`titulo`, `autores`, `instituicao`, `ano`, `url`, `escopoRegional`, `conferencia`|só `_id`|

## 4. Classes Java

Uma classe por arquivo, no pacote `model`. Imports omitidos (`org.springframework.data.annotation.Id`, `...mongodb.core.mapping.Document`, `...mongodb.core.index.Indexed`, `java.time.*`, `java.util.List`).

## 5. Faixas de solo: limites inclusivos

O `02` escreve as faixas com `<`, `≤` e `>`. No banco, cada classe usa **limites inclusivos** sobre o valor já arredondado para a precisão da tabela (pH e K com 1 casa, P e V inteiros). A busca fica `limiteMin <= valor <= limiteMax`, com `null` para extremo aberto, e cada valor cai em exatamente uma classe.

|Parâmetro|No `02`|No banco (`limiteMin`, `limiteMax`)|
|---|---|---|
|pH|≤ 4,3|`null`, 4,3|
|pH|> 6,0|6,1, `null`|
|V|> 90|91, `null`|
|P (anuais)|< 16|`null`, 15|
|P (anuais)|> 40|41, `null`|
|K|< 1,6|`null`, 1,5|
|K|> 6,0|6,1, `null`|

Arredondar pH e K com `Math.round(x * 10) / 10.0` (ou a regra do `02`, seção 3.1) antes de comparar, para que 4,3 digitado seja o mesmo `double` de 4,3 no banco.