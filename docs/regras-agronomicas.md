# Regras Agronômicas — Prontuário Digital do Talhão

**Equipe:** G-14
**Issues relacionadas:** #1 (requisitos), #3 (banco de dados) e #10 (Implementar regras agronômicas)
**Documento complementar:** `01-mvp-e-requisitos.md`
**Versão:** 3 — proposta para validação acadêmica
**Status:** limites de pH, V%, P e K preenchidos a partir do Boletim 100 do IAC. As regras de rotação são critérios do projeto e devem ser validadas por profissional de agronomia antes de qualquer uso operacional.

Este documento define o que o sistema calcula: o **status do solo** de um talhão e a **classificação de cada cenário de rotação**. Toda regra usa apenas os dados da seção 3 e registra sua fonte (RN08).

> **Limite de uso:** especificação acadêmica de apoio à decisão. Não substitui laudo completo, recomendação agronômica ou diagnóstico fitossanitário. O MVP não prescreve doses de calcário ou fertilizantes.

---

## 1. Princípios

- A recomendação é de **rotação e escolha de culturas**. O sistema não calcula doses de calcário ou fertilizantes.
- As faixas de pH, saturação por bases, fósforo e potássio reproduzem a fonte técnica, preservando método, unidade e grupo de cultura.
- A interpretação do fósforo depende do grupo de cultura do Boletim 100. Não aplicar uma única faixa de P a todas as culturas.
- Uma planta que recicla nutrientes não cria esses nutrientes nem garante correção da deficiência.
- Fixação biológica de nitrogênio (FBN) é diferente de ciclagem de nutrientes. A FBN depende da espécie, de microrganismos compatíveis e de nodulação eficiente.
- Tolerar uma limitação não significa corrigi-la.
- Não penalizar uma cultura apenas por pertencer à mesma família botânica da anterior. Riscos fitossanitários só entram quando documentados e avaliáveis com os dados do MVP.
- O resultado é qualitativo: **Recomendado**, **Aceitável** ou **Não recomendado**, com justificativa e fonte. Os rótulos de status **Sem alertas**, **Atenção** e **Risco** são simplificações do projeto, não classes oficiais do IAC.
- Se faltar informação para aplicar uma regra, declarar a limitação (RN09). Se não houver diferença entre os cenários, informar que são equivalentes (RN10).
- **Região de referência:** Estado de São Paulo (Boletim 100). Regras apoiadas em fontes de outras regiões ficam marcadas como regionais e pendentes de validação para São Paulo.

---

## 2. Fontes técnicas

A coluna "Conferência" indica o que foi verificado diretamente. Fontes "a conferir" precisam ser abertas e lidas pelo grupo antes da entrega final.

| ID | Fonte | Usada em | Conferência |
|---|---|---|---|
| F1 | IAC. *Boletim Técnico 100: Recomendações de Adubação e Calagem para o Estado de São Paulo*. 3. ed. Campinas, 2022. https://www.iac.sp.gov.br/publicacoes/boletim100.php | Classes de pH, V%, P e K (seção 4) | Parcial: valores de pH, V%, P e K conferidos em materiais e cópias que reproduzem o Boletim. Tabela de K da edição 2022 e números de página a conferir no livro. |
| F2 | IAC. *Interpretação de resultados de análise de solo* (página técnica). https://www.iac.sp.gov.br/produtoseservicos/analisedosolo/interpretacaoanalise.php | MO e textura (seção 4.2); classes de resposta esperada a N (R3) | Conferida |
| F3 | IAC. *Análise de fertilidade do solo* (página do laboratório). https://www.iac.sp.gov.br/produtoseservicos/analisedosolo/analisefertilidade.php | Parâmetros do laudo de rotina (seção 3) | Conferida |
| F4 | Embrapa. *Indicações Técnicas para a Cultura da Soja no Rio Grande do Sul e em Santa Catarina*, seção "Rotação de culturas". https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/1011192/1/IndicacoesTecnicasEmbrapa003.pdf | R1, R2 | A conferir. Fonte regional (RS e SC). |
| F5 | Embrapa. *Tecnologias de produção de soja 105*, capítulo sobre sistemas de produção e rotação. https://ainfo.cnptia.embrapa.br/digital/bitstream/item/223209/1/SP-17-2020-online-1.pdf | R5 | A conferir. Recomendação de contexto regional específico. |
| F6 | Mercante, F. M. et al. "Fixação biológica de nitrogênio em adubos verdes". In: *Adubação verde e plantas de cobertura no Brasil*. 2. ed. Embrapa, 2023, v. 1, cap. 8. https://www.infoteca.cnptia.embrapa.br/infoteca/handle/doc/1161220 | R4 | A conferir |
| F7 | Alves et al. *Balanço de N em rotação de culturas sob plantio direto em Dourados, MS*. Embrapa Agrobiologia, 2005. | R3 (complementar) | A conferir autoria e dados. Estudo de condição específica (Dourados, MS). |

