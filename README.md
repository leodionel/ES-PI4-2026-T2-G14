# Prontuário Digital do Talhão com Simulação de Rotação

Projeto Integrador IV — Engenharia de Software, PUC-Campinas (4º semestre). Grupo 14, Turma 2.

Aplicativo para pequenos e médios produtores rurais. O produtor cadastra seus talhões (áreas de plantio), registra as culturas e as análises de solo, vê o histórico e compara culturas candidatas para a próxima safra, com justificativa e fonte técnica.

> É um sistema de apoio à decisão. Não indica doses de calcário ou adubo e não substitui um engenheiro agrônomo. As regras agronômicas ainda não foram validadas por um agrônomo.

## Como o sistema é montado

```
App Flutter ──► Servidor Java (sockets, porta 3000) ──► Backend (Spring Boot, porta 8081) ──► MongoDB
```

No navegador (Chrome/Edge) o app usa a porta HTTP 3001 do mesmo servidor, porque o navegador não abre sockets. O caminho dos dados é o mesmo.

| Pasta | O que é |
|---|---|
| `frontend/` | O aplicativo (Flutter) |
| `servidor/` | Servidor Java (sockets na 3000, HTTP na 3001 só para o navegador). O app fala só com ele |
| `backend/` | API REST (Java 17 + Spring Boot) |
| `docs/` | Requisitos, regras agronômicas, modelo de dados, protocolo dos sockets |

O app **não** chama a API direto: todo pedido passa pelo servidor de sockets, que repassa ao backend (detalhes em `docs/04-protocolo-sockets.md`).

---

## O que instalar

| Para quê | Programa |
|---|---|
| Rodar banco, backend e servidor | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (precisa estar aberto) |
| Rodar o app | [Flutter](https://docs.flutter.dev/get-started/install) |
| Rodar no celular virtual (opcional) | Android Studio com um emulador Android criado |
| Rodar no navegador (opcional) | Chrome ou Edge |
| Rodar os testes Java (opcional) | Java 17 e Maven |

---

## Resumo: 4 passos

```
1. Clone o repositório e entre na pasta do projeto.
2. Configure o arquivo .env com as variáveis necessárias.
3. Execute o backend e o servidor Java utilizando o script run-backend.
4. Em outro terminal, entre na pasta frontend e execute o aplicativo com flutter run.
```

Cada passo está explicado a seguir.

---

## Passo a passo

### 1. Baixar o projeto

```
git clone https://github.com/leodionel/ES-PI4-2026-T2-G14.git
cd ES-PI4-2026-T2-G14
```

### 2. Criar o arquivo `.env`

Na raiz do projeto, copie o modelo:

```
cp env.example .env
```

(no Windows PowerShell: `copy env.example .env`)

**a) Chave secreta.** Gere uma e cole no `.env`, no lugar de `COLE_AQUI_O_VALOR_GERADO`:

- **Linux, macOS ou Git Bash:** `openssl rand -base64 32`
- **Windows (PowerShell):**
  ```
  $b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
  ```

O arquivo fica assim (use a sua chave, não esta):

```
JWT_SECRET_BASE64=abc123...
```

**b) Banco de dados.** Escolha um:

- **Banco local (padrão):** não faça nada. O Docker cria um MongoDB no seu computador. Funciona em qualquer rede, mas começa vazio: crie uma conta no app.
- **Banco da equipe (MongoDB Atlas):** peça a linha `MONGODB_URI=...` a quem administra o Atlas e cole no `.env`. Assim todos usam as mesmas contas e dados (cada usuário do app só vê os próprios talhões). Veja a seção do Atlas mais abaixo.

### 3. Subir o sistema: `./run-backend`

Abra o Docker Desktop, depois, **na raiz do projeto**, em um terminal:

| Sistema | Comando |
|---|---|
| Windows (PowerShell ou Prompt) | `./run-backend` |
| Linux, macOS | `./run-backend.sh` |

(No Windows use o PowerShell ou o Prompt de Comando, não o Git Bash.)

Esse único comando sobe o banco, o backend e o servidor Java. Na primeira vez demora alguns minutos. Quando aparecer:

```
Servidor ativo na porta 3000
Comandos disponiveis: status e desativar.
```

está pronto. **Deixe esse terminal aberto.** Ele é o terminal do servidor Java, e você pode digitar nele:

- `status`: consulta o backend e mostra a resposta;
- `desativar`: encerra o servidor.

Depois de `desativar`, o banco e o backend continuam ligados. Para desligar tudo: `docker compose down` (os dados ficam guardados). Para ligar de novo, `./run-backend`.

Mudou o código do backend ou do servidor? Use `./run-backend --build` para reconstruir.

### 4. Rodar o aplicativo

Abra um **segundo** terminal:

```
cd frontend
flutter pub get
```

Depois escolha onde rodar:

| Onde | Comando | Observação |
|---|---|---|
| Emulador Android | `flutter run` | Inicie o emulador antes (Android Studio → Device Manager) |
| Chrome | `flutter run -d chrome` | Não precisa de emulador |
| Edge | `flutter run -d edge` | Igual ao Chrome |

Pronto: crie uma conta no app e faça login.

---

## Rodar no Chrome ou no Edge

É o jeito mais rápido para desenvolver e para quem não tem emulador. Sem mudar nada no projeto:

- **É o mesmo app.** As telas, a lógica e os dados são os mesmos. O app mostra as mesmas contas, talhões e análises, porque tudo vem do mesmo servidor, backend e banco.
- **O que muda é só o "cano" até o servidor.** O emulador e o celular falam com o servidor Java por **socket** (porta 3000). O navegador não consegue abrir socket, então usa a **porta HTTP 3001 do mesmo servidor Java**. Dali em diante o caminho é igual (servidor → backend → banco). O app escolhe sozinho, você não configura nada.
- **O que precisa:** apenas o `./run-backend` rodando (ele já abre as portas 3000 e 3001).
- **Diferenças que você pode notar:** o tamanho da janela muda o layout; no navegador a sessão fica guardada no próprio navegador; e a página precisa abrir em `localhost` (é o padrão do `flutter run`).

---

## MongoDB Atlas (banco da equipe)

O app **não** acessa o Atlas direto: quem acessa é o **backend**, que roda no computador de cada pessoa. Por isso o Atlas precisa aceitar a conexão vinda do computador de quem roda o backend.

Quem administra o Atlas faz uma vez:

1. *Network Access* → *Add IP Address* → **Allow access from anywhere** (`0.0.0.0/0`). Assim funciona em qualquer rede, sem liberar IP por pessoa.
2. *Database Access* → crie um usuário **só para o projeto**, com permissão de leitura e escrita apenas no banco `talhao` (não use o usuário administrador) e uma senha forte.
3. Copie a string de conexão (`mongodb+srv://...`) e coloque o nome do banco no final (`/talhao`).

Quem usa coloca no `.env`:

```
MONGODB_URI=mongodb+srv://USUARIO:SENHA@cluster.mongodb.net/talhao
```

e roda `./run-backend --build`.

Cuidados:

- Nunca coloque a string de conexão no GitHub. O `.env` já está no `.gitignore`. Envie para a equipe por mensagem privada.
- Quem tem a string consegue ler o banco inteiro. As contas e os dados de cada usuário do app continuam separados dentro do app (cada um só vê o que é seu), mas isso não vale para quem acessa o banco direto.
- As senhas dos usuários ficam guardadas com hash, não em texto.
- Se a senha vazar, troque em *Database Access* e atualize o `.env`.
- Se a senha tiver caracteres especiais (`@`, `:`, `/`), troque por códigos de URL (`@` vira `%40`).

Para voltar ao banco local, apague ou comente a linha `MONGODB_URI` e rode `./run-backend --build`. Os dados do Atlas e os do banco local são separados.

---

## Outras formas de rodar

### Servidor Java direto no seu computador (`java -cp out Servidor`)

Útil para mexer no código do servidor. Precisa de Java 17. Um script faz tudo (sobe banco e backend no Docker, compila e abre o servidor no terminal):

```
scripts\modo-b.bat         (Windows)
./scripts/modo-b.sh        (Linux/macOS/Git Bash)
```

Ou manualmente, na raiz:

```
docker compose up -d --build --wait mongo backend
cd servidor
mkdir out
javac -d out src/*.java
java -cp out Servidor
```

Não rode isso junto com o `run-backend`: os dois usam a porta 3000. Variáveis opcionais do servidor: `BACKEND_URL` (padrão `http://localhost:8081`), `BIND_ADDRESS` (padrão `127.0.0.1`), `HTTP_PORT` (padrão `3001`, `0` desativa a porta do navegador).

