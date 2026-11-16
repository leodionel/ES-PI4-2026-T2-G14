# Regras Agronômicas

**Prontuário Digital do Talhão com Simulação de Rotação**
Projeto Integrador IV, Engenharia de Software — Equipe G-14

---

Este documento define o que o sistema calcula: o status do solo de um talhão e a classificação de cada cenário de rotação. As regras usam apenas os dados da seção 3.

O sistema é um apoio à decisão de caráter acadêmico. Não substitui laudo completo nem recomendação agronômica e não calcula doses de calcário ou fertilizantes. A região de referência é o Estado de São Paulo.

## 1. Princípios

- A recomendação trata de rotação e escolha de culturas.
- As faixas de pH, V%, P e K reproduzem a fonte técnica, com o mesmo método e a mesma unidade.
- A interpretação do fósforo depende do grupo de cultura. Não existe uma faixa única para todas.
- Pertencer à mesma família botânica da cultura anterior não penaliza uma cultura. Só repetir a mesma cultura conta.
- Fixação biológica de nitrogênio depende da espécie e da nodulação, e não é o mesmo que ciclagem de nutrientes.
- O resultado é qualitativo: Recomendado, Aceitável ou Não recomendado, sempre com justificativa e fonte.

## 2. Fontes técnicas

| ID | Fonte | Usada em | Abrangência |
|---|---|---|---|
| F1 | IAC. *Boletim Técnico 100: Recomendações de Adubação e Calagem para o Estado de São Paulo*. 3. ed. Campinas, 2022. https://www.iac.sp.gov.br/publicacoes/boletim100.php | Classes de pH, V%, P e K | São Paulo |
| F2 | IAC. *Interpretação de resultados de análise de solo*. https://www.iac.sp.gov.br/produtoseservicos/analisedosolo/interpretacaoanalise.php | R3 | São Paulo |
| F3 | IAC. *Análise de fertilidade do solo*. https://www.iac.sp.gov.br/produtoseservicos/analisedosolo/analisefertilidade.php | Parâmetros do laudo | São Paulo |
| F4 | Embrapa. *Indicações Técnicas para a Cultura da Soja no Rio Grande do Sul e em Santa Catarina*, seção "Rotação de culturas". https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/1011192/1/IndicacoesTecnicasEmbrapa003.pdf | R1, R2 | RS e SC |
| F5 | Embrapa. *Tecnologias de produção de soja 105*, capítulo sobre sistemas de produção e rotação. https://ainfo.cnptia.embrapa.br/digital/bitstream/item/223209/1/SP-17-2020-online-1.pdf | R5 | Regional |
| F6 | Mercante, F. M. et al. "Fixação biológica de nitrogênio em adubos verdes". In: *Adubação verde e plantas de cobertura no Brasil*. 2. ed. Embrapa, 2023, v. 1, cap. 8. https://www.infoteca.cnptia.embrapa.br/infoteca/handle/doc/1161220 | R4 | Brasil |
| F7 | Alves et al. *Balanço de N em rotação de culturas sob plantio direto em Dourados, MS*. Embrapa Agrobiologia, 2005. | R3 | Mato Grosso do Sul |

## 3. Dados de entrada

### 3.1. Laudo de solo

O sistema usa a última análise do talhão.

| Parâmetro | Unidade | Precisão ao classificar |
|---|---|---|
| pH em CaCl₂ | — | 1 casa decimal |
| Fósforo (P resina) | mg/dm³ | número inteiro |
| Potássio trocável (K) | mmolc/dm³ | 1 casa decimal |
| Saturação por bases (V) | % | número inteiro |

Antes de classificar, o valor é arredondado para a precisão da tabela. Laudos com outro extrator de P, outras unidades ou pH em água não devem ser interpretados por estas faixas.

### 3.2. Histórico do talhão

Lista de culturas por safra, em ordem cronológica, com a cultura do catálogo (seção 5) e a data de plantio. A "safra anterior" é a cultura mais recente registrada antes da data da simulação.

## 4. Status do solo