Fontes de regras fora do MVP estão no Apêndice A.

---

## 3. Dados de entrada

O sistema usa somente estes dados. Nenhuma regra deste documento depende de informação fora desta seção.

### 3.1. Laudo de solo (última análise do talhão)

| Parâmetro | Unidade | Obrigatório | Uso | Precisão para classificar |
|---|---|---|---|---|
| pH em CaCl₂ | sem unidade | Sim | Status | 1 casa decimal |
| Fósforo (P resina) | mg/dm³ | Sim | Status | número inteiro |
| Potássio trocável (K) | mmolc/dm³ | Sim | Status | 1 casa decimal |
| Saturação por bases (V) | % | Sim | Status | número inteiro |
| Matéria orgânica (MO) | g/dm³ | Não | Informativo; não entra no status | — |

Esses parâmetros fazem parte do laudo de rotina do IAC (F3). Antes de classificar, arredondar o valor para a precisão da tabela. Laudos com outro extrator de P, outras unidades ou pH em água não devem ser interpretados por estas faixas sem conversão.

### 3.2. Histórico do talhão

Lista de culturas por safra, em ordem cronológica, com a cultura escolhida no catálogo (seção 5) e a data de plantio. "Safra anterior" é a cultura mais recente registrada antes da data da simulação.

---

## 4. Status do solo

As classes reproduzem o Boletim 100 (F1). O tratamento (crítica, atenção, sem alerta) é uma **regra interna proposta**, a validar com agrônomo.

### 4.1. pH em CaCl₂

| Classe no Boletim 100 | Faixa | Tratamento |
|---|---|---|
| Acidez muito alta | ≤ 4,3 | Crítica |
| Acidez alta | 4,4–5,0 | Atenção |
| Acidez média | 5,1–5,5 | Sem alerta |
| Acidez baixa | 5,6–6,0 | Sem alerta |
| Acidez muito baixa | > 6,0 | Sem alerta |

### 4.2. Saturação por bases (V%)

| Classe no Boletim 100 | Faixa | Tratamento |
|---|---|---|
| Muito baixa | 0–25 | Crítica |
| Baixa | 26–50 | Atenção |
| Média | 51–70 | Sem alerta |
| Alta | 71–90 | Sem alerta |
| Muito alta | > 90 | Sem alerta |

As classes de pH e V% descrevem a acidez, não a qualidade do solo, e a adequação depende da cultura (F2). Por isso as classes média, baixa e muito baixa de pH, e média a muito alta de V%, não geram alerta.

### 4.3. Fósforo (P resina), por grupo de cultura

O MVP usa os dois grupos presentes no catálogo. Perenes e florestais ficam fora.

**Grupo Anuais (soja, feijão, milho, trigo, sorgo)**

| Classe | Faixa (mg/dm³) | Tratamento |
|---|---|---|
| Baixo | < 16 | Atenção |
| Médio | 16–40 | Sem alerta |
| Alto | > 40 | Sem alerta |

**Grupo Hortaliças (batata)**

| Classe | Faixa (mg/dm³) | Tratamento |
|---|---|---|
| Baixo | < 25 | Atenção |
| Médio | 25–60 | Sem alerta |
| Alto | > 60 | Sem alerta |

**Qual grupo usar:** o grupo da **cultura comercial mais recente** do histórico do talhão. Se o histórico não tiver cultura comercial, o P não entra no status e o sistema informa isso.

