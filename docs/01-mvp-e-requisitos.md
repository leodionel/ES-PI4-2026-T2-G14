# MVP e Requisitos

**Prontuário Digital do Talhão com Simulação de Rotação**
Projeto Integrador IV, Engenharia de Software — Equipe G-14

---

## 1. Visão do projeto

O projeto é um aplicativo mobile para pequenos e médios produtores rurais. Nele o produtor registra o histórico de plantio e as análises de solo de cada talhão, acompanha a evolução em uma linha do tempo e compara cenários de rotação de cultura antes de decidir o próximo plantio.

O sistema é um apoio à decisão baseado em boas práticas de rotação de culturas. Ele não prescreve doses de calcário ou fertilizantes e não substitui o acompanhamento de um engenheiro agrônomo.

## 2. Arquitetura

```
Flutter (app) → Servidor Java (sockets) → API REST (Spring Boot) → MongoDB
```

- **Aplicativo:** Flutter (Dart), para Android e iOS. Exibe os dados e não contém regras agronômicas.
- **Servidor de sockets:** Java, com `ServerSocket`. Recebe as mensagens do aplicativo, encaminha cada requisição à API REST e devolve a resposta. Repassa o token JWT nas requisições autenticadas e não acessa o banco.
- **Backend:** Java com Spring Boot. Expõe a API REST, autentica com JWT, aplica as regras (status do solo e classificação dos cenários) e é o único componente que acessa o banco.
- **Banco de dados:** MongoDB (não relacional).

## 3. Funcionalidades

1. Cadastro, login e recuperação de senha
2. Dashboard da propriedade
3. Cadastro de talhões
4. Registro de culturas por safra
5. Registro de análise de solo
6. Histórico do talhão em linha do tempo
7. Simulação e comparação de cenários de rotação
8. Recomendação de cultura, com justificativa e fonte
9. Exportação do prontuário em PDF
10. Perfil do usuário e logout

## 4. Dados da análise de solo

Os parâmetros seguem a análise química de rotina e as classes de interpretação do Boletim Técnico 100 do IAC (Estado de São Paulo). O detalhamento está no documento `02-regras-agronomicas.md`.

| Campo | Unidade | Uso |
|---|---|---|
| Data da análise | — | Linha do tempo e identificação do último laudo |
| pH (CaCl₂) | — | Status do solo |
| Fósforo (P resina) | mg/dm³ | Status do solo |
| Potássio (K) | mmolc/dm³ | Status do solo |
| Saturação por bases (V) | % | Status do solo |

Todos os campos são obrigatórios. O nitrogênio e a matéria orgânica não fazem parte do laudo do sistema.

## 5. Requisitos funcionais

**Acesso e perfil**
- **RF01** O sistema permite criar uma conta com nome, e-mail, telefone e senha.
- **RF02** O sistema permite login com e-mail e senha.
- **RF03** O sistema permite recuperar a senha por e-mail. Prioridade baixa: é implementado apenas depois dos demais requisitos.
- **RF04** O sistema permite encerrar a sessão.
- **RF05** O sistema permite ver e editar os dados pessoais e os dados da propriedade (nome e localização).

**Talhões**
- **RF06** O sistema permite cadastrar, editar, listar e excluir talhões, informando nome e área em hectares.
- **RF07** A lista de talhões exibe nome, área, cultura atual e status do solo.
- **RF08** Antes de excluir um talhão, o sistema informa quantas safras e análises serão removidas e oferece a exportação do prontuário em PDF.
- **RF09** A exclusão só é confirmada quando o usuário digita o nome do talhão (sem diferenciar maiúsculas e minúsculas e ignorando espaços nas pontas). O servidor repete a validação.

**Histórico**
- **RF10** O sistema permite registrar a cultura plantada em um talhão, com a data de plantio, escolhida em um catálogo.
- **RF11** O sistema permite registrar a colheita de uma cultura.
- **RF12** O sistema permite registrar uma análise de solo com os campos da seção 4.
- **RF13** O sistema exibe o histórico do talhão (culturas, safras e análises) em ordem cronológica.

**Dashboard**
- **RF14** O dashboard exibe a área total da propriedade e a quantidade de talhões.
- **RF15** O dashboard exibe a distribuição dos talhões por status do solo.
- **RF16** O dashboard lista os talhões que precisam de atenção e o parâmetro que motivou o status.

**Simulação e recomendação**
- **RF17** O usuário escolhe um talhão e de 2 a 3 culturas do catálogo para comparar como próxima cultura.
- **RF18** O sistema exibe os cenários lado a lado.
- **RF19** O sistema classifica cada cenário como Recomendado, Aceitável ou Não recomendado e apresenta a justificativa em linguagem simples.
- **RF20** A justificativa informa a regra aplicada e a fonte técnica.
- **RF21** A tela de simulação exibe o aviso de que a recomendação é apoio à decisão e não substitui um agrônomo.

**Exportação**
- **RF22** O sistema exporta o histórico completo de um talhão em PDF.

## 6. Regras de negócio

- **RN01** A simulação compara no mínimo 2 e no máximo 3 cenários.
- **RN02** O status do solo é calculado a partir da última análise do talhão: Risco, Atenção ou Saudável. "Saudável" significa apenas que nenhum indicador avaliado acendeu alerta, e a interface explica isso em um texto de ajuda. Talhão sem análise tem o status Sem análise. As regras de cálculo estão no `02`.
- **RN03** Repetir a mesma cultura da safra anterior não é recomendado. A família botânica, por si só, não altera a classificação.
- **RN04** A alternância entre leguminosas e gramíneas é favorecida.
- **RN05** A simulação considera as duas últimas safras do talhão.
- **RN06** Cada produtor acessa apenas os dados da própria propriedade.
- **RN07** Todos os dados são informados manualmente pelo produtor.
- **RN08** Toda regra de recomendação tem uma fonte técnica registrada.
- **RN09** Quando o histórico é insuficiente para aplicar uma regra, a justificativa informa isso.
- **RN10** Quando nenhum cenário se destaca, o sistema informa que as opções são equivalentes.
- **RN11** No MVP, cada produtor tem uma única propriedade.
- **RN12** Excluir um talhão remove definitivamente o histórico dele.

## 7. Requisitos não funcionais

- **RNF01 Usabilidade:** interface simples, com poucos elementos por tela, botões grandes e textos claros.
- **RNF02 Plataforma:** aplicativo Flutter para Android e iOS, comunicando-se com o servidor por sockets TCP.
- **RNF03 Segurança:** senhas com hash BCrypt e rotas protegidas por token JWT.
- **RNF04 Isolamento de dados:** um usuário não acessa dados de outro.
- **RNF05 Idioma:** interface em português do Brasil.
- **RNF06 Transparência:** o produtor consegue entender por que uma cultura foi recomendada.
- **RNF07 Rastreabilidade:** a base de regras guarda a fonte de cada regra.
- **RNF08 Extensibilidade:** a propriedade é uma entidade própria vinculada ao usuário, e os talhões pertencem à propriedade. Permitir várias propriedades por conta no futuro não exige reestruturar os dados.