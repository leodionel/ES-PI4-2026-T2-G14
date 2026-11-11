# Modelo de Dados

**Prontuário Digital do Talhão com Simulação de Rotação**
Projeto Integrador IV, Engenharia de Software — Equipe G-14

---

## 1. Visão geral

O banco é o MongoDB, acessado apenas pelo backend Spring Boot com Spring Data MongoDB. O MongoDB não impõe esquema, então o contrato dos dados fica nas classes Java do pacote `br.com.talhao.model`: um `record` com `@Document` por coleção, `record` simples para os subdocumentos e `enum` para valores fixos.

```
backend/src/main/
├── java/br/com/talhao/
│   ├── controller/   endpoints REST
│   ├── service/      regras de negócio
│   ├── repository/   acesso ao MongoDB
│   ├── dto/          objetos de entrada e saída da API
│   ├── config/       CORS, JWT e carga dos dados de referência
│   └── model/        classes do banco
└── resources/
    ├── application.properties
    └── seed/         dados de referência em JSON
```

Princípios do modelo:

- O histórico do talhão (plantios e análises) fica dentro do documento do talhão. A linha do tempo, a simulação, o PDF e o status leem um único documento, e excluir o talhão remove o histórico junto.
- O banco guarda só o dado bruto. Status do solo, cultura atual e última análise são calculados na leitura. A cultura atual é o plantio mais recente sem `dataColheita`.
- As listas `plantios` e `analises` são ordenadas por data pelo serviço ao ler, não pelo banco.
- A propriedade é uma coleção própria ligada ao usuário. Cada usuário tem uma única propriedade (RN11), regra verificada no serviço. Uma propriedade só pode ser excluída se não tiver talhões; caso contrário, a API responde 409.
- Os dados de referência (culturas, faixas de solo, regras e fontes) ficam em coleções carregadas por seed na inicialização e mantidas em memória pelo backend.
- O MongoDB não tem chave estrangeira. O serviço valida o `culturaId` contra o catálogo antes de gravar um plantio.

## 2. Coleções

| Coleção | Conteúdo | Campos | Índice |
|---|---|---|---|
| `usuarios` | Produtor | `nome`, `email`, `telefone`, `senhaHash`, `criadoEm` | `email` único |
| `propriedades` | Propriedade | `usuarioId`, `nome`, `localizacao` | `usuarioId` |
| `talhoes` | Talhão e histórico | `propriedadeId`, `nome`, `areaHa`, `criadoEm`, `plantios[]`, `analises[]` | `propriedadeId` |
| `culturas` | Catálogo de culturas | `nome`, `nomeCientifico`, `familia`, `grupo`, `tipoUso`, `grupoP`, `nota` | `_id` |
| `faixas_solo` | Classes de interpretação do solo | `parametro`, `grupoP`, `classe`, `limiteMin`, `limiteMax`, `tratamento`, `fonteId` | `_id` |
| `regras_rotacao` | Regras de rotação | `efeito`, `mensagem`, `fonteIds` | `_id` |
| `fontes_tecnicas` | Fontes técnicas | `titulo`, `autores`, `instituicao`, `ano`, `url`, `escopoRegional` | `_id` |

Os dados de referência usam `_id` fixo (`soja`, `R1`, `F1`, `PH_CRITICA`). A lógica das regras R1 a R7 fica no código Java. A coleção `regras_rotacao` guarda efeito, mensagem e as fontes de cada regra. A regra R3 cita duas fontes (F2 e F7), por isso `fonteIds` é uma lista.

Exemplo de documento da coleção `talhoes` (o plantio aberto não tem o campo `dataColheita`, porque o Spring Data não grava campos nulos):

