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
│   ├── config/       JWT, interceptor e carga dos dados de referência
│   └── model/        classes do banco
└── resources/
    └── application.properties
```

Princípios do modelo:

- Os plantios ficam dentro do documento do talhão: são poucos por talhão e sempre lidos junto com ele. As análises de solo ficam em coleção própria (`analises_solo`), ligadas ao talhão por `talhaoId`. O status do solo usa só a última análise, e o PDF e a linha do tempo leem a lista por talhão.
- Excluir um talhão remove também as análises dele. O serviço de talhões faz essa remoção.
- O banco guarda só o dado bruto. Status do solo, cultura atual e última análise são calculados na leitura. A cultura atual é o plantio mais recente sem `dataColheita`.
- A lista `plantios` é ordenada por data pelo serviço ao ler. As análises são consultadas já ordenadas por `dataColeta`.
- A propriedade é uma coleção própria ligada ao usuário. Cada usuário tem uma única propriedade (RN11), regra verificada no serviço. Uma propriedade só pode ser excluída se não tiver talhões; caso contrário, a API responde 409.
- Os dados de referência (culturas, faixas de solo, regras e fontes) ficam em coleções carregadas na inicialização e mantidas em memória pelo backend.
- O MongoDB não tem chave estrangeira. O serviço valida o `culturaId` contra o catálogo antes de gravar um plantio e valida, antes de gravar uma análise, que o talhão existe e pertence à propriedade do usuário.

## 2. Coleções

| Coleção | Conteúdo | Campos | Índice |
|---|---|---|---|
| `usuarios` | Produtor | `nome`, `email`, `telefone`, `senhaHash`, `criadoEm` | `email` único |
| `propriedades` | Propriedade | `usuarioId`, `nome`, `localizacao` | `usuarioId` |
| `talhoes` | Talhão e plantios | `propriedadeId`, `nome`, `areaHa`, `criadoEm`, `plantios[]` | `propriedadeId` |
| `analises_solo` | Análise de solo | `usuarioId`, `propriedadeId`, `talhaoId`, `dataColeta`, `ph`, `fosforo`, `potassio`, `saturacaoBases`, `observacoes` | `usuarioId`, `propriedadeId`, (`talhaoId`, `dataColeta`) |
| `culturas` | Catálogo de culturas | `nome`, `nomeCientifico`, `familia`, `grupo`, `tipoUso`, `grupoP` | `_id` |
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
  ]
}
```

Exemplo de documento da coleção `analises_solo`:

```js
{
  _id: ObjectId("665f20cc8b3a4d0012ab3601"),
  usuarioId: "665f19ff8b3a4d0012ab33ff",
  propriedadeId: "665f1a118b3a4d0012ab3400",
  talhaoId: "665f1c2e8b3a4d0012ab34cd",
  dataColeta: ISODate("2026-01-10T00:00:00Z"),
  ph: 5.3, fosforo: 30, potassio: 2.0, saturacaoBases: 55,
  observacoes: "Amostra de 0 a 20 cm"
}
```

Só o `_id` é um `ObjectId`. Os demais identificadores (`propriedadeId`, `usuarioId`, `talhaoId`, `plantioId`, `culturaId`) são texto.

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
        List<Plantio> plantios) {

    public Talhao {
        plantios = plantios == null ? List.of() : plantios;
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

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "analises_solo")
@CompoundIndex(name = "talhao_data", def = "{'talhaoId': 1, 'dataColeta': -1}")
public record AnaliseSolo(
        @Id String id,
        @Indexed String usuarioId,
        @Indexed String propriedadeId,
        String talhaoId,
        LocalDate dataColeta,
        Double ph,                  // CaCl2
        Double fosforo,             // P resina, mg/dm³
        Double potassio,            // K, mmolc/dm³
        Double saturacaoBases,      // V, %
        String observacoes) {}
```

O construtor compacto de `Talhao` evita lista nula, o que faria o `$push` falhar. O `plantioId` é gerado pelo servidor com `new ObjectId().toHexString()`.

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
        GrupoP grupoP) {}               // nulo para cultura de cobertura
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

// registrar colheita (somente de plantio ainda aberto)
Query aberto = Query.query(new Criteria().andOperator(
        dono,
        Criteria.where("plantios").elemMatch(
                Criteria.where("plantioId").is(plantioId).and("dataColheita").is(null))));
mongo.updateFirst(aberto, new Update().set("plantios.$.dataColheita", data), Talhao.class);

// excluir talhão e, em seguida, as análises dele
mongo.remove(Query.query(dono), Talhao.class);
analiseSoloRepository.deleteByTalhaoId(talhaoId);
```

Respostas de erro:

- Registrar plantio e excluir: se `getMatchedCount()` (ou `getDeletedCount()`) for 0, o talhão não existe ou não é do usuário, e a resposta é 404.
- Registrar colheita: o serviço primeiro busca o talhão do dono (404 se não existir) e confere que o plantio existe, que está aberto e que a data não é anterior à `dataPlantio`; falhas de regra respondem 409 ou 400. Só então faz o `update`. O filtro por plantio aberto no `update` impede que dois pedidos simultâneos fechem o mesmo plantio; se `getMatchedCount()` for 0 nesse ponto, a resposta é 409.

- Registrar ou editar análise: o serviço confere que a propriedade é do usuário e que o talhão existe nessa propriedade (404 se não existir).
- Cadastrar propriedade: se o usuário já tem uma, a resposta é 409 (RN11).
- Excluir propriedade: se ela ainda tem talhões, a resposta é 409.

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
- **Dados de referência:** na inicialização, uma classe Java (`ApplicationRunner`) grava cada item por `_id` (grava ou substitui), e o backend os mantém em memória. Reiniciar não duplica dados.
- **Senha:** o banco guarda apenas o hash BCrypt, que nunca sai nas respostas da API.
- **Testes:** os testes que gravam no banco usam um banco separado do de desenvolvimento.