### 4.4. Potássio trocável (K)

| Classe no Boletim 100 | Faixa (mmolc/dm³) | Tratamento |
|---|---|---|
| Baixo (inclui muito baixo) | < 1,6 | Atenção |
| Médio | 1,6–3,0 | Sem alerta |
| Alto | 3,1–6,0 | Sem alerta |
| Muito alto | > 6,0 | Atenção (possível desequilíbrio com Ca e Mg) |

Para K muito alto, o sistema só sinaliza. Não recomenda planta para "retirar" potássio.

### 4.5. Matéria orgânica (informativa)

A MO não prevê a disponibilidade de nitrogênio no Estado de São Paulo (F2). Serve como indicação de textura: até 15 g/dm³ sugere solo arenoso, 16–30 textura média, 31–60 argiloso, e valores bem acima de 60 indicam acúmulo localizado, por exemplo por má drenagem ou acidez elevada (F2).

- O sistema exibe a MO com essa leitura de textura.
- A MO **não** aciona Atenção ou Risco e **não** estima nitrogênio.

### 4.6. Cálculo do status do talhão

1. Classificar pH, V%, K e P (quando houver grupo) pelas tabelas acima.
2. Qualquer parâmetro com tratamento **Crítica**: **Risco**.
3. Sem crítica, e pelo menos um **Atenção**: **Atenção**.
4. Nenhum alerta: **Sem alertas**, entendido estritamente como "sem alerta nos indicadores avaliados", não como atestado de saúde do solo.
5. Informar quais parâmetros motivaram o status (RF14).

---

## 5. Catálogo de culturas (MVP)

| Cultura | Nome científico | Família | Grupo | Fixa N | Grupo de P | Nota de uso |
|---|---|---|---|---|---|---|
| Soja | *Glycine max* | Fabaceae | Leguminosa | Sim, condicional | Anuais | Controlar histórico de doenças e nematoides. |
| Feijão-comum | *Phaseolus vulgaris* | Fabaceae | Leguminosa | Sim, condicional | Anuais | Pode compartilhar riscos fitossanitários com a soja em certas sucessões (R5). |
| Crotalária | *Crotalaria* spp. | Fabaceae | Leguminosa (adubo verde) | Sim, condicional | — | Escolher a espécie conforme objetivo e região. |
| Milho | *Zea mays* | Poaceae | Gramínea | Não | Anuais | — |
| Trigo | *Triticum aestivum* | Poaceae | Gramínea | Não | Anuais | Cultura de época e região específicas. |
| Sorgo | *Sorghum bicolor* | Poaceae | Gramínea | Não | Anuais | Verificar adaptação regional. |
| Milheto | *Pennisetum glaucum* | Poaceae | Gramínea (cobertura) | Não | — | Uso em sistemas e janelas adaptados. |
| Aveia-preta | *Avena strigosa* | Poaceae | Gramínea (cobertura) | Não | — | Opção de outono-inverno em regiões adequadas. |
| Batata | *Solanum tuberosum* | Solanaceae | Outras | Não | Hortaliças | Consultar histórico fitossanitário fora do sistema. |

"Fixa N, condicional" significa que a FBN depende de nodulação eficiente e de manejo. Culturas sem grupo de P (cobertura) não definem a faixa de fósforo do talhão (seção 4.3).

---

## 6. Regras de rotação

### 6.1. Tipos de efeito

| Efeito | Significado |
|---|---|
| Favorável | O padrão de rotação é considerado positivo |
| Neutra | Sem efeito na classificação; pode trazer mensagem |
| Alerta | Há ponto de atenção, mas a cultura não é descartada |
| Restritiva | A cultura não é recomendada naquela condição |

### 6.2. Regras

Cada regra compara a **cultura candidata** com o histórico do talhão. A coluna "Mensagem" é o texto base mostrado ao produtor (RF19).