```js
{
  _id: ObjectId("665f1c2e8b3a4d0012ab34cd"),
  propriedadeId: "665f1a118b3a4d0012ab3400",
  nome: "Talhão 04",
  areaHa: 42.8,
  criadoEm: ISODate("2026-01-05T13:00:00Z"),
  plantios: [
    { plantioId: "665f20aa8b3a4d0012ab3501", culturaId: "milho",
      dataPlantio: ISODate("2025-03-10T00:00:00Z"), dataColheita: ISODate("2025-08-02T00:00:00Z") },
    { plantioId: "665f20bb8b3a4d0012ab3502", culturaId: "soja",
      dataPlantio: ISODate("2025-11-15T00:00:00Z") }
  ],
  analises: [
    { analiseId: "665f20cc8b3a4d0012ab3601", data: ISODate("2026-01-10T00:00:00Z"),
      ph: 5.3, fosforo: 30, potassio: 2.0, v: 55 }
  ]
}
```

Só o `_id` é um `ObjectId`. Os demais identificadores (`propriedadeId`, `usuarioId`, `plantioId`, `analiseId`, `culturaId`) são texto.

## 3. Classes Java

Cada tipo fica em um arquivo próprio, em `br/com/talhao/model/`.

### 3.1. Enums

```java
package br.com.talhao.model;

public enum Grupo { LEGUMINOSA, GRAMINEA, OUTRAS }
```

```java
package br.com.talhao.model;

public enum TipoUso { COMERCIAL, COBERTURA }
```

```java
package br.com.talhao.model;

public enum GrupoP { ANUAIS, HORTALICAS }
```

```java
package br.com.talhao.model;

public enum Parametro { PH, V, P, K }
```

```java
package br.com.talhao.model;

public enum Tratamento { CRITICA, ATENCAO, SEM_ALERTA }
```

```java
package br.com.talhao.model;

public enum Efeito { RESTRITIVA, ALERTA, FAVORAVEL, NEUTRA }
```

### 3.2. Dados do produtor

```java
// Usuario.java
package br.com.talhao.model;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("usuarios")
public record Usuario(
        @Id String id,
        String nome,
        @Indexed(unique = true) String email,   // gravar em minúsculas
        String telefone,
        String senhaHash,                        // hash BCrypt, nunca a senha
        Instant criadoEm) {}
```

```java
// Propriedade.java
package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("propriedades")
public record Propriedade(
        @Id String id,
        @Indexed String usuarioId,
        String nome,
        String localizacao) {}
```

```java
// Talhao.java
package br.com.talhao.model;

import java.time.Instant;
import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("talhoes")
public record Talhao(
        @Id String id,
        @Indexed String propriedadeId,
        String nome,
        double areaHa,
        Instant criadoEm,
        List<Plantio> plantios,
        List<AnaliseSolo> analises) {

    public Talhao {
        plantios = plantios == null ? List.of() : plantios;
        analises = analises == null ? List.of() : analises;
    }
}
```

```java
// Plantio.java
package br.com.talhao.model;

import java.time.LocalDate;

public record Plantio(String plantioId, String culturaId,
                      LocalDate dataPlantio, LocalDate dataColheita) {}
```

```java
// AnaliseSolo.java
package br.com.talhao.model;

import java.time.LocalDate;

public record AnaliseSolo(String analiseId, LocalDate data,
                          double ph, double fosforo, double potassio, double v) {}
```

O construtor compacto de `Talhao` evita listas nulas, o que faria o `$push` falhar. O `plantioId` e o `analiseId` são gerados pelo servidor com `new ObjectId().toHexString()`.

### 3.3. Dados de referência

```java
// Cultura.java
package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("culturas")
public record Cultura(
        @Id String id,                  // "soja", "feijao", "milho"
        String nome,
        String nomeCientifico,
        String familia,
        Grupo grupo,
        TipoUso tipoUso,
        GrupoP grupoP,                  // nulo para cultura de cobertura
        String nota) {}
```

```java
// FaixaSolo.java
package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("faixas_solo")
public record FaixaSolo(
        @Id String id,                  // "PH_CRITICA", "P_ANUAIS_BAIXO"
        Parametro parametro,
        GrupoP grupoP,                  // somente para o fósforo
        String classe,
        Double limiteMin,               // inclusivo; nulo = sem limite
        Double limiteMax,               // inclusivo; nulo = sem limite
        Tratamento tratamento,
        String fonteId) {}
```

```java
// RegraRotacao.java
package br.com.talhao.model;

import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("regras_rotacao")
public record RegraRotacao(
        @Id String id,                  // "R1" a "R7"
        Efeito efeito,
        String mensagem,
        List<String> fonteIds) {}       // vazia na R7
```

