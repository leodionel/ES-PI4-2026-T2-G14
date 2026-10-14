# Regras Agronômicas — Prontuário Digital do Talhão

**Equipe G-14**
**Issues relacionadas:** #1 (requisitos), #3 (banco de dados) e "Implementar regras agronômicas"
**Status:** estrutura definida; limites numéricos e fontes por regra a preencher e validar

Este documento define o que o sistema usa para calcular o status do solo e para recomendar a próxima cultura. Cada regra precisa ter fonte registrada (RN08).

---

## 1. Princípios

- A recomendação é de **rotação de culturas**. O sistema não recomenda doses de calcário ou adubo.
- Os limites e as regras vêm de fontes oficiais (Embrapa e IAC) e ficam em base própria do sistema.
- Nenhum número deste documento deve ser inventado: todo limite é copiado da tabela da fonte, com referência.
- O resultado é qualitativo (Recomendado, Aceitável, Não recomendado), sem notas numéricas que sugiram uma precisão que não existe.

---

## 2. Fontes

**Interpretação do laudo de solo**
- IAC. *Boletim Técnico 100: Recomendações de Adubação e Calagem para o Estado de São Paulo* (3ª edição, 2022). Fonte principal para as classes de interpretação.
- Embrapa. Apostila *Interpretação de Análises de Solo e Recomendação de Calagem e Adubação*, que reúne o Boletim 100 e boletins de outros estados (acesso gratuito na Infoteca da Embrapa).

**Rotação de culturas e fixação biológica de nitrogênio (fontes candidatas, a ler e extrair a regra)**
- Embrapa Agrobiologia. *Balanço de N em Rotação de Culturas sob Plantio Direto em Dourados, MS* (2005).
- Embrapa. *Sistema Santa Brígida: Consorciação de Milho com Leguminosas* (Circular Técnica 88).
- Embrapa Soja. Resumos da Reunião de Pesquisa de Soja sobre culturas de entressafra e nitrogênio na soja.

Cada regra da seção 6 deve apontar para uma destas fontes (ou outra equivalente) com título, ano e página.

---

## 3. Parâmetros do laudo usados no MVP

| Parâmetro | Unidade (padrão IAC, confirmar no Boletim 100) |
|---|---|
| pH (CaCl₂) | sem unidade |
| Matéria orgânica (MO) | g/dm³ |
| Fósforo (P resina) | mg/dm³ |
| Potássio (K) | mmolc/dm³ |
| Saturação por bases (V%) | % |

Laudos de outros laboratórios podem usar unidades ou métodos diferentes. O formulário deve exibir a unidade esperada ao lado de cada campo.

---

## 4. Classes de interpretação (preencher a partir do Boletim 100)

Para cada parâmetro, copiar da tabela do Boletim 100 os limites de cada classe e marcar como o sistema trata a classe.

| Parâmetro | Classe (nome na fonte) | Limite inferior | Limite superior | Tratamento no sistema | Página/tabela da fonte |
|---|---|---|---|---|---|
| pH (CaCl₂) | | | | adequada / atenção / crítica | |
| MO | | | | adequada / atenção / crítica | |
| P resina | | | | adequada / atenção / crítica | |
| K | | | | adequada / atenção / crítica | |
| V% | | | | adequada / atenção / crítica | |

(Acrescentar uma linha por classe de cada parâmetro.)

**Cálculo do status do talhão (proposta, validar com agrônomo):**
- Qualquer parâmetro em classe crítica: **Risco**
- Qualquer parâmetro em classe de atenção: **Atenção**
- Todos em classe adequada: **Saudável**

O sistema deve informar qual parâmetro motivou o status (RF14).

---

## 5. Catálogo inicial de culturas (confirmar)

| Cultura | Família botânica | Grupo | Fixa nitrogênio |
|---|---|---|---|
| Soja | Fabaceae | Leguminosa | Sim |
| Feijão | Fabaceae | Leguminosa | Sim |
| Crotalária (adubo verde) | Fabaceae | Leguminosa | Sim |
| Milho | Poaceae | Gramínea | Não |
| Trigo | Poaceae | Gramínea | Não |
| Sorgo | Poaceae | Gramínea | Não |
| Aveia-preta (cobertura) | Poaceae | Gramínea | Não |
| Batata | Solanaceae | Outras | Não |
| Pousio | n/a | n/a | n/a |

---

## 6. Regras de rotação (propostas, cada uma precisa de fonte)

| ID | Condição | Efeito | Fonte |
|---|---|---|---|
| R1 | Próxima cultura igual à da safra anterior | Não recomendado | a vincular |
| R2 | Próxima cultura da mesma família da safra anterior (ex: soja seguida de feijão) | Reduz a classificação | a vincular |
| R3 | Safra anterior gramínea e próxima leguminosa | Favorece (aporte de nitrogênio pela fixação biológica) | a vincular |
| R4 | Safra anterior leguminosa e próxima gramínea | Favorece (diversificação de família) | a vincular |
| R5 | Próxima cultura igual à de duas safras atrás (ex: soja, milho, soja) | Alerta de sucessão repetitiva | a vincular |
| R6 | Talhão com status Risco | Destaca pousio ou adubo verde como opção de recuperação | a vincular |

Observação: alternar apenas duas culturas (ex: soja e milho) é sucessão, não rotação plena, e pode manter o desgaste do solo. A regra R5 trata esse caso.

**Como o resultado é montado**
1. Aplicar as regras a cada cenário usando as duas últimas safras do talhão.
2. Classificar cada cenário: Recomendado (regras favoráveis e nenhuma penalidade), Aceitável (sem favorecimento claro ou com penalidade leve) ou Não recomendado (penalidade forte, como R1).
3. Se nenhum cenário se destacar, informar que as opções são equivalentes (RN10).
4. Se faltar histórico para aplicar uma regra, dizer isso na justificativa (RN09).
5. Exibir a justificativa em linguagem simples, com a regra e a fonte (RF19).

---

## 7. Estrutura sugerida no banco (para a issue #3)

- **culturas:** id, nome, familia_botanica, grupo, fixa_nitrogenio
- **faixas_solo:** id, parametro, classe, limite_min, limite_max, tratamento, fonte
- **regras_rotacao:** id, codigo, condicao, efeito, justificativa, fonte, versao

---

## 8. Checklist de validação

- [ ] Tabela da seção 4 preenchida com os limites do Boletim 100 e página da fonte
- [ ] Cada regra da seção 6 com fonte registrada
- [ ] Catálogo da seção 5 confirmado