# Protocolo dos sockets (app ↔ servidor ↔ API)

O aplicativo não chama a API direto. Todas as chamadas passam pelo servidor Java (`servidor/`), que encaminha ao Spring Boot e devolve a resposta. No celular e no emulador a conversa é por sockets; no navegador (Flutter Web) é por HTTP, numa porta extra do mesmo servidor (ver "Flutter Web").

```
Flutter --TCP/3000, serialização Java--> servidor --HTTP/8081--> Spring Boot --> MongoDB
```

## Mensagens

| Classe | Sentido | Campos |
|---|---|---|
| `PedidoRequisicao` | app → servidor | `metodo`, `caminho`, `token`, `corpo` (byte[] UTF-8) |
| `RespostaRequisicao` | servidor → app | `status` (HTTP), `tipoConteudo`, `corpo` (byte[]) |

- Uma conexão TCP por requisição: o app conecta, envia, lê a resposta e fecha.
- Cada lado envia primeiro o cabeçalho do fluxo Java (`AC ED 00 05`).
- O corpo vai como `byte[]` para preservar acentos (a serialização Java usa UTF-8 modificado em `String`).
- O código HTTP do backend (401, 409, 422...) é repassado em `status`; o app traduz em `AppException`.
- Falhas do próprio servidor (backend fora do ar) voltam como `status` 502/503 com JSON `{"title": ...}`.

## Segurança

- `PedidoRequisicao` valida no `readObject`: método (GET/POST/PUT/DELETE/PATCH), caminho (`/status` ou `/api/...`, sem `..`), token ASCII até 4096 caracteres e corpo até 512 KB.
- `Parceiro` usa `ObjectInputFilter` com lista de classes permitidas.
- O tráfego é TCP sem criptografia (token e senha trafegam em claro). Aceitável em rede local para o trabalho acadêmico; em produção, usar TLS.

## Como rodar

1. MongoDB + backend Spring Boot (porta 8081).
2. Servidor: `./run-backend` (na raiz) sobe banco, backend e servidor e deixa o terminal do servidor aberto, na porta 3000 (e 3001 para o navegador). Dentro do Docker ele acha o backend por `BACKEND_URL` (`http://backend:8081`). Para rodar direto pelo computador: `cd servidor && javac -d out src/*.java && java -cp out Servidor` (padrão `http://localhost:8081`), sem o `./run-backend` ao mesmo tempo. Detalhes no README.
3. App:
   - emulador Android: `flutter run` (usa `10.0.2.2:3000`);
   - Chrome ou Edge: `flutter run -d chrome` (ou `-d edge`), ver abaixo.
   - `--dart-define=SERVIDOR_PORTA=3000` altera a porta dos sockets.

Por Wi-Fi não funciona do jeito padrão, porque o Docker abre as portas só para o próprio computador (`127.0.0.1`).

## Flutter Web (Chrome e Edge)

O navegador não abre sockets TCP, então o app web usa a porta HTTP do servidor (padrão 3001, variável `HTTP_PORT`; `0` desativa):

```
navegador --HTTP/3001--> servidor --HTTP/8081--> Spring Boot
```

- A escolha é feita na compilação (`criar_transporte.dart`): `dart:io` e sockets no celular, `package:http` no navegador. O restante do app usa a mesma interface (`ServidorTransporte`).
- A porta HTTP aplica as mesmas regras do `PedidoRequisicao`: só `GET`, `POST`, `PUT` e `DELETE`, só rotas `/status` e `/api/...`, token e corpo com tamanho limitado. O token vai no cabeçalho `Authorization: Bearer ...`.
- CORS: só aceita páginas de `localhost` e `127.0.0.1` (qualquer porta), que é onde o `flutter run` serve o app.
- `--dart-define=SERVIDOR_HTTP=http://localhost:3001` altera o endereço no app.
- É uma conveniência de desenvolvimento e teste. O caminho principal do projeto continua sendo o socket.

## Testes

- App: `cd frontend && flutter test` (inclui `serializacao_java_test.dart`, com bytes gerados pelo Java, e `servidor_http_test.dart`).
- Servidor: `PedidoRequisicaoTest`, `BackendClientTest` e `PortaHttpTest` (JUnit 5, ver `servidor/pom.xml`).