```java
// FonteTecnica.java
package br.com.talhao.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document("fontes_tecnicas")
public record FonteTecnica(
        @Id String id,                  // "F1" a "F7"
        String titulo,
        String autores,
        String instituicao,
        Integer ano,
        String url,
        String escopoRegional) {}
```

## 4. Operações no histórico

Toda consulta de talhão filtra também por `propriedadeId`, que vem do usuário autenticado e nunca do corpo da requisição.

```java
Criteria dono = Criteria.where("id").is(talhaoId).and("propriedadeId").is(propriedadeId);

// registrar plantio
mongo.updateFirst(Query.query(dono), new Update().push("plantios", novoPlantio), Talhao.class);

// registrar análise
mongo.updateFirst(Query.query(dono), new Update().push("analises", novaAnalise), Talhao.class);

// registrar colheita (somente de plantio ainda aberto)
Query aberto = Query.query(new Criteria().andOperator(
        dono,
        Criteria.where("plantios").elemMatch(
                Criteria.where("plantioId").is(plantioId).and("dataColheita").is(null))));
mongo.updateFirst(aberto, new Update().set("plantios.$.dataColheita", data), Talhao.class);

// excluir talhão e histórico
mongo.remove(Query.query(dono), Talhao.class);
```

Respostas de erro:

- Registrar plantio ou análise, e excluir: se `getMatchedCount()` (ou `getDeletedCount()`) for 0, o talhão não existe ou não é do usuário, e a resposta é 404.
- Registrar colheita: o serviço primeiro busca o talhão do dono (404 se não existir) e confere que o plantio existe, que está aberto e que a data não é anterior à `dataPlantio`; falhas de regra respondem 409 ou 400. Só então faz o `update`. O filtro por plantio aberto no `update` impede que dois pedidos simultâneos fechem o mesmo plantio; se `getMatchedCount()` for 0 nesse ponto, a resposta é 409.

O banco não valida datas nem referências, então essas checagens ficam no serviço.

## 5. Faixas de solo no banco

As tabelas do documento `02` usam `<`, `≤` e `>`. No banco, cada classe usa limites inclusivos sobre o valor já arredondado para a precisão da tabela (pH e K com 1 casa decimal, P e V inteiros), com `null` para extremo aberto. O arredondamento é feito antes da comparação, com `Math.round(x * 10) / 10.0` para pH e K. A busca é `limiteMin <= valor <= limiteMax`, e cada valor cai em exatamente uma classe.

| Parâmetro | No documento `02` | No banco (`limiteMin`, `limiteMax`) |
|---|---|---|
| pH | ≤ 4,3 | `null`, 4,3 |
| pH | > 6,0 | 6,1, `null` |
| V | > 90 | 91, `null` |
| P (anuais) | < 16 | `null`, 15 |
| P (anuais) | > 40 | 41, `null` |
| K | < 1,6 | `null`, 1,5 |
| K | > 6,0 | 6,1, `null` |

## 6. Configuração

- **Banco local:** MongoDB em contêiner (`docker compose up -d`), em `mongodb://localhost:27017/talhao`, com a porta aberta só para a própria máquina.
- **Banco da equipe:** MongoDB Atlas, com a URI na variável de ambiente `MONGODB_URI`. Credenciais não vão para o Git.
- **Índices:** `spring.data.mongodb.auto-index-creation=true`, necessário para o índice único do e-mail.
- **Fuso horário:** a JVM usa UTC (`TimeZone.setDefault(TimeZone.getTimeZone("UTC"))` antes do `SpringApplication.run`), para que as datas sem hora não mudem de dia entre ambientes.
- **Dados de referência:** na inicialização, o backend grava cada item dos arquivos de `seed/` por `_id` (grava ou substitui) e depois os carrega em memória. Reiniciar não duplica dados.
- **Senha:** o banco guarda apenas o hash BCrypt, que nunca sai nas respostas da API.
- **Testes:** os testes que gravam no banco usam um banco separado do de desenvolvimento.