### Tudo em segundo plano (sem terminal do servidor)

```
docker compose --profile segundo-plano up -d --build --wait
```

Nesse caso os comandos `status` e `desativar` só funcionam com `docker attach servidor-talhao`. Para voltar ao normal, `docker compose down`.

### Backend direto no seu computador

Precisa de Java 17, Maven e um MongoDB (o do Docker serve).

```
docker compose up -d --wait mongo
docker compose stop backend
cd backend
mvn spring-boot:run
```

Antes do `mvn`, defina a chave: Linux/macOS/Git Bash `export JWT_SECRET_BASE64=SUA_CHAVE`, PowerShell `$env:JWT_SECRET_BASE64 = "SUA_CHAVE"`. Sem `MONGODB_URI`, ele usa `mongodb://localhost:27017/talhao`. Depois rode o servidor Java no seu computador (seção acima), porque o do Docker só enxerga o backend do Docker.

---

## Testes

| O quê | Comando |
|---|---|
| Backend | `cd backend && mvn test` |
| Servidor de sockets | `cd servidor && mvn test` |
| App | `cd frontend && flutter test` |

Os testes do backend usam bancos e servidores falsos. Não precisam do Docker.

---

## Problemas comuns

| O que aparece | O que fazer |
|---|---|
| `Defina JWT_SECRET_BASE64 no arquivo .env` | Falta o `.env` na raiz, ou a linha `JWT_SECRET_BASE64` está vazia (passo 2) |
| `ports are not available ... 3000`, ou `A porta 3000 já está em uso` | Há dois servidores tentando usar a porta 3000 (por exemplo `run-backend` e `java -cp out Servidor` ao mesmo tempo). Deixe só um: digite `desativar` no outro. Para ver quem usa a porta no Windows: `netstat -ano \| findstr :3000` |
| `Falha ao encaminhar ...: HTTP/1.1 header parser received no bytes` no servidor | O backend ainda estava subindo ou a conexão com ele caiu. Rode `docker compose ps` e espere o `backend-talhao` ficar `healthy` (o `run-backend` já espera). O servidor já tenta de novo sozinho uma vez |
| O login não funciona, ou o app não valida a conta | Confira `docker compose ps`: `backend-talhao` precisa estar `healthy`. Veja também `docker compose logs backend` |
| "Não foi possível conectar ao servidor" no app | O Docker não está rodando, ou o `servidor-talhao` caiu. Veja `docker compose ps` e `docker compose logs servidor` |
| Mesmo erro, mas só no celular físico | Use `adb reverse` com `SERVIDOR_HOST=127.0.0.1` (seção do celular) |
| `port is already allocated` (8081 ou 27017) | Outro programa usa a porta. Feche-o ou pare o MongoDB instalado no computador |
| O backend não fica `healthy` e o log mostra `SSLException: internal_error` ou `MongoTimeoutException` com `mongodb.net` | O Atlas está recusando a conexão: o seu IP não está liberado em *Network Access* (o IP muda com a rede). Libere-o no Atlas, ou, se o Atlas já está liberado para qualquer IP, confira usuário e senha da `MONGODB_URI`. Para testar sem Atlas, comente `MONGODB_URI` no `.env` |
| O backend não fica `healthy` por outro motivo | Veja `docker compose logs backend`. Em geral é a chave JWT inválida ou a `MONGODB_URI` errada |
| No Chrome/Edge: "Não foi possível conectar ao servidor" | O servidor não está no ar, ou a porta 3001 está ocupada (o servidor avisa no terminal). Confira se o `run-backend` está aberto e mostra `Servidor ativo`. Teste também <http://localhost:3001/status> |
| Alterei o código e nada mudou | Rode `run-backend --build` |
| Quero zerar o banco local | `docker compose down -v` (apaga os dados do MongoDB do Compose) |

---

## Mais informações

- `docs/01-mvp-e-requisitos.md` — requisitos e escopo
- `docs/02-regras-agronomicas.md` — regras do status do solo e da rotação
- `docs/03-modelo-de-dados.md` — coleções do MongoDB
- `docs/04-protocolo-sockets.md` — como o app conversa com o servidor
- `docs/regras-de-contribuicao.md` — padrão de branches, commits e PRs

## Equipe

Leonardo Dionel, Lucas Kendi, Matheus Rosini, Matheus Teixeira e Demetrius Valverde.
