# Prontuário Digital do Talhão com Simulação de Rotação

Projeto Integrador IV — Engenharia de Software, PUC-Campinas (4º semestre).
Equipe G-14, Turma 2.

Aplicativo mobile para pequenos e médios produtores rurais. O produtor registra o histórico de plantio e as análises de solo de cada talhão, acompanha a evolução e compara cenários de rotação de cultura antes de decidir o próximo plantio. O sistema é um apoio à decisão e não substitui o acompanhamento de um engenheiro agrônomo.

## Arquitetura

```
Flutter (app) → Servidor Java (sockets) → API REST (Spring Boot) → MongoDB
```

| Pasta | Componente | Tecnologia | Porta |
|---|---|---|---|
| `frontend/` | Aplicativo | Flutter (Dart) | — |
| `servidor/` | Servidor de sockets | Java 17 (`ServerSocket`) | 3000 |
| `backend/` | API REST e regras de negócio | Java 17, Spring Boot 4 | 8081 |
| (Docker) | Banco de dados | MongoDB 7 | 27017 |

O backend é o único componente que acessa o banco. O servidor de sockets recebe os pedidos do aplicativo e os encaminha à API, repassando o token JWT.

**Estado atual da integração:** o aplicativo ainda chama a API REST diretamente. A passagem pelo servidor de sockets está em desenvolvimento.

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/01-mvp-e-requisitos.md`](docs/01-mvp-e-requisitos.md) | Escopo, requisitos funcionais e regras de negócio |
| [`docs/02-regras-agronomicas.md`](docs/02-regras-agronomicas.md) | Status do solo, regras de rotação e fontes técnicas |
| [`docs/03-modelo-de-dados.md`](docs/03-modelo-de-dados.md) | Coleções do MongoDB e classes Java |
| [`docs/regras-de-contribuicao.md`](docs/regras-de-contribuicao.md) | Convenções de branches, commits e Pull Requests |

## Pré-requisitos

| Ferramenta | Para quê |
|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Subir o banco (e, opcionalmente, tudo) |
| JDK 17 e [Maven](https://maven.apache.org/) | Rodar o backend e o servidor fora do Docker |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.11 ou superior) | Rodar o aplicativo |

## Configuração

Os segredos ficam em um arquivo `.env` na raiz do projeto. Ele não é versionado.

1. Copie o modelo:

   ```bash
   cp .env.example .env
   ```

   No PowerShell: `Copy-Item .env.example .env`

2. Gere a chave do JWT (Base64 de 32 bytes ou mais) e cole em `JWT_SECRET_BASE64`.

   Linux, macOS ou Git Bash:

   ```bash
   openssl rand -base64 32
   ```

   PowerShell:

   ```powershell
   $b = New-Object byte[] 32
   [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
   [Convert]::ToBase64String($b)
   ```

3. Escolha o banco em `MONGODB_URI`:

   | Opção | Valor |
   |---|---|
   | Mongo do Docker Compose (padrão) | `mongodb://mongo:27017/talhao` |
   | MongoDB Atlas | `mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/talhao` |

   Para usar o Atlas, libere o seu IP em *Network Access* no painel do Atlas. Nunca coloque usuário e senha no código nem no Git.

### Variáveis de ambiente

| Variável | Usada por | Descrição |
|---|---|---|
| `MONGODB_URI` | backend | Endereço do MongoDB. Sem ela, fora do Docker, o backend usa `mongodb://localhost:27017/talhao` |
| `JWT_SECRET_BASE64` | backend | Chave de assinatura do JWT. Obrigatória: sem ela o backend não inicia |
| `CORS_ALLOWED_ORIGINS` | backend | Origens permitidas (apenas para Flutter Web) |
| `BACKEND_URL` | servidor | Endereço da API. Padrão `http://localhost:8081` |
| `BIND_ADDRESS` | servidor | Interface de escuta. Padrão `127.0.0.1` |
| `API_URL` | app | Endereço da API, passado com `--dart-define` |

## Executar tudo com Docker

Sobe o banco, o backend e o servidor de sockets:

```bash
docker compose up -d --build
```

Verifique se a API respondeu:

```bash
curl http://localhost:8081/status
```

A resposta esperada é `{"status":"ativo"}`.

Comandos úteis:

```bash
docker compose ps                  # situação dos contêineres
docker compose logs -f backend     # acompanhar o backend
docker compose down                # parar tudo (os dados do Mongo são mantidos)
docker compose down -v             # parar e apagar também os dados do Mongo
```

O Mongo do Docker guarda os dados no volume `mongo-talhao-data` e só aceita conexões da própria máquina.

## Executar em modo de desenvolvimento (sem Docker para o código)

Use o Docker só para o banco e rode o restante na máquina.

**1. Banco de dados**

```bash
docker compose up -d mongo
```

**2. Backend** (a partir da pasta `backend/`)

Defina as variáveis e inicie. O Spring não lê o arquivo `.env`.

Linux, macOS ou Git Bash:

```bash
export JWT_SECRET_BASE64="cole-a-chave-aqui"
mvn spring-boot:run
```

PowerShell:

```powershell
$env:JWT_SECRET_BASE64 = "cole-a-chave-aqui"
mvn spring-boot:run
```

Sem `MONGODB_URI`, o backend conecta em `mongodb://localhost:27017/talhao`, que é o Mongo do passo 1. O catálogo de culturas é carregado na primeira inicialização.

**3. Servidor de sockets** (a partir da pasta `servidor/`)

```bash
mkdir out
javac -d out src/*.java
java -cp out Servidor
```

No PowerShell, troque a compilação por `javac -d out (Get-ChildItem src -Filter *.java).FullName`.

Com o servidor ativo, digite `status` para consultar a API ou `desativar` para encerrar.

**4. Aplicativo** (a partir da pasta `frontend/`)

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8081
```

| Onde o app roda | Valor de `API_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8081` (é o endereço do computador visto pelo emulador) |
| Celular físico por USB | Rode `adb reverse tcp:8081 tcp:8081` e use `http://localhost:8081` |
| Navegador (Flutter Web) | `http://localhost:8081`, com a origem em `CORS_ALLOWED_ORIGINS` |

## Testes

```bash
cd backend
mvn test
```

Os testes não usam o banco nem precisam do `.env`.

## API

As rotas abaixo exigem o cabeçalho `Authorization: Bearer <token>`, exceto as públicas.

**Públicas**

| Método | Rota | Descrição |
|---|---|---|
| GET | `/status` | Verifica se a API está ativa |
| POST | `/api/usuarios/cadastro` | Cria uma conta |
| POST | `/api/usuarios/login` | Retorna o token JWT (válido por 2 horas) |

**Autenticadas**

| Recurso | Rotas |
|---|---|
| Propriedade (uma por usuário) | `GET`, `POST /api/propriedades`; `GET`, `PUT`, `DELETE /api/propriedades/{id}` |
| Talhões | `GET`, `POST /api/talhoes`; `GET`, `PUT`, `DELETE /api/talhoes/{id}` |
| Plantios | `GET`, `POST /api/talhoes/{id}/plantios`; `PUT /api/talhoes/{id}/plantios/{plantioId}/colheita` |
| Culturas (catálogo) | `GET /api/culturas` |
| Análises de solo | `GET`, `POST /api/analises-solo`; `GET`, `PUT`, `DELETE /api/analises-solo/{id}` |
| Relatório | `GET /api/relatorios/propriedade/{id}/pdf` |

Observações:

- Excluir um talhão exige o nome dele no corpo: `{"confirmacaoNome": "Talhão 04"}`.
- Uma propriedade só pode ser excluída depois que seus talhões forem excluídos.
- Os erros seguem o formato `ProblemDetail`, e os de validação trazem os campos em `campos`.

## Problemas comuns

| Sintoma | Causa e solução |
|---|---|
| O backend não inicia e cita `JWT_SECRET_BASE64` | A variável está vazia ou ausente. Defina uma chave Base64 de 32 bytes ou mais |
| Erro de conexão com o MongoDB | Confira se o contêiner está de pé (`docker compose ps`). No Atlas, libere o seu IP em *Network Access* |
| O app mostra "Não foi possível conectar ao servidor" | O `API_URL` está errado para o dispositivo. Veja a tabela do aplicativo |
| Porta 8081, 3000 ou 27017 em uso | Outro processo ocupa a porta. Encerre-o ou pare os contêineres antigos com `docker compose down` |
| `401` em todas as rotas | O token expirou (2 horas) ou foi assinado com outra chave. Faça login de novo |

## Contribuição

Branches, commits e Pull Requests seguem [`docs/regras-de-contribuicao.md`](docs/regras-de-contribuicao.md).
