# MVP e Requisitos — Prontuário Digital do Talhão com Simulação de Rotação

**Equipe G-14:** Leonardo Dionel, Lucas Kendi, Matheus Rosini, Matheus Teixeira, Demetrius Valverde
**Issue relacionada:** #1 — Definir o MVP e requisitos
**Versão:** 2 — protótipo substituído por especificação definitiva (regras e laudo de solo revisados)
**Documento complementar:** `02-regras-agronomicas.md`

---

## 1. Visão do produto

Sistema web que permite ao pequeno e médio produtor rural registrar o histórico de plantio e as análises de solo de cada talhão, visualizar essa evolução em uma linha do tempo e comparar cenários de rotação de cultura antes de decidir o próximo plantio.

**Público-alvo:** pequenos e médios produtores rurais, especialmente agricultura familiar, com baixa familiaridade com sistemas agrícolas complexos.

**Foco do MVP:** simplicidade, organização e apoio à decisão.

**Natureza da recomendação:** o sistema oferece apoio à decisão baseado em boas práticas de rotação de culturas. Não substitui o acompanhamento de um engenheiro agrônomo.

---

## 2. Escopo do MVP

1. Cadastro, login e recuperação de senha
2. Dashboard (visão geral da propriedade)
3. Cadastro de talhões
4. Registro de culturas por safra
5. Registro de análise do solo (parâmetros definidos na seção 3)
6. Consulta ao histórico do talhão (linha do tempo)
7. Simulação e comparação de cenários de rotação
8. Recomendação de cultura baseada em regras documentadas e com fonte
9. Exportação do prontuário em PDF
10. Gestão de perfil e logout

---

## 3. Dados da análise de solo

Os parâmetros seguem a análise química de rotina e as classes de interpretação do Boletim Técnico 100 do IAC (referência: Estado de São Paulo). O detalhamento está em `02-regras-agronomicas.md`.

| Parâmetro | Obrigatório | Usado em |
|---|---|---|
| Data da análise | Sim | Linha do tempo e "último laudo" |
| pH (CaCl₂) | Sim | Status do solo |
| Matéria orgânica (MO) | Sim | Status do solo |
| Fósforo (P resina) | Sim | Status do solo |
| Potássio (K) | Sim | Status do solo |
| Saturação por bases (V%) | Sim | Status do solo |

**Nitrogênio não é campo do laudo.** O nitrogênio não é avaliado pela análise de solo de rotina. O efeito de nitrogênio na rotação é tratado pelas regras de alternância entre leguminosas e gramíneas, com base no histórico de culturas.

---

## 4. Requisitos funcionais

### Acesso e perfil
- **RF01** — O sistema deve permitir que o produtor crie uma conta informando nome, e-mail, telefone e senha.
- **RF02** — O sistema deve permitir login com e-mail e senha.
- **RF03** — O sistema deve permitir a recuperação de senha enviando um email para a conta cadastrada.
- **RF04** — O sistema deve permitir encerrar a sessão (logout).
- **RF05** — O sistema deve permitir visualizar e editar os dados pessoais e os dados da propriedade (nome e localização).

### Talhões
- **RF06** — O sistema deve permitir cadastrar, editar, listar e excluir talhões, informando nome e área em hectares.
- **RF07** — O sistema deve exibir a lista de talhões com nome, área, cultura atual e indicador de status do solo.
- **RF22** — Antes de excluir um talhão, o sistema deve informar quantas safras e análises de solo serão removidas junto com ele e oferecer a exportação do prontuário em PDF (RF21).
- **RF23** — A exclusão de um talhão só deve ser confirmada quando o usuário digitar o nome exato do talhão, sem diferenciar maiúsculas de minúsculas e ignorando espaços nas pontas. A validação deve ser feita também no servidor.

### Histórico
- **RF08** — O sistema deve permitir registrar a cultura plantada em um talhão por safra, com data de plantio, escolhendo a cultura em um catálogo pré-cadastrado.
- **RF09** — O sistema deve permitir registrar a colheita de uma cultura.
- **RF10** — O sistema deve permitir registrar uma análise de solo informando os parâmetros obrigatórios da seção 3.
- **RF11** — O sistema deve exibir o histórico de cada talhão em linha do tempo cronológica (culturas, safras e análises de solo).

### Dashboard
- **RF12** — O sistema deve exibir a área total da propriedade e a quantidade de talhões.
- **RF13** — O sistema deve exibir a distribuição dos talhões por status do solo (saudável, atenção, risco).
- **RF14** — O sistema deve listar os talhões que precisam de atenção, informando qual parâmetro do solo motivou o status.