| ID | Condição (usa só os dados da seção 3) | Efeito | Mensagem ao produtor | Fonte |
|---|---|---|---|---|
| R1 | Candidata é a mesma cultura da safra anterior | Restritiva | "Esta cultura foi plantada na safra anterior. Repetir a mesma cultura em seguida aumenta o risco de doenças e pragas." | F4 (regional) |
| R2 | Candidata é a mesma cultura de duas safras atrás e diferente da safra anterior | Alerta | "Esta cultura também foi plantada duas safras atrás. Alternar só duas culturas pode manter riscos de pragas e doenças. Considere uma terceira." | F4 (regional) |
| R3 | Safra anterior é leguminosa e candidata é gramínea | Favorável | "A cultura anterior é uma leguminosa. Alternar com uma gramínea diversifica o sistema. Leguminosas no histórico são um fator que o IAC usa para estimar menor resposta ao nitrogênio, e o efeito depende da intensidade do cultivo anterior." | F2, F7 |
| R4 | Safra anterior é gramínea e candidata é leguminosa | Favorável | "A cultura anterior é uma gramínea. Uma leguminosa diversifica o sistema e pode obter parte do nitrogênio por fixação biológica." | F6 |
| R5 | Safra anterior é soja e candidata é feijão-comum | Alerta | "Feijão logo depois de soja: em alguns sistemas, a sucessão imediata aumenta o risco de doenças de raiz e caule. Confirme a orientação para a sua região." | F5 (regional) |
| R6 | Status do talhão é Atenção ou Risco | Neutra (mensagem) | "O solo deste talhão tem [parâmetros] fora da faixa. A escolha da cultura não corrige isso. Procure um agrônomo." | F1 |
| R7 | Histórico sem cultura registrada, ou com apenas uma safra (R2 não avaliável) | Neutra (mensagem) | "Histórico insuficiente: algumas regras não puderam ser avaliadas." | Regra funcional, RN09 |

R6 é aplicada a todos os cenários e não altera a classificação. Nenhuma regra depende de família botânica isolada.

### 6.3. Como o resultado é definido

Para cada cenário, combinar os efeitos das regras aplicáveis:

1. Existe efeito **Restritiva**: **Não recomendado**.
2. Sem restritiva, existe **Alerta**: **Aceitável**, mostrando os alertas.
3. Sem restritiva nem alerta, existe **Favorável**: **Recomendado**.
4. Nenhum dos casos acima: **Aceitável**, sem diferença identificada pelas regras.

**Equivalência (RN10):** se todos os cenários comparados receberem a mesma classificação e a mesma situação quanto a alertas (todos com alerta ou todos sem), informar que as opções são equivalentes segundo os critérios avaliados. Um cenário "Aceitável" com alerta e outro "Aceitável" sem alerta não são equivalentes.

**Justificativa (RF19):** para cada cenário, listar as mensagens das regras acionadas, cada uma com sua fonte, e o aviso de que a recomendação é apoio à decisão (RF20).

### 6.4. Rotação e sucessão

Rotação é a alternância planejada de espécies no tempo. Sucessão é a sequência de culturas em ciclos consecutivos, muitas vezes no mesmo ano agrícola. Alternar duas culturas pode ser rotação em certos sistemas, mas não elimina sozinho os riscos de pragas, doenças ou degradação (por isso R2).

---

## 7. Casos de teste

Servem de base para os testes automatizados do motor de simulação. Histórico listado da safra mais recente para a mais antiga.

| ID | Histórico | Cenários | Resultado esperado |
|---|---|---|---|
| T1 | Soja | Milho, Feijão, Soja | Milho: Recomendado (R3). Feijão: Aceitável com alerta (R5). Soja: Não recomendado (R1). |
| T2 | Milho, Soja | Soja, Feijão, Trigo | Soja: Aceitável com alerta (R4 favorável, R2 alerta). Feijão: Recomendado (R4). Trigo: Aceitável sem diferença. |
| T3 | Vazio | Soja, Milho | Ambos Aceitável com a mensagem de histórico insuficiente (R7). Equivalentes. |
| T4 | Milho | Trigo, Sorgo | Ambos Aceitável sem diferença. Equivalentes. |
| T5 | Laudo: pH 4,2; V 22; P 10; K 1,0. Cultura comercial recente: soja | Status | Risco (pH e V críticos; P e K em atenção). |
| T6 | Laudo: pH 5,3; V 55; P 30; K 2,0. Cultura comercial recente: soja | Status | Sem alertas. |
| T7 | Valores de fronteira, cultura anual: pH 4,3 e 4,4; V 25 e 26; P 15 e 16; K 1,5 e 1,6 | Classes | pH: muito alta e alta. V: muito baixa e baixa. P: baixo e médio. K: baixo e médio. |