As classes reproduzem o Boletim 100 (F1). O tratamento de cada classe (crítica, atenção ou sem alerta) é uma regra interna do projeto.

### 4.1. pH em CaCl₂

| Classe | Faixa | Tratamento |
|---|---|---|
| Acidez muito alta | ≤ 4,3 | Crítica |
| Acidez alta | 4,4 a 5,0 | Atenção |
| Acidez média | 5,1 a 5,5 | Sem alerta |
| Acidez baixa | 5,6 a 6,0 | Sem alerta |
| Acidez muito baixa | > 6,0 | Sem alerta |

### 4.2. Saturação por bases (V%)

| Classe | Faixa | Tratamento |
|---|---|---|
| Muito baixa | 0 a 25 | Crítica |
| Baixa | 26 a 50 | Atenção |
| Média | 51 a 70 | Sem alerta |
| Alta | 71 a 90 | Sem alerta |
| Muito alta | > 90 | Sem alerta |

### 4.3. Fósforo (P resina), por grupo de cultura

Grupo Anuais (soja, feijão, milho, trigo, sorgo):

| Classe | Faixa (mg/dm³) | Tratamento |
|---|---|---|
| Baixo | < 16 | Atenção |
| Médio | 16 a 40 | Sem alerta |
| Alto | > 40 | Sem alerta |

Grupo Hortaliças (batata):

| Classe | Faixa (mg/dm³) | Tratamento |
|---|---|---|
| Baixo | 0 a 25 | Atenção |
| Médio | 26 a 60 | Sem alerta |
| Alto | > 60 | Sem alerta |

O grupo usado é o da cultura comercial mais recente do talhão. Se o histórico não tem cultura comercial, o fósforo não entra no status e o sistema informa isso.

### 4.4. Potássio trocável (K)

| Classe | Faixa (mmolc/dm³) | Tratamento |
|---|---|---|
| Baixo | < 1,6 | Atenção |
| Médio | 1,6 a 3,0 | Sem alerta |
| Alto | 3,1 a 6,0 | Sem alerta |
| Muito alto | > 6,0 | Atenção |

Para K muito alto o sistema apenas sinaliza o possível desequilíbrio com cálcio e magnésio.

### 4.5. Cálculo do status

1. Talhão sem nenhuma análise: **Sem análise**.
2. Classificar pH, V%, K e P (quando houver grupo) pelas tabelas acima.
3. Algum parâmetro em classe crítica: **Risco**.
4. Sem classe crítica e com ao menos um parâmetro em atenção: **Atenção**.
5. Nenhum alerta: **Saudável**, no sentido de "sem alerta nos indicadores avaliados".
6. O sistema informa os parâmetros que motivaram o status.

Saudável, Atenção e Risco só aparecem a partir da primeira análise.

## 5. Catálogo de culturas

| Cultura | Nome científico | Família | Grupo | Fixa N | Grupo de P |
|---|---|---|---|---|---|
| Soja | *Glycine max* | Fabaceae | Leguminosa | Sim | Anuais |
| Feijão-comum | *Phaseolus vulgaris* | Fabaceae | Leguminosa | Sim | Anuais |
| Crotalária | *Crotalaria* spp. | Fabaceae | Leguminosa (adubo verde) | Sim | — |
| Milho | *Zea mays* | Poaceae | Gramínea | Não | Anuais |
| Trigo | *Triticum aestivum* | Poaceae | Gramínea | Não | Anuais |
| Sorgo | *Sorghum bicolor* | Poaceae | Gramínea | Não | Anuais |
| Milheto | *Pennisetum glaucum* | Poaceae | Gramínea (cobertura) | Não | — |
| Aveia-preta | *Avena strigosa* | Poaceae | Gramínea (cobertura) | Não | — |
| Batata | *Solanum tuberosum* | Solanaceae | Outras | Não | Hortaliças |

Culturas de cobertura não definem o grupo de fósforo do talhão.

## 6. Regras de rotação

### 6.1. Efeitos

