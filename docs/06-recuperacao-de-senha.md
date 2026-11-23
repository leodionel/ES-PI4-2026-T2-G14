# Recuperação de senha (RF03)

Versão simulada: o sistema **não envia e-mail**. Ele gera o código de recuperação, e o código aparece no log do backend e, por padrão, na resposta da API. Trocar para e-mail real depende só de enviar o código no lugar de mostrá-lo; o restante do fluxo não muda.

Rotas abertas (não precisam de token).

## Como funciona

1. O produtor informa o e-mail e pede o código (`POST /api/usuarios/recuperar-senha`).
2. O app mostra a tela do código. No modo simulado, o código vem na resposta (`codigoSimulado`).
3. O produtor digita o código e a nova senha (`POST /api/usuarios/redefinir-senha`).
4. Depois da troca, ele entra com a nova senha pelo login normal.

## POST /api/usuarios/recuperar-senha

```json
{ "email": "joao@email.com" }
```

Resposta `200`:

```json
{
  "mensagem": "Se o e-mail estiver cadastrado, um código de recuperação foi gerado.",
  "codigoSimulado": "482913"
}
```

| Campo | Significado |
|---|---|
| `mensagem` | Sempre a mesma, o e-mail existindo ou não |
| `codigoSimulado` | Código de 6 dígitos. Só vem no modo simulado (`RECUPERACAO_EXIBIR_CODIGO=true`, o padrão). Para e-mail não cadastrado vem um código qualquer, que não funciona |

| Status | Quando |
|---|---|
| 200 | Pedido aceito (e-mail cadastrado ou não) |
| 400 | E-mail ausente ou inválido |

## POST /api/usuarios/redefinir-senha

```json
{
  "email": "joao@email.com",
  "codigo": "482913",
  "novaSenha": "NovaSenha123"
}
```

Resposta `204`, sem corpo.

| Status | Quando |
|---|---|
| 204 | Senha trocada |
| 400 | Campos inválidos (código com 6 dígitos, senha de 8 a 128 caracteres) |
| 400 | Código errado, expirado, já usado ou com tentativas esgotadas. A mensagem é a mesma nos quatro casos |

## Regras

- O código tem **6 dígitos** e vale **15 minutos**.
- Cada código aceita **5 tentativas**. Na sexta o pedido é recusado e é preciso pedir um código novo.
- O código vale **uma vez**: depois da troca, o pedido é apagado.
- Cada usuário tem **um pedido por vez**. Pedir de novo substitui o anterior.
- O banco guarda apenas o **hash** (BCrypt) do código, e apaga o pedido sozinho depois de expirar (índice TTL na coleção `recuperacoes_senha`).
- O sistema **não revela se um e-mail existe**: a resposta do pedido é igual, e a troca falha com a mesma mensagem.
- A nova senha segue a mesma regra do cadastro (8 a 128 caracteres).

## Configuração

| Variável | Padrão | Efeito |
|---|---|---|
| `RECUPERACAO_EXIBIR_CODIGO` | `true` | `true`: o código volta na resposta. `false`: só aparece no log do backend (`docker logs backend-talhao`) |

## O que o app precisa

- Tela do e-mail (já existe): chama `recuperar-senha`.
- Segunda tela: campos código e nova senha (com confirmação), chama `redefinir-senha` e volta ao login.
- No modo simulado, mostrar o `codigoSimulado` na tela, por exemplo "Código (simulado): 482913".

## Limites conhecidos

- O token de login já emitido continua valendo até expirar (2 horas) depois da troca de senha, porque o JWT não fica guardado no servidor.
- No modo simulado, quem tem acesso à API recebe o código. Isso é proposital para a demonstração; num sistema real, o código iria só por e-mail.