---

## 8. Decisões a confirmar pelo grupo

| ID | Decisão adotada nesta versão | Alternativa |
|---|---|---|
| D1 | R1 (repetir a mesma cultura da safra anterior) é **Restritiva**. É a única regra do MVP capaz de gerar "Não recomendado". | Tratar R1 como Alerta. Nesse caso, "Não recomendado" não existe no MVP e o RF18 muda para dois níveis. |
| D2 | **Histórico fitossanitário fora do MVP.** Eventos de praga e doença não entram no histórico, e o protótipo deve ser ajustado. | Incluir o registro de ocorrências e reativar R7 e R8 do Apêndice A, o que adiciona funcionalidade, tabela e tela. |
| D3 | O rótulo **"Sem alertas"** substitui "Saudável" na interface. | Manter "Saudável" e deixar a limitação explícita em texto de ajuda. |
| D4 | Catálogo com **9 culturas**, sem pousio. | Reincluir pousio com regra própria. |
| D5 | MO **informativa e opcional**. Argila fora do MVP. | Reincluir a argila com classes de MO validadas por textura e região. |

Mudanças em relação à versão anterior, com o motivo:
- **V%:** faixas copiadas da fonte (0–25, 26–50, 51–70, 71–90, > 90), sem limites compartilhados.
- **pH médio (5,1–5,5):** deixou de ser Atenção, porque contradizia o V médio sem alerta e a faixa em que soja e milho atingem produção próxima ao máximo.
- **P:** o grupo agora vem da cultura comercial mais recente, porque o status do talhão é calculado sem simulação.
- **Regra de decisão do resultado:** incluída (seção 6.3), pois antes não havia como transformar regras em classificação.
- **Numeração das regras:** R1 (antiga R1, agora restritiva), R2 (antiga R5), R3 e R4 (mantidas, reescritas com mensagem e fonte), R5 (antiga R9), R6 (antiga R6, reduzida a mensagem) e R7 (antiga R10). A antiga R2 (mesma família) virou princípio da seção 1. A antiga R11 virou a regra de equivalência da seção 6.3.

---

## 9. Estrutura sugerida no banco de dados (issue #3)

- **culturas:** `id`, `nome`, `nome_cientifico`, `familia_botanica`, `grupo` (leguminosa/gramínea/outras), `tipo_uso` (comercial/cobertura), `fixa_nitrogenio`, `grupo_p` (anuais/hortaliças/nulo), `nota`.
- **faixas_solo:** `id`, `parametro` (pH/V/P/K), `grupo_p` (nulo exceto para P), `classe_fonte`, `limite_min`, `limite_max`, `tratamento` (critica/atencao/sem_alerta), `fonte_id`, `versao`.
- **regras_rotacao:** `id`, `codigo` (R1 a R7), `condicao`, `efeito`, `mensagem`, `fonte_id` (nulo em regras funcionais, como R7), `escopo_regional`, `status_validacao`.
- **fontes_tecnicas:** `id`, `codigo` (F1 a F7), `titulo`, `autores`, `instituicao`, `ano`, `url`, `escopo_regional`, `conferencia`.

`status_validacao` assume **validada**, **pendente de validação** ou **não aplicável**. Todas as regras de rotação começam como pendentes.

---

## 10. Checklist de validação

- [ ] Conferir no livro oficial do Boletim 100 (3ª edição) as tabelas de pH, V%, P e K, com os números de página.
- [ ] Confirmar a tabela de K da edição 2022 (hoje conferida só na edição anterior).
- [ ] Abrir e ler F4, F5, F6 e F7 e confirmar que sustentam as regras citadas.
- [ ] Confirmar com o grupo as decisões D1 a D5.
- [ ] Declarar a região de referência (São Paulo) no documento final do projeto.
- [ ] Ajustar protótipo e pitch: rótulo "Sem alertas", remoção do card "Nitrogênio" e do evento "Praga identificada", e novo exemplo de recomendação.

