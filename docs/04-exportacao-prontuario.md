# Exportação do prontuário do talhão

Issue #11: exportar o histórico completo de um talhão em PDF.

## Endpoint

`GET /api/relatorios/talhao/{id}/pdf`

Enviar `Authorization: Bearer <token JWT>`. O usuário é obtido do token e o
talhão precisa pertencer à propriedade dele.

Exemplo no Bash, com `TOKEN` e `TALHAO_ID` definidos:

```bash
curl --fail --show-error \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/relatorios/talhao/$TALHAO_ID/pdf" \
  --output prontuario-talhao.pdf
```

O sucesso retorna `200`, `Content-Type: application/pdf`, `Content-Length` e
`Content-Disposition: attachment; filename="prontuario-talhao.pdf"`.
Token ausente, inválido ou expirado retorna `401`. Talhão inexistente ou
inacessível ao usuário retorna `404`.

## Conteúdo

- Nome e localização da propriedade; nome, identificador e área do talhão.
- Todas as safras, com nome da cultura, identificador do plantio, data de
  plantio e data de colheita (ou indicação de que continua em aberto).
- Todas as análises do talhão, com data da coleta, pH (CaCl2), fósforo
  (P resina, mg/dm³), potássio (mmolc/dm³), saturação por bases (V%) e observações.

Safras e análises aparecem em seções próprias, do registro mais antigo para o
mais recente. Os dados vêm dos plantios registrados no talhão, do catálogo de
culturas e das análises filtradas por usuário, propriedade e talhão. Culturas
ausentes do catálogo continuam no histórico, identificadas pelo código salvo.

Talhões sem histórico também geram PDF, com indicação das seções vazias.
Históricos extensos recebem páginas adicionais. A rota existente
`GET /api/relatorios/propriedade/{id}/pdf` continua disponível.

## Validação

`ProntuarioTalhaoControllerTest` usa o controller e os serviços reais, com JWT e
repositórios simulados. Os testes abrem os bytes retornados com PDFBox e conferem
conteúdo, ordem, cabeçalhos, margens, paginação e controle de acesso.

Para executar a suíte do backend com Maven e Java 17 ou superior:

```bash
mvn -f backend/pom.xml test
```
