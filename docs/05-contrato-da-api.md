# Contrato da API

Documento vivo: cada módulo novo do backend entra aqui. Todas as rotas abaixo passam pelo servidor de sockets (ver `04-protocolo-sockets.md`). Rotas protegidas exigem o token JWT (campo `token` do pedido, que vira `Authorization: Bearer ...`).

Erros seguem o formato do Spring (`ProblemDetail`): `title`, `status`, `detail`. Erros de validação trazem também `campos`, com a mensagem de cada campo.

## Recuperação de senha (RF03)

As duas rotas são públicas. Para habilitar o envio pelo Docker Compose, preencha os campos SMTP de `env.example` no `.env` e execute `docker compose up -d --build backend`. Use o endereço de remetente autorizado pelo seu provedor.

- `POST /api/usuarios/recuperacao-senha` recebe `{"email":"produtor@example.org"}`. Retorna 202 para e-mails conhecidos ou desconhecidos. Um código vale por 15 minutos e pode ser reenviado após 60 segundos. O reenvio substitui o código anterior.
- `POST /api/usuarios/redefinir-senha` recebe os campos `email`, `codigo` e `novaSenha`. Retorna 204 após a alteração ou 400 se o código estiver incorreto, vencido ou já utilizado. A senha deve ter pelo menos oito caracteres e no máximo 72 bytes em UTF-8.

## Perfil (RF04, RF05)

O usuário vem sempre do token, nunca da URL: cada produtor só vê e altera o próprio perfil (RN06).

### GET /api/usuarios/me

Devolve os dados pessoais e a propriedade do usuário logado.

```json
{
  "usuario": {
    "id": "665f...",
    "nome": "Maria Silva",
    "email": "maria@email.com",
    "telefone": "19999999999",
    "criadoEm": "2026-01-10T12:00:00Z"
  },
  "propriedade": {
    "id": "665f...",
    "nome": "Sítio Boa Vista",
    "localizacao": "Campinas - SP"
  }
}
```

`propriedade` é `null` enquanto o produtor não cadastrou uma. O `id` da propriedade é o usado nas rotas `/api/propriedades`.

| Status | Quando |
|---|---|
| 200 | Perfil devolvido |
| 401 | Token ausente, inválido ou expirado; ou a conta não existe mais |

### PUT /api/usuarios/me

Altera nome e telefone.

```json
{ "nome": "Maria Souza", "telefone": "1933334444" }
```

- `nome`: 3 a 120 caracteres (espaços nas pontas são removidos antes de contar).
- `telefone`: só números, com DDD (10 ou 11 dígitos).
- Qualquer outro campo enviado (`email`, `id`, `senha`) é ignorado.

A resposta tem o mesmo formato do `GET`.

| Status | Quando |
|---|---|
| 200 | Dados atualizados |
| 400 | Campo inválido (`campos` indica qual) |
| 401 | Token ausente, inválido ou expirado; ou a conta não existe mais |

### Propriedade

Nome e localização da propriedade (RF05) são alterados em `PUT /api/propriedades/{id}` com `{ "nome": "...", "localizacao": "..." }`. A propriedade nova é criada em `POST /api/propriedades` (uma por conta, RN11).

### Logout (RF04)

O token é sem estado: sair é apagar o token no app. O servidor não guarda sessão, então não há rota de logout. O token continua valendo até expirar (2 horas).

### Decisões

- **E-mail não é editável**: ele é o login da conta e não há confirmação por e-mail no MVP. Se o grupo decidir o contrário, é preciso checar e-mail duplicado e reemitir o token.
- **Troca de senha** não está nos requisitos e ficou de fora.

## Dashboard (RF14, RF15, RF16)

### GET /api/dashboard

Resumo da propriedade do usuário logado. A propriedade vem do token (RN06). O status de cada talhão é calculado no servidor, pela mesma regra de `GET /api/talhoes/{id}/status-solo`.

