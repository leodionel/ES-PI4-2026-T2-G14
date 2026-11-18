# Prontuário Digital do Talhão com Simulação de Rotação

Projeto Integrador IV — Engenharia de Software, PUC-Campinas (4º semestre). Grupo 14, Turma 2.

Aplicativo para pequenos e médios produtores rurais. O produtor cadastra seus talhões (áreas de plantio), registra as culturas e as análises de solo, vê o histórico e compara culturas candidatas para a próxima safra, com justificativa e fonte técnica.

> É um sistema de apoio à decisão. Não indica doses de calcário ou adubo e não substitui um engenheiro agrônomo. As regras agronômicas ainda não foram validadas por um agrônomo.

## Como o sistema é montado

```
App Flutter ──► Servidor de sockets (Java, porta 3000) ──► Backend (Spring Boot, porta 8081) ──► MongoDB
```

| Pasta | O que é |
|---|---|
| `frontend/` | O aplicativo (Flutter) |
| `servidor/` | Servidor Java de sockets. O app fala só com ele |
| `backend/` | API REST (Java 17 + Spring Boot) |
| `docs/` | Requisitos, regras agronômicas, modelo de dados, protocolo dos sockets |

O app **não** chama a API direto: todo pedido passa pelo servidor de sockets, que repassa ao backend (detalhes em `docs/04-protocolo-sockets.md`).

---

## O que instalar

| Para quê | Programa |
|---|---|
| Rodar banco, backend e servidor | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Rodar o app | [Flutter](https://docs.flutter.dev/get-started/install) + Android Studio (com um emulador Android criado) |
| Rodar os testes Java (opcional) | Java 17 e Maven |

---

## Passo a passo (jeito mais fácil)

### 1. Baixar o projeto

```
git clone https://github.com/leodionel/ES-PI4-2026-T2-G14.git
cd ES-PI4-2026-T2-G14
```

Ou use o GitHub Desktop e abra a pasta do projeto no terminal.

### 2. Criar o arquivo `.env`

Na raiz do projeto, copie o modelo:

```
cp .env.example .env
```

(no Windows PowerShell: `copy .env.example .env`)

Agora gere a chave secreta e cole no `.env`, no lugar de `COLE_AQUI_O_VALOR_GERADO`:

- **Linux, macOS ou Git Bash:**
  ```
  openssl rand -base64 32
  ```
- **Windows (PowerShell):**
  ```
  $b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
  ```

O arquivo deve ficar assim (use a sua chave, não esta):

```
JWT_SECRET_BASE64=abc123...
```

### 3. Subir banco, backend e servidor

Com o Docker Desktop aberto, na raiz do projeto:

```
docker compose up --build
```

Na primeira vez demora alguns minutos. Quando estiver pronto, tem três containers rodando: `mongo-talhao`, `backend-talhao` e `servidor-talhao`.

Para conferir, abra no navegador: <http://localhost:8081/status>. Se aparecer uma resposta (JSON), o backend está no ar.

Para parar: `Ctrl + C` no terminal, depois `docker compose down`. Os dados do banco ficam guardados e continuam na próxima vez.

### 4. Rodar o aplicativo

Abra um **segundo** terminal:

```
cd frontend
flutter pub get
flutter run
```

Antes, inicie o emulador Android (Android Studio → Device Manager). O app já vem configurado para o emulador: ele encontra o servidor em `10.0.2.2:3000`, que é como o emulador enxerga o seu computador.

Pronto: crie uma conta no app e faça login. A conta aparece no MongoDB.

---

## Rodar em celular de verdade

O app precisa chegar na porta 3000 do computador. O jeito mais simples é por cabo USB, com a depuração USB ligada no celular:

```
adb reverse tcp:3000 tcp:3000
flutter run --dart-define=SERVIDOR_HOST=127.0.0.1
```

Por Wi-Fi não funciona do jeito padrão, porque o Docker só abre a porta 3000 para o próprio computador.

Outras opções do app (`--dart-define`):

| Opção | Padrão | Para que serve |
|---|---|---|
| `SERVIDOR_HOST` | `10.0.2.2` | Endereço do servidor de sockets |
| `SERVIDOR_PORTA` | `3000` | Porta do servidor de sockets |

O app usa `dart:io`, então **não funciona no Flutter Web**.

---

## Usar o MongoDB Atlas (em vez do banco local)

1. No Atlas, crie um cluster e um usuário de banco, e libere o seu IP em *Network Access*.
2. Copie a string de conexão (`mongodb+srv://...`) e coloque o nome do banco no final (`/talhao`).
3. No `.env`, descomente e preencha:
   ```
   MONGODB_URI=mongodb+srv://USUARIO:SENHA@cluster.mongodb.net/talhao
   ```
4. Rode `docker compose up --build` de novo.

Se a senha tiver caracteres especiais (`@`, `:`, `/`), troque por códigos de URL (por exemplo `@` vira `%40`).

---

## Rodar sem Docker (para quem está mexendo no código)

Precisa de Java 17, Maven e um MongoDB rodando (pode ser o Atlas).

**Terminal 1 — backend** (porta 8081):

```
cd backend
mvn spring-boot:run
```

Antes, defina as variáveis de ambiente:

- Linux/macOS/Git Bash: `export JWT_SECRET_BASE64=SUA_CHAVE`
- PowerShell: `$env:JWT_SECRET_BASE64 = "SUA_CHAVE"`

Sem `MONGODB_URI`, ele usa `mongodb://localhost:27017/talhao`.

**Terminal 2 — servidor de sockets** (porta 3000):

```
cd servidor
mkdir out
javac -d out src/*.java
java -cp out Servidor
```

Por padrão ele procura o backend em `http://localhost:8081`. Para mudar, defina `BACKEND_URL`.

**Terminal 3 — app:** igual ao passo 4 acima.

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
| "Não foi possível conectar ao servidor" no app | O Docker não está rodando, ou o `servidor-talhao` caiu. Veja `docker compose ps` e `docker compose logs servidor` |
| Mesmo erro, mas só no celular físico | Use `adb reverse` com `SERVIDOR_HOST=127.0.0.1` (seção do celular) |
| `port is already allocated` (3000, 8081 ou 27017) | Outro programa usa a porta. Feche-o ou pare o MongoDB instalado no computador |
| O backend cai ao subir | Veja `docker compose logs backend`. Quase sempre é a chave JWT inválida ou a `MONGODB_URI` errada |
| Alterei o código e nada mudou | Rode `docker compose up --build` de novo |
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