| Efeito | Significado |
|---|---|
| Favorável | O padrão de rotação é positivo |
| Neutra | Não altera a classificação; pode trazer uma mensagem |
| Alerta | Há um ponto de atenção, mas a cultura não é descartada |
| Restritiva | A cultura não é recomendada naquela condição |

### 6.2. Regras

Cada regra compara a cultura candidata com o histórico do talhão.

| ID | Condição | Efeito | Mensagem ao produtor | Fonte |
|---|---|---|---|---|
| R1 | A candidata é a mesma cultura da safra anterior | Restritiva | "Esta cultura foi plantada na safra anterior. Repetir a mesma cultura em seguida aumenta o risco de doenças e pragas." | F4 |
| R2 | A candidata é a mesma cultura de duas safras atrás e diferente da safra anterior | Alerta | "Esta cultura também foi plantada duas safras atrás. Alternar só duas culturas pode manter riscos de pragas e doenças. Considere uma terceira." | F4 |
| R3 | A safra anterior é leguminosa e a candidata é gramínea | Favorável | "A cultura anterior é uma leguminosa. Alternar com uma gramínea diversifica o sistema." | F2, F7 |
| R4 | A safra anterior é gramínea e a candidata é leguminosa | Favorável | "A cultura anterior é uma gramínea. Uma leguminosa diversifica o sistema e pode obter parte do nitrogênio por fixação biológica." | F6 |
| R5 | A safra anterior é soja e a candidata é feijão-comum | Alerta | "Feijão logo depois de soja: em alguns sistemas, a sucessão imediata aumenta o risco de doenças de raiz e caule. Confirme a orientação para a sua região." | F5 |
| R6 | O status do talhão é Atenção ou Risco | Neutra | "O solo deste talhão tem [parâmetros] fora da faixa. A escolha da cultura não corrige isso." | F1 |
| R7 | O histórico não tem cultura registrada ou tem só uma safra | Neutra | "Histórico insuficiente: algumas regras não puderam ser avaliadas." | Regra funcional |

A R6 é aplicada a todos os cenários e não altera a classificação.

### 6.3. Resultado do cenário

Para cada cenário, combinam-se os efeitos das regras aplicáveis:

1. Existe efeito Restritiva: **Não recomendado**.
2. Sem Restritiva, existe Alerta: **Aceitável**, com os alertas exibidos.
3. Sem Restritiva nem Alerta, existe Favorável: **Recomendado**.
4. Nenhum dos casos acima: **Aceitável**, sem diferença identificada pelas regras.

Se todos os cenários recebem a mesma classificação e a mesma situação quanto a alertas (todos com alerta ou todos sem), o sistema informa que as opções são equivalentes. Cada cenário lista as mensagens das regras acionadas, com a fonte de cada uma, e o aviso de que a recomendação é apoio à decisão.

## 7. Casos de teste

O histórico é listado da safra mais recente para a mais antiga.

| ID | Histórico | Entrada | Resultado esperado |
|---|---|---|---|
| T1 | Soja | Milho, Feijão, Soja | Milho: Recomendado (R3). Feijão: Aceitável com alerta (R5). Soja: Não recomendado (R1). |
| T2 | Milho, Soja | Soja, Feijão, Trigo | Soja: Aceitável com alerta (R4 favorável, R2 alerta). Feijão: Recomendado (R4). Trigo: Aceitável, sem diferença. |
| T3 | Vazio | Soja, Milho | Ambos Aceitável, com a mensagem de histórico insuficiente (R7). Equivalentes. |
| T4 | Milho | Trigo, Sorgo | Ambos Aceitável, sem diferença. Equivalentes. |
| T5 | pH 4,2; V 22; P 10; K 1,0. Última cultura comercial: soja | Status | Risco (pH e V críticos; P e K em atenção). |
| T6 | pH 5,3; V 55; P 30; K 2,0. Última cultura comercial: soja | Status | Saudável. |
| T7 | Cultura anual. pH 4,3 e 4,4; V 25 e 26; P 15 e 16; K 1,5 e 1,6 | Classes | pH: muito alta e alta. V: muito baixa e baixa. P: baixo e médio. K: baixo e médio. |