```json
{
  "propriedadeNome": "Sítio Boa Vista",
  "totalTalhoes": 4,
  "areaTotalHa": 15.8,
  "distribuicao": [
    { "status": "RISCO", "quantidade": 1 },
    { "status": "ATENCAO", "quantidade": 1 },
    { "status": "SAUDAVEL", "quantidade": 1 },
    { "status": "SEM_ANALISE", "quantidade": 1 }
  ],
  "talhoesEmAlerta": [
    {
      "talhaoId": "665f...",
      "nome": "Talhão 04",
      "areaHa": 10.5,
      "status": "RISCO",
      "dataAnalise": "2026-01-10",
      "motivos": ["pH (acidez muito alta)"]
    }
  ]
}
```

| Campo | Significado |
|---|---|
| `propriedadeNome` | `null` enquanto o produtor não cadastrou a propriedade |
| `totalTalhoes` | Quantidade de talhões (RF14) |
| `areaTotalHa` | Soma da área dos talhões, com 2 casas decimais (RF14) |
| `distribuicao` | Sempre os quatro status, nessa ordem, com `0` quando não há talhão (RF15) |
| `talhoesEmAlerta` | Talhões em `RISCO` ou `ATENCAO`, com o parâmetro que motivou o status (RF16). `RISCO` vem primeiro; dentro de cada grupo, por nome |

Sem propriedade ou sem talhões, a resposta vem zerada (`totalTalhoes` 0, quatro status com 0, `talhoesEmAlerta` vazio).

| Status | Quando |
|---|---|
| 200 | Resumo devolvido |
| 401 | Token ausente, inválido ou expirado |

### Decisões

- **Talhão sem análise** conta em `SEM_ANALISE` na distribuição e não entra em `talhoesEmAlerta`: não há solo fora da faixa para destacar.
- **`SAUDAVEL`** só quer dizer que nenhum indicador avaliado acendeu alerta (RN02). O texto exibido ao produtor é decisão do app (o grupo pode preferir "Sem alertas").
- **Área total** é a soma das áreas dos talhões, porque a propriedade não tem área própria.

## Lista de talhões (RF07)

### GET /api/talhoes

Lista os talhões da propriedade do usuário logado (a propriedade vem do token). Cada item traz a cultura atual e o status do solo, calculados no servidor.

```json
[
  {
    "id": "665f...",
    "nome": "Talhão Norte",
    "areaHa": 12.5,
    "criadoEm": "2026-01-01T12:00:00Z",
    "totalPlantios": 2,
    "totalAnalises": 3,
    "culturaAtual": {
      "plantioId": "665f...",
      "culturaId": "soja",
      "nome": "Soja",
      "dataPlantio": "2026-03-01"
    },
    "statusSolo": "ATENCAO"
  },
  {
    "id": "665f...",
    "nome": "Talhão Novo",
    "areaHa": 4.0,
    "criadoEm": "2026-01-02T12:00:00Z",
    "totalPlantios": 0,
    "totalAnalises": 0,
    "culturaAtual": null,
    "statusSolo": "SEM_ANALISE"
  }
]
```

| Campo | Significado |
|---|---|
| `totalPlantios`, `totalAnalises` | Quantas safras e análises o talhão tem (incluindo as já colhidas) |
| `culturaAtual` | Plantio mais recente que já começou e não tem colheita registrada. `null` quando o talhão não tem cultura plantada. `plantioId` serve para registrar a colheita |
| `statusSolo` | `RISCO`, `ATENCAO`, `SAUDAVEL` ou `SEM_ANALISE`, pela última análise (mesma regra de `GET /api/talhoes/{id}/status-solo`) |

A lista vem vazia (`[]`) quando o usuário ainda não tem propriedade ou talhões. A ordem é a do banco; o app pode reordenar.

| Status | Quando |
|---|---|
| 200 | Lista devolvida |
| 401 | Token ausente, inválido ou expirado |

Os campos que já existiam (`id`, `nome`, `areaHa`, `criadoEm`, `totalPlantios`, `totalAnalises`) continuam iguais. `culturaAtual` e `statusSolo` são novos. As demais rotas (`GET /api/talhoes/{id}`, `POST` e `PUT`) não mudaram e não trazem esses dois campos.

### Decisões

- **Cultura atual**: segue o `docs/03-modelo-de-dados.md`, o plantio mais recente sem `dataColheita`. Plantio com data futura ainda não conta. Com datas iguais, vale o registrado por último. Cultura que saiu do catálogo é ignorada.
- **Só a lista** foi enriquecida. O detalhe do talhão continua usando a rota de status e a de plantios.
