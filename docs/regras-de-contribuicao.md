# Convenções de Git — Prontuário Digital do Talhão (G-14)

Este guia define como nomeamos **branches**, **commits**, **Pull Requests** e **issues** neste projeto. O objetivo é manter o histórico legível e fazer cada mudança apontar para a issue que a originou.

Resumo rápido:

| Item | Formato | Exemplo |
|---|---|---|
| Branch | `tipo-numero-da-issue-descricao-curta` | `feat-6-api-talhoes` |
| Commit | `tipo(escopo): descrição` | `feat(talhao): adiciona endpoint de cadastro` |
| Rodapé do commit | `Refs #N` | `Refs #6` |
| Pull Request | título igual ao commit + `Closes #N` na descrição | `Closes #6` |
| Issue | `[Área] Descrição` | `[Backend] Desenvolver API de talhões` |

---

## 1. Commits (Conventional Commits)

### Formato

```
tipo(escopo): descrição curta

Corpo opcional explicando o porquê da mudança.

Refs #N
```

- **Primeira linha (assunto):** obrigatória. É o que aparece no histórico.
- **Corpo:** opcional. Use quando a mudança não for óbvia.
- **Rodapé:** referência à issue (`Refs #N` ou `Closes #N`).

### Tipos

| Tipo | Quando usar | Exemplo |
|---|---|---|
| `feat` | Funcionalidade nova | `feat(talhao): adiciona endpoint de cadastro de talhões` |
| `fix` | Correção de bug | `fix(auth): corrige validação de senha no login` |
| `docs` | Documentação | `docs(requisitos): define escopo do mvp e requisitos` |
| `refactor` | Reorganiza código sem mudar o comportamento | `refactor(solo): extrai cálculo de status para serviço` |
| `test` | Cria ou ajusta testes | `test(simulacao): cobre regra de repetição de família` |
| `style` | Formatação, sem mudar lógica | `style(frontend): padroniza indentação dos componentes` |
| `chore` | Configuração, scripts e tarefas de manutenção | `chore(github): adiciona script de criação de issues` |

### Escopos

O escopo é opcional, mas usem sempre que possível, escolhendo da lista abaixo para não termos variações do mesmo nome.

| Escopo | Cobre |
|---|---|
| `auth` | Cadastro, login, recuperação de senha e logout |
| `perfil` | Dados do produtor e da propriedade |
| `talhao` | Cadastro, listagem e exclusão de talhões |
| `cultura` | Culturas e safras |
| `solo` | Análises de solo e status do solo |
| `simulacao` | Simulação, comparação e recomendação |
| `dashboard` | Painel de visão geral |
| `pdf` | Exportação do prontuário |
| `db` | Modelagem, migrations e seeds |
| `docs`, `requisitos`, `regras`, `git` | Documentos do projeto |
| `github` | Scripts e configuração do repositório |

Se precisarem de um escopo novo, combinem no grupo e adicionem a esta tabela.

### Regras da descrição

- Em **português**, com **letra minúscula** no início e **sem ponto final**.
- Começa com um **verbo no presente**: adiciona, corrige, define, remove, ajusta.
- Teste: a frase "Este commit ___" deve fazer sentido. Evite o passado ("adicionado", "corrigi").
- Até cerca de **70 caracteres**.
- Descreve **o que muda**, não "ajustes", "alterações" ou "atualização".
- Os tipos (`feat`, `fix`...) ficam em inglês porque fazem parte do padrão.

| Evitar | Preferir |
|---|---|
| `ajustes` | `fix(auth): corrige redirecionamento após login` |
| `Adicionado login.` | `feat(auth): adiciona tela de login` |
| `docs: atualizações` | `docs(regras): preenche classes do laudo de solo` |

### Rodapé: `Refs` e `Closes`

- `Refs #N`: o commit está relacionado à issue, que continua aberta. Usem na maioria dos commits.
- `Closes #N`: a issue fecha sozinha quando a mudança chega na `main`. Prefiram colocar na **descrição do Pull Request**, e não nos commits.

Quando um commit mexe em mais de uma issue, usem uma linha por issue:

```
Refs #4
Refs #5
```

### Commits pequenos e atômicos

Cada commit deve fazer **uma coisa**. Se a mensagem precisa de "e" para descrever duas mudanças que não têm relação, são dois commits.

---

## 2. Como commitar no GitHub Desktop

- **Campo de cima (Summary):** o assunto, ou seja, `tipo(escopo): descrição`.
- **Campo Description:** o corpo e o rodapé, por exemplo `Refs #1`. Não precisa deixar linha em branco entre os campos.
- O ícone de pessoa com "+" adiciona **coautores**. Usem quando mais de uma pessoa trabalhou no mesmo commit.

Depois, **Commit to nome-da-branch** e em seguida **Push origin**.

---

## 3. Branches

### Formato

```
tipo-numero-da-issue-descricao-curta
```

- Tudo em **minúsculas**, com **hífen** entre as palavras.
- **Sem** espaços, acentos ou caracteres especiais.
- O `tipo` é o mesmo dos commits (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`).
- O **número da issue** liga a branch ao trabalho. Para trabalho sem issue, omitam o número, mas prefiram criar a issue antes.
- Descrição com poucas palavras.

| Exemplo | Para quê |
|---|---|
| `docs-1-mvp-e-requisitos` | Documento de requisitos (issue #1) |
| `docs-10-regras-agronomicas` | Regras agronômicas (issue #10) |
| `feat-6-api-talhoes` | API de talhões |
| `fix-12-validacao-senha` | Correção na validação de senha |
| `docs-convencoes-git` | Este guia, sem issue |

### Regras de uso

- **Uma branch por issue.** Não misturem assuntos diferentes na mesma branch.
- **Criem a branch a partir da `main` atualizada.** Façam **Fetch/Pull** antes de criar.
- **Não trabalhem direto na `main`.** Toda mudança entra por Pull Request.
- Depois do merge, **apaguem a branch** e criem uma nova para a próxima tarefa. Não reutilizem branches antigas.

---

## 4. Pull Requests

- **Título:** segue o mesmo formato do commit, por exemplo `docs(requisitos): define escopo do mvp e requisitos`.
- **Descrição:** explica o que mudou e inclui `Closes #N` quando o PR resolve a issue por completo.
- Pelo menos **uma pessoa do grupo** revisa antes do merge.
- Depois do merge, apaguem a branch.

---

## 5. Issues

- **Título:** `[Área] Descrição`, com a área sendo `Backend`, `Frontend`, `Banco de dados`, `Sistema` ou `Projeto`.
  Exemplo: `[Backend] Desenvolver API de talhões`
- Preencham **descrição**, **critério de aceite** e **responsável**.
- Usem as **labels** de tipo e de prioridade definidas no projeto.
- Ninguém começa a programar algo sem antes existir uma issue para aquilo.

---

## 6. Checklist antes de commitar

- [ ] Estou na branch certa, e não na `main`?
- [ ] O assunto tem `tipo(escopo): descrição` e começa com verbo no presente?
- [ ] O commit faz uma coisa só?
- [ ] O rodapé tem `Refs #N` com o número da issue certa?
- [ ] Não estou enviando arquivos que não deveriam subir (senhas, `.env`, `node_modules`)?