### Simulação e recomendação
- **RF15** — O sistema deve permitir escolher um talhão para simulação.
- **RF16** — O sistema deve permitir selecionar de 2 a 3 culturas do catálogo para comparar como próxima cultura.
- **RF17** — O sistema deve exibir a comparação lado a lado dos cenários selecionados.
- **RF18** — O sistema deve classificar cada cenário como Recomendado, Aceitável ou Não recomendado e apresentar a justificativa em linguagem simples.
- **RF19** — O sistema deve informar, na justificativa, qual regra foi aplicada e a fonte técnica dela.
- **RF20** — O sistema deve exibir, na tela de simulação, o aviso de que a recomendação é apoio à decisão e não substitui um agrônomo.

### Exportação
- **RF21** — O sistema deve permitir exportar o histórico completo de um talhão em PDF.

---

## 5. Regras de negócio

- **RN01** — A simulação compara no mínimo 2 e no máximo 3 cenários por vez.
- **RN02** — O status do solo (saudável, atenção, risco) é calculado a partir da última análise de solo cadastrada, usando as classes de interpretação do Boletim 100 (IAC). Regra proposta: qualquer parâmetro em classe crítica resulta em Risco; qualquer parâmetro em classe de atenção resulta em Atenção; caso contrário, Saudável. Os limites exatos estão em `02-regras-agronomicas.md`.
- **RN03** — A recomendação não favorece repetir a mesma cultura nem a mesma família botânica da safra anterior.
- **RN04** — A recomendação favorece a alternância entre leguminosas (fixam nitrogênio) e gramíneas.
- **RN05** — A recomendação considera as duas últimas safras do talhão para evitar sucessão repetitiva de apenas duas culturas.
- **RN06** — Cada produtor acessa apenas os dados da sua própria propriedade.
- **RN07** — Todos os dados são inseridos manualmente pelo produtor.
- **RN08** — Toda regra de recomendação deve ter uma fonte técnica registrada (Embrapa, IAC ou equivalente).
- **RN09** — Se o talhão não tiver histórico suficiente para aplicar uma regra, o sistema informa isso na justificativa em vez de assumir um resultado.
- **RN10** — Se nenhum cenário se destacar pelas regras, o sistema informa que as opções são equivalentes.
- **RN11** — No MVP, cada produtor possui uma única propriedade.
- **RN12** — A exclusão de um talhão remove definitivamente o histórico dele (culturas, safras e análises de solo).

---

## 6. Requisitos não funcionais

- **RNF01 — Usabilidade:** interface simples, poucos elementos por tela, botões grandes e textos claros, pensada para usuários com baixa familiaridade digital.
- **RNF02 — Plataforma:** aplicação web acessível pelos navegadores atuais, com layout que funcione em desktop (prioridade) e em tela de celular.
- **RNF03 — Segurança:** senhas armazenadas com hash (nunca em texto puro) e rotas protegidas por autenticação.
- **RNF04 — Isolamento de dados:** um usuário não pode acessar dados de outro.
- **RNF05 — Idioma:** interface em português do Brasil.
- **RNF06 — Transparência:** o produtor deve conseguir entender por que uma cultura foi recomendada (RF19).
- **RNF07 — Rastreabilidade das regras:** a base de regras guarda a fonte e a versão de cada regra.
- **RNF08 — Extensibilidade de propriedades:** a propriedade deve ser uma entidade própria no banco, vinculada ao usuário, e os talhões devem pertencer à propriedade. Assim, permitir várias propriedades por conta no futuro não exige reestruturar os dados. No MVP, a interface e a API tratam a propriedade como única.

---

## 7. Decisões tomadas

| Decisão | Resultado |
|---|---|
| Origem das regras de recomendação | Base própria, construída a partir de fontes oficiais (Embrapa e IAC), sem integração em tempo real |
| Nitrogênio como campo do laudo | Removido |
| Parâmetros do laudo | pH, MO, P, K e V% |
| Saída da recomendação | Recomendado / Aceitável / Não recomendado, sem notas numéricas |
| Doses de calagem e adubação | Fora do escopo |
| Propriedades por usuário | Uma no MVP, com o modelo de dados preparado para várias no futuro |
| Exclusão de talhão | Definitiva, com aviso do que será removido e confirmação digitando o nome exato. Alternativa registrada: arquivamento (exclusão lógica), a reavaliar se sobrar tempo |

---

## 8. Rastreabilidade (requisito → funcionalidade da lista)

| Funcionalidade | Requisitos |
|---|---|
| 1. Cadastro e Login | RF01, RF02, RF03 |
| 2. Dashboard | RF12, RF13, RF14 |
| 3. Cadastro de Talhões | RF06, RF07, RF22, RF23 |
| 4. Registro de Culturas | RF08, RF09 |
| 5. Registro de Análise do Solo | RF10 |
| 6. Consulta ao Histórico | RF11 |
| 7. Simulação e Comparação | RF15, RF16, RF17 |
| 8. Recomendação de Cultura | RF18, RF19, RF20 |
| 9. Exportação do Prontuário | RF21 |
| 10. Gestão de Perfil | RF04, RF05 |
