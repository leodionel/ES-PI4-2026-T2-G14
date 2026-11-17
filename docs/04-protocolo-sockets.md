# Protocolo dos sockets (app ↔ servidor ↔ API)

O aplicativo não fala HTTP com a API. Todas as chamadas passam pelo servidor Java de sockets (`servidor/`), que encaminha ao Spring Boot e devolve a resposta.

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
2. Servidor: `cd servidor && javac -d out src/*.java && java -cp out Servidor` (porta 3000; o backend é localizado por `BACKEND_URL`, padrão `http://localhost:8081`).
3. App:
   - emulador Android: `flutter run` (usa `10.0.2.2:3000`);
   - celular por USB: `adb reverse tcp:3000 tcp:3000` e `flutter run --dart-define=SERVIDOR_HOST=127.0.0.1`;
   - celular por Wi-Fi: `--dart-define=SERVIDOR_HOST=<IP do computador>`.
   - `--dart-define=SERVIDOR_PORTA=3000` altera a porta.

O app usa `dart:io`, então não funciona no Flutter Web.

## Testes

- App: `cd frontend && flutter test` (inclui `serializacao_java_test.dart`, com bytes gerados pelo Java).
- Servidor: `PedidoRequisicaoTest` e `BackendClientTest` (JUnit 5, ver `servidor/pom.xml`).
