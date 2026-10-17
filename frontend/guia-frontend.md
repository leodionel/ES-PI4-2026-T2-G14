# Guia do Front-end — Prontuário Digital do Talhão

**Equipe G-14**
**Versão:** 1 — proposta para validação do grupo e do professor
**Documentos complementares:** `01-mvp-e-requisitos.md` (o que o sistema faz) e `02-regras-agronomicas.md` (como o sistema decide)
**Tecnologia:** app mobile em Flutter (Dart), conversando com um servidor em Java

Este guia explica como o app deve ser construído e como cada parte deve funcionar. Foi escrito para que qualquer pessoa, mesmo sem ter participado das conversas anteriores, consiga entender a estrutura e começar a trabalhar.

> **Estado do projeto:** ainda não existe código. Este guia é a especificação do front-end. A API do servidor ainda não foi definida, então tudo que depende dela está marcado como pendência na seção 15.

---

## 0. Como usar este guia

| Se você quer... | Leia |
|---|---|
| Entender o app em 5 minutos | Seções 1 e 3 |
| Saber onde fica cada arquivo e o que ele faz | Seção 4 |
| Criar ou alterar uma tela | Seções 7, 8, 10 e 13 |
| Mexer em dados e na comunicação com o servidor | Seções 5 e 6 |
| Entender rotas, login e sessão | Seção 9 |
| Escolher cores e textos | Seção 11 |
| Escrever testes | Seção 12 |
| Saber o que ainda está indefinido | Seção 15 |
| Entender uma palavra técnica | Seção 16 |
| Descobrir qual tela atende a qual requisito | Apêndice A |

---

## 1. Visão geral e princípios

### O que o app faz

O produtor rural cadastra seus talhões, registra o que plantou em cada um e os resultados das análises de solo. O app mostra o histórico em linha do tempo, destaca os talhões com solo fora da faixa e compara de 2 a 3 culturas para a próxima safra, indicando qual combina melhor com o histórico.

### O que o app não faz

- Não calcula o status do solo nem a recomendação de cultura. Isso é feito pelo servidor, com as regras do documento `02`. O app só exibe o que recebe.
- Não prescreve doses de calcário ou adubo.
- Não funciona sem internet no MVP.
- Não trata mais de uma propriedade por conta no MVP.

### Regras de ouro

1. A **view** só exibe dados e captura toques e digitação. Não tem lógica de negócio e não chama o servidor.
2. A **ViewModel** guarda o estado da tela e chama repositories. Não conhece widgets nem HTTP.
3. O **repository** é a única porta de dados para a ViewModel. Devolve modelos Dart, nunca JSON.
4. O **service** conversa com o mundo externo (HTTP, armazenamento seguro, arquivos). Nenhuma outra camada usa `package:http` diretamente.
5. As regras agronômicas e seus limites **nunca** são escritos no app.
6. Toda dependência chega por **injeção** (provider). Nenhuma classe cria os próprios repositories.
7. Todo repository tem uma versão **fake**, para o app rodar e ser testado sem servidor.
8. Textos oficiais vêm de `app_textos.dart`. Cores e fontes vêm de `core/theme`.
9. Toda tela trata quatro situações: **carregando**, **erro**, **vazio** e **sucesso**.

---

## 2. Tecnologias e pacotes

| Pacote | Para quê | Observação |
|---|---|---|
| `flutter` (SDK) | Interface | |
| `provider` | Injeção de dependência e observar ViewModels | Recomendado na documentação oficial do Flutter |
| `go_router` | Navegação, rotas protegidas e abas | Recomendado na documentação oficial |
| `http` | Chamadas ao servidor | Usado somente dentro de `api_client.dart` (e, nos testes, pelo `MockClient`) |
| `flutter_secure_storage` | Guardar o token de sessão | Nunca usar `SharedPreferences` para o token |
| `intl` | Formatar datas e números em português | |
| `flutter_lints` (desenvolvimento) | Análise estática do código | |

**Não adicionar no MVP:** Bloc, Riverpod, `freezed`, `json_serializable`, banco de dados local e bibliotecas de gráficos. Cada um acrescenta complexidade que o escopo não exige. Os modelos têm `fromJson` escrito à mão, e os gráficos do Dashboard são feitos com widgets simples.

Pacote para abrir ou compartilhar o PDF: **a definir** (pendência P5). As versões dos pacotes devem ser fixadas no `pubspec.yaml` quando o projeto for criado.

---

## 3. Arquitetura

O app segue o padrão recomendado pela documentação oficial do Flutter: **MVVM** com duas camadas.

```
 Camada de UI                      Camada de dados
 ┌──────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────┐
 │  View    │──▶│  ViewModel   │──▶│  Repository  │──▶│ Service  │──▶ servidor Java
 │ (tela)   │◀──│ (estado)     │◀──│ (dados)      │◀──│ (HTTP...) │◀──
 └──────────┘   └──────────────┘   └──────────────┘   └──────────┘
```

### Quem pode chamar quem

| Origem | Pode chamar | Não pode chamar |
|---|---|---|
| View | Sua ViewModel (por `provider`), widgets, navegação | Repository, Service, `http` |
| ViewModel | Repositories e `ArquivoService` | Widgets, `BuildContext`, `ApiClient`, `http` |
| Repository | `ApiClient`, `TokenStorage` | ViewModel, widgets |
| Service | Bibliotecas externas (`http`, armazenamento seguro, arquivos) | Repositories, ViewModels |
| Modelos de domínio | Nada | Qualquer outra camada |

### O caminho de uma ação

Exemplo: o produtor abre a lista de talhões.

1. A `TalhaoListView` aparece e a rota já criou a `TalhaoListViewModel` e chamou `carregar()`.
2. A ViewModel muda o status para **carregando** e pede ao `TalhaoRepository.listar()`.
3. O repository remoto chama o `ApiClient.get`, que envia a requisição ao servidor Java com o token de sessão.
4. O JSON volta, o repository o transforma em `List<Talhao>` e devolve.
5. A ViewModel guarda a lista, muda o status para **sucesso** e avisa a view.
6. A view se redesenha mostrando os cartões.

Se algo falha, o `ApiClient` lança uma `AppException`, a ViewModel guarda a mensagem e muda o status para **erro**, e a view mostra a mensagem com o botão "Tentar novamente".

---

## 4. Estrutura de pastas e arquivos

A camada de UI é organizada **por funcionalidade**, para que duas pessoas trabalhem em telas diferentes sem conflito no Git.

### 4.1. Árvore completa

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── dependencies.dart
│   ├── routes.dart
│   └── env.dart
├── core/
│   ├── app_textos.dart
│   ├── app_exception.dart
│   ├── base_view_model.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── status_chip.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_message.dart
│   │   └── empty_state.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
├── domain/
│   └── models/
│       ├── usuario.dart
│       ├── propriedade.dart
│       ├── talhao.dart
│       ├── cultura.dart
│       ├── registro_cultura.dart
│       ├── analise_solo.dart
│       ├── evento_historico.dart
│       ├── mensagem_regra.dart
│       ├── cenario_resultado.dart
│       ├── resultado_simulacao.dart
│       ├── status_solo.dart
│       └── classificacao.dart
├── data/
│   ├── services/
│   │   ├── api_client.dart
│   │   ├── token_storage.dart
│   │   └── arquivo_service.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── auth_repository_remote.dart
│       ├── auth_repository_fake.dart
│       ├── perfil_repository.dart
│       ├── perfil_repository_remote.dart
│       ├── perfil_repository_fake.dart
│       ├── talhao_repository.dart
│       ├── talhao_repository_remote.dart
│       ├── talhao_repository_fake.dart
│       ├── historico_repository.dart
│       ├── historico_repository_remote.dart
│       ├── historico_repository_fake.dart
│       ├── cultura_repository.dart
│       ├── cultura_repository_remote.dart
│       ├── cultura_repository_fake.dart
│       ├── simulacao_repository.dart
│       ├── simulacao_repository_remote.dart
│       └── simulacao_repository_fake.dart
└── ui/
    ├── auth/
    │   ├── splash_view.dart
    │   ├── login_view.dart
    │   ├── login_view_model.dart
    │   ├── cadastro_view.dart
    │   ├── cadastro_view_model.dart
    │   ├── esqueci_senha_view.dart
    │   └── esqueci_senha_view_model.dart
    ├── shell/
    │   └── main_shell.dart
    ├── dashboard/
    │   ├── dashboard_view.dart
    │   └── dashboard_view_model.dart
    ├── talhoes/
    │   ├── talhao_list_view.dart
    │   ├── talhao_list_view_model.dart
    │   ├── talhao_form_view.dart
    │   ├── talhao_form_view_model.dart
    │   ├── talhao_detalhe_view.dart
    │   ├── talhao_detalhe_view_model.dart
    │   └── widgets/
    │       ├── talhao_card.dart
    │       ├── timeline_item.dart
    │       ├── excluir_talhao_dialog.dart
    │       └── registrar_colheita_dialog.dart
    ├── historico/
    │   ├── registrar_cultura_view.dart
    │   ├── registrar_cultura_view_model.dart
    │   ├── registrar_analise_view.dart
    │   └── registrar_analise_view_model.dart
    ├── simulacao/
    │   ├── simulacao_view.dart
    │   ├── simulacao_view_model.dart
    │   └── widgets/
    │       └── cenario_card.dart
    └── perfil/
        ├── perfil_view.dart
        └── perfil_view_model.dart
```

O diretório `test/` espelha `lib/` (seção 12).

### 4.2. O que cada pasta contém

#### `lib/`

Arquivos de entrada do app.

| Arquivo | Responsabilidade |
|---|---|
| `main.dart` | Ponto de entrada. Escolhe os providers (reais ou fake, conforme `USAR_FAKE`) e inicia o `App`. |
| `app.dart` | Widget raiz: cria o roteador uma única vez e aplica o tema. Sem lógica de tela. |

#### `lib/config/`

Configuração global do app. Não tem lógica de tela.

| Arquivo | Responsabilidade |
|---|---|
| `dependencies.dart` | Listas de providers (remotos e fake). Cria `TokenStorage`, `ApiClient`, `ArquivoService` e os repositories. É o único lugar que decide qual implementação usar. |
| `routes.dart` | Todas as rotas, o redirecionamento de sessão e a criação de cada ViewModel com `ChangeNotifierProvider`. |
| `env.dart` | Constantes de ambiente lidas de `--dart-define`: `API_URL` e `USAR_FAKE`. |

#### `lib/core/`

Peças compartilhadas por todo o app, independentes de funcionalidade.

| Arquivo | Responsabilidade |
|---|---|
| `app_textos.dart` | Textos oficiais compartilhados: rótulos de status e classificação, aviso de apoio à decisão e texto de equivalência (seção 11). |
| `app_exception.dart` | `AppException` e `TipoErro`: erros que sobem do `ApiClient` até a ViewModel, já com mensagem para o usuário. |
| `base_view_model.dart` | `UiStatus` e `BaseViewModel`: estado de carregando, sucesso ou erro e o método `executar`, usados por todas as ViewModels. |

#### `lib/core/theme/`

Identidade visual do app.

| Arquivo | Responsabilidade |
|---|---|
| `app_colors.dart` | Constantes de cor (seção 11). Nenhuma cor é escrita direto nas telas. |
| `app_theme.dart` | `ThemeData` do app: cores, tipografia, botões e campos de texto. |

#### `lib/core/widgets/`

Widgets usados em mais de uma tela. Não conhecem ViewModels nem repositories.

| Arquivo | Responsabilidade |
|---|---|
| `app_button.dart` | Botão padrão (primário e secundário), com altura mínima de 48 dp e estado de carregando. |
| `app_text_field.dart` | Campo de texto padrão com rótulo, unidade opcional, mensagem de erro e opção de mostrar ou ocultar senha. |
| `status_chip.dart` | Selo do status do solo com cor, ícone e texto. Recebe um `StatusSolo`. |
| `loading_indicator.dart` | Indicador de carregamento centralizado. |
| `error_message.dart` | Mensagem de erro com o botão "Tentar novamente". |
| `empty_state.dart` | Estado vazio com texto e botão de ação opcional. |

#### `lib/core/utils/`

Funções de apoio, sem dependência de telas ou dados.

| Arquivo | Responsabilidade |
|---|---|
| `validators.dart` | Validações de formulário (obrigatório, e-mail, telefone, faixa numérica, datas). Devolvem a mensagem de erro ou nulo. |
| `formatters.dart` | Converte número com vírgula ("5,3") em `double` e formata números e datas em português. |

#### `lib/domain/models/`

Classes de dados descritas na seção 5. Não dependem de nenhuma outra camada.

| Arquivo | Responsabilidade |
|---|---|
| `usuario.dart` | Dados do produtor. |
| `propriedade.dart` | Dados da propriedade (nome e localização). |
| `talhao.dart` | Talhão com área, cultura atual, status do solo, motivos e data do último laudo. |
| `cultura.dart` | Cultura do catálogo, com nome e tipo de uso. |
| `registro_cultura.dart` | Cultura plantada em um talhão, com datas de plantio e colheita. |
| `analise_solo.dart` | Laudo de solo: pH, fósforo, potássio, V% e MO opcional. |
| `evento_historico.dart` | Item da linha do tempo (plantio, colheita ou análise). Montado pela ViewModel. |
| `mensagem_regra.dart` | Texto de uma regra aplicada e sua fonte técnica. |
| `cenario_resultado.dart` | Resultado de uma cultura na simulação: classificação, alerta e mensagens. |
| `resultado_simulacao.dart` | Conjunto de cenários e a indicação de equivalência. |
| `status_solo.dart` | Enum `StatusSolo` com a conversão do texto do servidor. |
| `classificacao.dart` | Enum `Classificacao` (recomendado, aceitável, não recomendado). |

#### `lib/data/services/`

Acesso ao mundo externo: HTTP, armazenamento seguro e arquivos. Só repositories e configuração os usam.

| Arquivo | Responsabilidade |
|---|---|
| `api_client.dart` | Único ponto que usa `package:http`. Monta a URL, envia JSON, anexa o token, aplica tempo limite e traduz falhas em `AppException` (seção 6.1). |
| `token_storage.dart` | Guarda, lê e apaga o token de sessão em armazenamento seguro. |
| `arquivo_service.dart` | Salva os bytes de um PDF em arquivo temporário e o abre ou compartilha (`salvarEAbrirPdf`). |

#### `lib/data/repositories/`

Para cada tipo de dado: contrato, implementação remota e implementação fake (seção 6.4).

| Arquivo | Responsabilidade |
|---|---|
| `auth_repository.dart` | Contrato de `AuthRepository`. É um `ChangeNotifier` que expõe `autenticado` e `iniciando`, além dos métodos (seção 6.4). |
| `auth_repository_remote.dart` | Implementação real de `AuthRepository`: chama o `ApiClient`, guarda e apaga o token e atualiza `autenticado`. |
| `auth_repository_fake.dart` | Implementação de `AuthRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |
| `perfil_repository.dart` | Contrato de `PerfilRepository`: métodos que as ViewModels podem chamar (seção 6.4). Não cita HTTP nem JSON. |
| `perfil_repository_remote.dart` | Implementação real de `PerfilRepository`: chama o `ApiClient` e converte JSON em modelos. Aqui ficam os caminhos da API. |
| `perfil_repository_fake.dart` | Implementação de `PerfilRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |
| `talhao_repository.dart` | Contrato de `TalhaoRepository`: métodos que as ViewModels podem chamar (seção 6.4). Não cita HTTP nem JSON. |
| `talhao_repository_remote.dart` | Implementação real de `TalhaoRepository`: chama o `ApiClient` e converte JSON em modelos. Aqui ficam os caminhos da API. |
| `talhao_repository_fake.dart` | Implementação de `TalhaoRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |
| `historico_repository.dart` | Contrato de `HistoricoRepository`: métodos que as ViewModels podem chamar (seção 6.4). Não cita HTTP nem JSON. |
| `historico_repository_remote.dart` | Implementação real de `HistoricoRepository`: chama o `ApiClient` e converte JSON em modelos. Aqui ficam os caminhos da API. |
| `historico_repository_fake.dart` | Implementação de `HistoricoRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |
| `cultura_repository.dart` | Contrato de `CulturaRepository`: métodos que as ViewModels podem chamar (seção 6.4). Não cita HTTP nem JSON. |
| `cultura_repository_remote.dart` | Implementação real de `CulturaRepository`: chama o `ApiClient` e converte JSON em modelos. Aqui ficam os caminhos da API. |
| `cultura_repository_fake.dart` | Implementação de `CulturaRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |
| `simulacao_repository.dart` | Contrato de `SimulacaoRepository`: métodos que as ViewModels podem chamar (seção 6.4). Não cita HTTP nem JSON. |
| `simulacao_repository_remote.dart` | Implementação real de `SimulacaoRepository`: chama o `ApiClient` e converte JSON em modelos. Aqui ficam os caminhos da API. |
| `simulacao_repository_fake.dart` | Implementação de `SimulacaoRepository` com dados de exemplo, para rodar o app e os testes sem servidor. |

#### `lib/ui/auth/`

Telas de acesso: sessão, login, cadastro e recuperação de senha.

| Arquivo | Responsabilidade |
|---|---|
| `splash_view.dart` | Tela de abertura enquanto a sessão salva é lida. Sem ViewModel. |
| `login_view.dart` | Tela de login (RF02). |
| `login_view_model.dart` | Estado e ação de entrar. Valida os campos e chama `AuthRepository.entrar`. |
| `cadastro_view.dart` | Tela de criação de conta (RF01). |
| `cadastro_view_model.dart` | Estado e ação de cadastrar. Chama `AuthRepository.cadastrar`. |
| `esqueci_senha_view.dart` | Tela de recuperação de senha (RF03). |
| `esqueci_senha_view_model.dart` | Estado e ação de enviar o pedido de recuperação. |

#### `lib/ui/shell/`

Moldura das telas principais.

| Arquivo | Responsabilidade |
|---|---|
| `main_shell.dart` | Mostra a aba atual e a barra de navegação inferior com Dashboard, Talhões, Simulação e Perfil. |

#### `lib/ui/dashboard/`

Visão geral da propriedade.

| Arquivo | Responsabilidade |
|---|---|
| `dashboard_view.dart` | Tela do Dashboard (RF12 a RF14). |
| `dashboard_view_model.dart` | Carrega os talhões e calcula área total, contagens por status e lista de atenção (agregações de exibição). |

#### `lib/ui/talhoes/`

Lista, formulário e detalhe de talhões.

| Arquivo | Responsabilidade |
|---|---|
| `talhao_list_view.dart` | Lista de talhões (RF06, RF07). |
| `talhao_list_view_model.dart` | Carrega e expõe a lista de talhões. |
| `talhao_form_view.dart` | Formulário de criação e edição de talhão (RF06). |
| `talhao_form_view_model.dart` | Estado do formulário. Carrega o talhão na edição e salva. |
| `talhao_detalhe_view.dart` | Detalhe do talhão com status, última análise, linha do tempo e ações (RF11, RF21). |
| `talhao_detalhe_view_model.dart` | Carrega talhão e histórico, monta a linha do tempo, registra colheita, exporta PDF e exclui o talhão. |

#### `lib/ui/talhoes/widgets/`

Widgets e diálogos usados só nas telas de talhão.

| Arquivo | Responsabilidade |
|---|---|
| `talhao_card.dart` | Cartão de um talhão na lista e no Dashboard. |
| `timeline_item.dart` | Item da linha do tempo, com ícone por tipo de evento. |
| `excluir_talhao_dialog.dart` | Diálogo de exclusão: avisa o que será apagado e exige o nome do talhão (RF22, RF23). |
| `registrar_colheita_dialog.dart` | Diálogo para informar a data de colheita (RF09). |

#### `lib/ui/historico/`

Formulários de registro no histórico do talhão.

| Arquivo | Responsabilidade |
|---|---|
| `registrar_cultura_view.dart` | Formulário para registrar a cultura plantada (RF08). |
| `registrar_cultura_view_model.dart` | Carrega o catálogo de culturas e salva o registro. |
| `registrar_analise_view.dart` | Formulário de análise de solo (RF10). |
| `registrar_analise_view_model.dart` | Estado do formulário de análise. Salva o laudo. |

#### `lib/ui/simulacao/`

Simulação e comparação de cenários.

| Arquivo | Responsabilidade |
|---|---|
| `simulacao_view.dart` | Tela de simulação em etapas: talhão, culturas e resultado (RF15 a RF20). |
| `simulacao_view_model.dart` | Controla as etapas e as escolhas (até 3 culturas) e chama `SimulacaoRepository.simular`. |

#### `lib/ui/simulacao/widgets/`

Widgets usados só na simulação.

| Arquivo | Responsabilidade |
|---|---|
| `cenario_card.dart` | Cartão de um cenário: cultura, classificação, mensagens e fontes (RF17 a RF19). |

#### `lib/ui/perfil/`

Dados do produtor, da propriedade e saída da conta.

| Arquivo | Responsabilidade |
|---|---|
| `perfil_view.dart` | Tela de perfil com edição de dados e botão "Sair da conta" (RF04, RF05). |
| `perfil_view_model.dart` | Carrega e salva usuário e propriedade, e encerra a sessão. |


---

## 5. Modelos de domínio

Os modelos ficam em `lib/domain/models/`. São classes imutáveis que apenas guardam dados, sem regra de negócio e sem dependência de outras camadas. Os nomes dos campos no JSON são **provisórios** até o contrato da API ser definido (P1).

| Modelo | Arquivo | Campos |
|---|---|---|
| `Usuario` | `usuario.dart` | `id`, `nome`, `email`, `telefone` |
| `Propriedade` | `propriedade.dart` | `id`, `nome`, `localizacao` |
| `Talhao` | `talhao.dart` | `id`, `nome`, `areaHa`, `culturaAtual` (opcional), `statusSolo`, `motivosStatus`, `ultimaAnalise` (opcional) |
| `Cultura` | `cultura.dart` | `id`, `nome`, `tipoUso` (comercial ou cobertura) |
| `RegistroCultura` | `registro_cultura.dart` | `id`, `talhaoId`, `culturaId`, `culturaNome`, `dataPlantio`, `dataColheita` (opcional) |
| `AnaliseSolo` | `analise_solo.dart` | `id`, `talhaoId`, `data`, `ph`, `fosforo`, `potassio`, `v`, `mo` (opcional), `leituraMo` (opcional, texto vindo do servidor) |
| `EventoHistorico` | `evento_historico.dart` | `tipo` (plantio, colheita ou análise), `data`, `titulo`, `descricao`. Montado pela ViewModel para a linha do tempo, não vem do servidor |
| `MensagemRegra` | `mensagem_regra.dart` | `texto`, `fonte` |
| `CenarioResultado` | `cenario_resultado.dart` | `cultura`, `classificacao`, `temAlerta`, `mensagens` |
| `ResultadoSimulacao` | `resultado_simulacao.dart` | `cenarios`, `equivalentes` |
| `StatusSolo` | `status_solo.dart` | Enum: `semAlertas`, `atencao`, `risco`, `semAnalise` |
| `Classificacao` | `classificacao.dart` | Enum: `recomendado`, `aceitavel`, `naoRecomendado` |

Observações:

- `semAnalise` representa um talhão que ainda não tem laudo. Esse caso não está definido nos documentos `01` e `02` (pendência P7).
- "Aceitável com alerta" não é um valor do enum. É uma classificação `aceitavel` com `temAlerta` verdadeiro.
- O `v` de `AnaliseSolo` é a saturação por bases (V%).

Exemplo de modelo com enum:

```dart
enum StatusSolo {
  semAlertas,
  atencao,
  risco,
  semAnalise;

  static StatusSolo fromJson(String? valor) {
    switch (valor) {
      case 'SEM_ALERTAS':
        return StatusSolo.semAlertas;
      case 'ATENCAO':
        return StatusSolo.atencao;
      case 'RISCO':
        return StatusSolo.risco;
      default:
        return StatusSolo.semAnalise;
    }
  }
}

class Talhao {
  const Talhao({
    required this.id,
    required this.nome,
    required this.areaHa,
    this.culturaAtual,
    this.statusSolo = StatusSolo.semAnalise,
    this.motivosStatus = const [],
    this.ultimaAnalise,
  });

  final String id;
  final String nome;
  final double areaHa;
  final String? culturaAtual;
  final StatusSolo statusSolo;
  final List<String> motivosStatus;
  final DateTime? ultimaAnalise;

  factory Talhao.fromJson(Map<String, dynamic> json) {
    return Talhao(
      id: json['id'] as String,
      nome: json['nome'] as String,
      areaHa: (json['areaHa'] as num).toDouble(),
      culturaAtual: json['culturaAtual'] as String?,
      statusSolo: StatusSolo.fromJson(json['statusSolo'] as String?),
      motivosStatus: (json['motivosStatus'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      ultimaAnalise: json['ultimaAnalise'] == null
          ? null
          : DateTime.parse(json['ultimaAnalise'] as String),
    );
  }
}
```

---

## 6. Camada de dados

### 6.1. ApiClient (`api_client.dart`)

É o único ponto que fala HTTP. Responsabilidades:

- Montar a URL com a base de `Env.apiUrl` e o caminho recebido.
- Enviar e receber JSON.
- Anexar o token de sessão (lido do `TokenStorage`) quando existir.
- Aplicar um tempo limite às requisições.
- Traduzir falhas em `AppException`, conforme a tabela abaixo.
- Quando receber 401, avisar a sessão por meio do callback `aoNaoAutorizado`, que o `AuthRepositoryRemote` configura ao ser criado. Isso evita dependência circular entre `ApiClient` e `AuthRepository`.

O construtor aceita um `http.Client` opcional, para os testes usarem um cliente simulado.

| Situação | Exceção |
|---|---|
| Sem conexão ou tempo esgotado | `AppException(TipoErro.rede, ...)` |
| Status 401 | `AppException(TipoErro.naoAutorizado, ...)` e dispara `aoNaoAutorizado` |
| Status 400 ou 422 | `AppException(TipoErro.validacao, ...)` com a mensagem do servidor |
| Status 404 | `AppException(TipoErro.naoEncontrado, ...)` |
| Status 5xx ou resposta ilegível | `AppException(TipoErro.servidor, ...)` |

Atenção ao login: um 401 na tela de login significa credenciais inválidas, e não sessão expirada. Nesse caso a mensagem exibida deve ser a do servidor, e a sessão não precisa ser encerrada (já não existe). O formato do corpo de erro do servidor ainda não foi definido (P3).

```dart
enum TipoErro { rede, naoAutorizado, validacao, naoEncontrado, servidor }

class AppException implements Exception {
  const AppException(this.tipo, this.mensagem);

  final TipoErro tipo;
  final String mensagem;
}
```

### 6.2. TokenStorage (`token_storage.dart`)

Guarda, lê e apaga o token de sessão usando `flutter_secure_storage`. Métodos: `ler()`, `salvar(token)` e `apagar()`.

### 6.3. ArquivoService (`arquivo_service.dart`)

Recebe os bytes de um PDF, salva em um arquivo temporário e o abre no leitor do aparelho (ou compartilha). Método: `salvarEAbrirPdf(bytes, nomeArquivo)`. O pacote usado é a pendência P5.

### 6.4. Repositories

Cada repository tem três arquivos: o **contrato** (classe abstrata), a **implementação remota** e a **implementação fake**. As ViewModels dependem apenas do contrato.

Contratos e métodos consumidos pelas ViewModels e pela configuração:

| Classe | Método | Usado por |
|---|---|---|
| `AuthRepository` | `iniciar()` | `dependencies.dart` |
| `AuthRepository` | `entrar(email, senha)` | `LoginViewModel` |
| `AuthRepository` | `cadastrar(nome, email, telefone, senha)` | `CadastroViewModel` |
| `AuthRepository` | `recuperarSenha(email)` | `EsqueciSenhaViewModel` |
| `AuthRepository` | `sair()` | `PerfilViewModel` |
| `PerfilRepository` | `obterUsuario()` | `PerfilViewModel` |
| `PerfilRepository` | `obterPropriedade()` | `PerfilViewModel` |
| `PerfilRepository` | `atualizarUsuario(nome, telefone)` | `PerfilViewModel` |
| `PerfilRepository` | `atualizarPropriedade(nome, localizacao)` | `PerfilViewModel` |
| `TalhaoRepository` | `listar()` | `TalhaoListViewModel`, `DashboardViewModel`, `SimulacaoViewModel` |
| `TalhaoRepository` | `obter(id)` | `TalhaoDetalheViewModel`, `TalhaoFormViewModel` |
| `TalhaoRepository` | `criar(nome, areaHa)` | `TalhaoFormViewModel` |
| `TalhaoRepository` | `atualizar(id, nome, areaHa)` | `TalhaoFormViewModel` |
| `TalhaoRepository` | `excluir(id, nomeConfirmacao)` | `TalhaoDetalheViewModel` |
| `TalhaoRepository` | `baixarProntuarioPdf(id)` | `TalhaoDetalheViewModel` |
| `HistoricoRepository` | `listarCulturas(talhaoId)` | `TalhaoDetalheViewModel` |
| `HistoricoRepository` | `listarAnalises(talhaoId)` | `TalhaoDetalheViewModel` |
| `HistoricoRepository` | `registrarCultura(talhaoId, culturaId, dataPlantio)` | `RegistrarCulturaViewModel` |
| `HistoricoRepository` | `registrarColheita(registroId, dataColheita)` | `TalhaoDetalheViewModel` |
| `HistoricoRepository` | `registrarAnalise(talhaoId, data, ph, fosforo, potassio, v, mo)` | `RegistrarAnaliseViewModel` |
| `CulturaRepository` | `catalogo()` | `RegistrarCulturaViewModel`, `SimulacaoViewModel` |
| `SimulacaoRepository` | `simular(talhaoId, culturaIds)` | `SimulacaoViewModel` |
| `ArquivoService` | `salvarEAbrirPdf(bytes, nomeArquivo)` | `TalhaoDetalheViewModel` |

Além dos métodos, o `AuthRepository` é um `ChangeNotifier` que expõe `autenticado` e `iniciando`. O roteador escuta essas duas informações para decidir qual tela mostrar.

Regras dos repositories:

- O contrato não menciona HTTP, JSON nem `ApiClient`.
- A implementação remota é o **único** lugar onde caminhos de API e nomes de campos JSON aparecem (junto com os `fromJson` dos modelos). Quando o contrato da API for definido (P1), só esses arquivos mudam.
- A implementação fake devolve dados de exemplo coerentes com os casos de teste da seção 7 do documento `02`. O fake da simulação devolve um resultado fixo, e não implementa as regras.
- Erros sobem como `AppException`. O repository não mostra mensagem na tela.

Exemplo do trio para listar talhões:

```dart
// talhao_repository.dart
abstract class TalhaoRepository {
  Future<List<Talhao>> listar();
}

// talhao_repository_remote.dart
class TalhaoRepositoryRemote implements TalhaoRepository {
  TalhaoRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<List<Talhao>> listar() async {
    final json = await _api.get('/talhoes') as List<dynamic>;
    return json
        .map((e) => Talhao.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// talhao_repository_fake.dart
class TalhaoRepositoryFake implements TalhaoRepository {
  @override
  Future<List<Talhao>> listar() async {
    return const [
      Talhao(
        id: '1',
        nome: 'Talhão 01',
        areaHa: 18.2,
        culturaAtual: 'Milho',
        statusSolo: StatusSolo.semAlertas,
      ),
      Talhao(
        id: '2',
        nome: 'Talhão 02',
        areaHa: 25.6,
        culturaAtual: 'Feijão',
        statusSolo: StatusSolo.atencao,
        motivosStatus: ['Potássio baixo'],
      ),
    ];
  }
}
```

O caminho `/talhoes` é ilustrativo (P1).

### 6.5. Sessão

O `AuthRepositoryRemote` guarda o token ao entrar, apaga ao sair e atualiza `autenticado`. Ao iniciar o app, `iniciar()` lê o token salvo: enquanto lê, `iniciando` é verdadeiro. Detalhes na seção 9.

### 6.6. Injeção de dependência e modo fake

`dependencies.dart` devolve duas listas de providers: uma com as implementações remotas e outra com as fake. O `main.dart` escolhe pela constante `USAR_FAKE`. Assim o grupo roda o app sem servidor com:

```
flutter run --dart-define=USAR_FAKE=true
```

```dart
class Env {
  static const apiUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');
  static const usarFake = bool.fromEnvironment('USAR_FAKE');
}

List<SingleChildWidget> providersRemotos() => [
      Provider<TokenStorage>(create: (_) => TokenStorage()),
      Provider<ApiClient>(
        create: (ctx) => ApiClient(
          baseUrl: Env.apiUrl,
          tokens: ctx.read<TokenStorage>(),
        ),
      ),
      ChangeNotifierProvider<AuthRepository>(
        create: (ctx) => AuthRepositoryRemote(
          api: ctx.read<ApiClient>(),
          tokens: ctx.read<TokenStorage>(),
        )..iniciar(),
      ),
      Provider<TalhaoRepository>(
        create: (ctx) => TalhaoRepositoryRemote(ctx.read<ApiClient>()),
      ),
      // demais repositories seguem o mesmo padrão
    ];

void main() {
  runApp(
    MultiProvider(
      providers: Env.usarFake ? providersFake() : providersRemotos(),
      child: const App(),
    ),
  );
}
```

A porta `8080` e o endereço `10.0.2.2` (como o emulador Android enxerga o computador) são valores de desenvolvimento.

---

## 7. Camada de UI

### 7.1. BaseViewModel (`base_view_model.dart`)

Todas as ViewModels herdam dela. Ela guarda o status e a mensagem de erro e oferece `executar`, que envolve qualquer ação assíncrona: marca carregando, executa, trata `AppException` e avisa a view.

```dart
enum UiStatus { inicial, carregando, sucesso, erro }

abstract class BaseViewModel extends ChangeNotifier {
  UiStatus _status = UiStatus.inicial;
  String? _erro;
  bool _descartado = false;

  UiStatus get status => _status;
  String? get erro => _erro;

  Future<void> executar(Future<void> Function() acao) async {
    _status = UiStatus.carregando;
    _erro = null;
    notifyListeners();
    try {
      await acao();
      _status = UiStatus.sucesso;
    } on AppException catch (e) {
      _erro = e.mensagem;
      _status = UiStatus.erro;
    } catch (_) {
      _erro = 'Algo deu errado. Tente novamente.';
      _status = UiStatus.erro;
    }
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
```

### 7.2. ViewModel típica

```dart
class TalhaoListViewModel extends BaseViewModel {
  TalhaoListViewModel(this._repo);

  final TalhaoRepository _repo;
  List<Talhao> _talhoes = [];

  List<Talhao> get talhoes => List.unmodifiable(_talhoes);

  Future<void> carregar() => executar(() async {
        _talhoes = await _repo.listar();
      });
}
```

Regras de uma ViewModel:

- Recebe seus repositories pelo construtor.
- Expõe estado por getters somente leitura e ações por métodos.
- Não importa `package:flutter/material.dart`, não usa `BuildContext` e não navega.
- Toda ação assíncrona passa por `executar`.

### 7.3. View típica

A view observa a ViewModel com `context.watch` e trata os quatro estados.

```dart
class TalhaoListView extends StatelessWidget {
  const TalhaoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TalhaoListViewModel>();

    switch (vm.status) {
      case UiStatus.inicial:
      case UiStatus.carregando:
        return const LoadingIndicator();
      case UiStatus.erro:
        return ErrorMessage(
          texto: vm.erro ?? 'Algo deu errado.',
          aoTentarNovamente: vm.carregar,
        );
      case UiStatus.sucesso:
        if (vm.talhoes.isEmpty) {
          return const EmptyState(texto: 'Você ainda não cadastrou talhões.');
        }
        return ListView.builder(
          itemCount: vm.talhoes.length,
          itemBuilder: (context, i) => TalhaoCard(
            talhao: vm.talhoes[i],
            aoTocar: () => context.go('/talhoes/${vm.talhoes[i].id}'),
          ),
        );
    }
  }
}
```

Regras de uma view:

- Não chama repository, não usa `http` e não decide regra de negócio.
- Navegação acontece na view. Depois de um `await`, confira `context.mounted` antes de navegar.
- Telas de formulário são abertas com `context.push`, que devolve um resultado quando a tela fecha. A tela de origem recarrega seus dados ao voltar.
- Botões ficam desabilitados enquanto o status é `carregando`, para evitar toques duplos.

### 7.4. ViewModels e suas dependências

| ViewModel | Arquivo | Dependências |
|---|---|---|
| `LoginViewModel` | `login_view_model.dart` | `AuthRepository.entrar` |
| `CadastroViewModel` | `cadastro_view_model.dart` | `AuthRepository.cadastrar` |
| `EsqueciSenhaViewModel` | `esqueci_senha_view_model.dart` | `AuthRepository.recuperarSenha` |
| `DashboardViewModel` | `dashboard_view_model.dart` | `TalhaoRepository.listar` |
| `TalhaoListViewModel` | `talhao_list_view_model.dart` | `TalhaoRepository.listar` |
| `TalhaoFormViewModel` | `talhao_form_view_model.dart` | `TalhaoRepository.obter`, `TalhaoRepository.criar`, `TalhaoRepository.atualizar` |
| `TalhaoDetalheViewModel` | `talhao_detalhe_view_model.dart` | `TalhaoRepository.obter`, `TalhaoRepository.excluir`, `TalhaoRepository.baixarProntuarioPdf`, `HistoricoRepository.listarCulturas`, `HistoricoRepository.listarAnalises`, `HistoricoRepository.registrarColheita`, `ArquivoService.salvarEAbrirPdf` |
| `RegistrarCulturaViewModel` | `registrar_cultura_view_model.dart` | `CulturaRepository.catalogo`, `HistoricoRepository.registrarCultura` |
| `RegistrarAnaliseViewModel` | `registrar_analise_view_model.dart` | `HistoricoRepository.registrarAnalise` |
| `SimulacaoViewModel` | `simulacao_view_model.dart` | `TalhaoRepository.listar`, `CulturaRepository.catalogo`, `SimulacaoRepository.simular` |
| `PerfilViewModel` | `perfil_view_model.dart` | `PerfilRepository.obterUsuario`, `PerfilRepository.obterPropriedade`, `PerfilRepository.atualizarUsuario`, `PerfilRepository.atualizarPropriedade`, `AuthRepository.sair` |

### 7.5. Estados de tela

| Estado | O que a view mostra |
|---|---|
| `carregando` | `LoadingIndicator` |
| `erro` | `ErrorMessage` com o texto da ViewModel e "Tentar novamente" |
| `sucesso` sem dados | `EmptyState` com texto claro e, quando fizer sentido, botão de ação |
| `sucesso` com dados | O conteúdo da tela |

Em formulários, o erro aparece acima do botão de enviar, e os campos mantêm o que o usuário digitou.

---

## 8. Telas

Cada tela é descrita por: objetivo, o que mostra, o que o usuário pode fazer, observações e requisitos do documento `01`. O layout visual para celular ainda não foi prototipado (P15). Esta seção define o comportamento.

### SplashView (`/splash`)
- **Objetivo:** esperar a leitura da sessão salva.
- **Mostra:** logo e indicador de carregamento.
- **Ações:** nenhuma. O roteador troca de tela quando `iniciando` termina.

### LoginView (`/login`) — RF02
- **Mostra:** campos e-mail e senha (com mostrar/ocultar), botão "Entrar", links "Esqueci minha senha" e "Criar conta".
- **Erro:** mensagem da ViewModel acima do botão (por exemplo, credenciais inválidas).
- **Observações:** não navega manualmente. Ao autenticar, `autenticado` muda e o roteador leva ao Dashboard.

### CadastroView (`/cadastro`) — RF01
- **Mostra:** nome, e-mail, telefone, senha e confirmação de senha, botão "Criar conta" e link "Já tenho conta".
- **Observações:** ao concluir, mostra uma mensagem de sucesso e vai ao login (P9). Regras dos campos na seção 10.

### EsqueciSenhaView (`/esqueci-senha`) — RF03
- **Mostra:** campo de e-mail, botão "Enviar link de recuperação", link "Voltar para o login".
- **Observações:** depois do envio, mostra sempre a mesma mensagem ("Se o e-mail estiver cadastrado, enviaremos as instruções"), sem revelar se o e-mail existe. Envio real ou simulado é a pendência P13.

### DashboardView (`/dashboard`) — RF12, RF13, RF14
- **Mostra:** área total (ha), quantidade de talhões, distribuição por status (barra proporcional e legenda com a contagem de cada status), lista "Talhões que precisam de atenção" (status atenção ou risco, com os motivos) e botão "Simular rotação".
- **Ações:** tocar em um talhão leva ao detalhe. "Simular rotação" leva a `/simulacao`.
- **Vazio:** "Cadastre seu primeiro talhão", com botão para `/talhoes/novo`.
- **Observações:** somas e contagens são agregações de exibição feitas na ViewModel a partir de `TalhaoRepository.listar`. Não são regras agronômicas.

### TalhaoListView (`/talhoes`) — RF06, RF07
- **Mostra:** um cartão por talhão com nome, área, cultura atual (ou "Sem cultura registrada"), `StatusChip` e data do último laudo.
- **Ações:** botão "+ Novo talhão", tocar no cartão abre o detalhe, puxar para baixo recarrega.
- **Vazio:** mensagem com botão "Novo talhão".

### TalhaoFormView (`/talhoes/novo` e `/talhoes/:id/editar`) — RF06
- **Mostra:** campos nome e área (ha), botão "Salvar".
- **Observações:** com `id` na rota, carrega o talhão (`obter`) e funciona como edição. Ao salvar com sucesso, fecha a tela.

### TalhaoDetalheView (`/talhoes/:id`) — RF11, RF14, RF21, RF22, RF23, RF09
- **Mostra:** nome, área e cultura atual, `StatusChip` com os motivos do status, a última análise de solo (valores e a leitura da MO, se vier do servidor) e a linha do tempo (plantios, colheitas e análises, do mais recente para o mais antigo).
- **Ações:** "Registrar cultura", "Registrar análise de solo", "Registrar colheita" (aparece quando há cultura atual sem colheita) e menu com "Editar", "Exportar prontuário (PDF)" e "Excluir talhão".
- **Linha do tempo:** a ViewModel junta `listarCulturas` e `listarAnalises` em uma lista de `EventoHistorico` ordenada por data (P4).
- **Exportar PDF:** mostra progresso, recebe os bytes e abre o arquivo pelo `ArquivoService`. Erros aparecem como mensagem.
- **Excluir:** abre o `ExcluirTalhaoDialog` (veja abaixo).
- **Registrar colheita:** abre o `RegistrarColheitaDialog`.

### ExcluirTalhaoDialog — RF22, RF23
- **Mostra:** quantas safras e análises serão apagadas junto com o talhão (contadas das listas já carregadas), botão "Exportar PDF antes de excluir" e um campo para digitar o nome do talhão.
- **Regra:** o botão "Excluir" só habilita quando o texto digitado confere com o nome, ignorando maiúsculas e espaços nas pontas (`nomeConfere` na ViewModel). O servidor valida de novo.
- **Ao confirmar com sucesso:** volta para `/talhoes`.

### RegistrarColheitaDialog — RF09
- **Mostra:** seletor de data e botão "Confirmar".
- **Regra:** a data não pode ser anterior ao plantio nem futura.

### RegistrarCulturaView (`/talhoes/:id/cultura/nova`) — RF08
- **Mostra:** lista de culturas do catálogo (separadas em comerciais e de cobertura), seletor de data de plantio e botão "Salvar".
- **Observações:** o app não valida rotação. Quem avalia a sequência de culturas é o servidor, na simulação.

### RegistrarAnaliseView (`/talhoes/:id/analise/nova`) — RF10
- **Mostra:** data da análise, pH (CaCl₂), fósforo (mg/dm³), potássio (mmolc/dm³), V% e matéria orgânica opcional (g/dm³), cada um com a unidade ao lado, e botão "Salvar".
- **Observações:** o app envia os valores como digitados. O arredondamento para classificar é feito pelo servidor (documento `02`, seção 3.1).

### SimulacaoView (`/simulacao`) — RF15, RF16, RF17, RF18, RF19, RF20
- **Etapa 1:** escolher o talhão (lista com cultura atual e status).
- **Etapa 2:** escolher de 2 a 3 culturas do catálogo. Ao tentar escolher a quarta, mostra um aviso.
- **Comparar:** botão habilitado somente com talhão e de 2 a 3 culturas.
- **Resultado:** um `CenarioCard` por cultura, com a classificação (Recomendado, Aceitável, Aceitável com alerta ou Não recomendado), as mensagens de cada regra com sua fonte, e o aviso de apoio à decisão sempre visível.
- **Equivalentes:** quando o servidor indicar `equivalentes`, mostra o texto "As opções são equivalentes segundo os critérios avaliados."
- **Ações:** "Nova simulação" volta à etapa 1.
- **Observações:** as três etapas ficam na mesma tela, controladas pela ViewModel, sem rota própria para o resultado.

### PerfilView (`/perfil`) — RF04, RF05
- **Mostra:** dados pessoais (nome e telefone editáveis, e-mail somente leitura), dados da propriedade (nome e localização), botão "Salvar alterações" e botão "Sair da conta".
- **Propriedade vazia:** se o nome estiver vazio, mostra um convite para preenchê-lo (P8).
- **Sair:** abre uma confirmação ("Sair da conta?"). Ao confirmar, chama `AuthRepository.sair`, e o roteador leva ao login.

### MainShell
- **O que é:** a moldura das telas principais. Mostra a tela da aba atual e uma barra de navegação inferior com 4 destinos: Dashboard, Talhões, Simulação e Perfil.
- **Como funciona:** ao tocar em uma aba, chama `goBranch` do `go_router`, que guarda o estado de cada aba. Tocar na aba já selecionada volta ao início dela.

---

## 9. Navegação e sessão

### Rotas

| Rota | Tela | Observação |
|---|---|---|
| `/splash` | `splash_view.dart` | Pública. Só aparece enquanto a sessão é lida |
| `/login` | `login_view.dart` | Pública |
| `/cadastro` | `cadastro_view.dart` | Pública |
| `/esqueci-senha` | `esqueci_senha_view.dart` | Pública |
| `/dashboard` | `dashboard_view.dart` | Aba 1 |
| `/talhoes` | `talhao_list_view.dart` | Aba 2 |
| `/talhoes/novo` | `talhao_form_view.dart` | Dentro da aba 2. Declarar antes de `:id` |
| `/talhoes/:id` | `talhao_detalhe_view.dart` | Dentro da aba 2 |
| `/talhoes/:id/editar` | `talhao_form_view.dart` | Mesma tela, modo edição |
| `/talhoes/:id/cultura/nova` | `registrar_cultura_view.dart` | Dentro da aba 2 |
| `/talhoes/:id/analise/nova` | `registrar_analise_view.dart` | Dentro da aba 2 |
| `/simulacao` | `simulacao_view.dart` | Aba 3 |
| `/perfil` | `perfil_view.dart` | Aba 4 |

A rota `/talhoes/novo` precisa vir antes de `/talhoes/:id`, senão o roteador entende "novo" como um id.

### Regras de redirecionamento

1. Enquanto `iniciando` for verdadeiro, qualquer rota vai para `/splash`.
2. Sem sessão (`autenticado` falso), qualquer rota que não seja pública vai para `/login`.
3. Com sessão, as rotas públicas e `/splash` vão para `/dashboard`.

```dart
GoRouter criarRouter(AuthRepository auth) {
  const publicas = ['/login', '/cadastro', '/esqueci-senha'];

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final rota = state.matchedLocation;
      if (auth.iniciando) return rota == '/splash' ? null : '/splash';
      if (!auth.autenticado) return publicas.contains(rota) ? null : '/login';
      if (publicas.contains(rota) || rota == '/splash') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => ChangeNotifierProvider(
          create: (ctx) => LoginViewModel(ctx.read<AuthRepository>()),
          child: const LoginView(),
        ),
      ),
      // demais rotas públicas seguem o mesmo padrão
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => ChangeNotifierProvider(
                  create: (ctx) =>
                      DashboardViewModel(ctx.read<TalhaoRepository>())
                        ..carregar(),
                  child: const DashboardView(),
                ),
              ),
            ],
          ),
          // abas Talhões, Simulação e Perfil seguem o mesmo padrão
        ],
      ),
    ],
  );
}
```

Cada rota cria a sua ViewModel com `ChangeNotifierProvider`, entregando os repositories lidos do `provider`. É o único lugar onde ViewModels são criadas.

### Fluxo de sessão

1. O app abre e `iniciar()` lê o token salvo. Com token, `autenticado` fica verdadeiro, senão falso. Depois disso, `iniciando` fica falso.
2. No login, o `AuthRepository.entrar` guarda o token e `autenticado` vira verdadeiro. O roteador, que escuta o repository, leva ao Dashboard.
3. Se o servidor responder 401, o `ApiClient` dispara `aoNaoAutorizado`, o `AuthRepository` apaga o token e `autenticado` vira falso. O roteador leva ao login.
4. Em "Sair da conta", o `AuthRepository.sair` apaga o token e o fluxo é o mesmo do item anterior.

Esse fluxo assume token enviado no cabeçalho `Authorization` (P2).

---

## 10. Formulários e validações

As validações do app existem para ajudar o usuário a não errar a digitação. A validação definitiva é sempre do servidor. As funções ficam em `validators.dart`, e a conversão de números em `formatters.dart`.

**Números:** o produtor digita com vírgula ("5,3"). O app aceita vírgula e ponto, e envia o número ao servidor sem arredondar.

### Cadastro

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| Nome | Sim | Não vazio | "Informe seu nome." |
| E-mail | Sim | Formato de e-mail | "Informe um e-mail válido." |
| Telefone | Sim | 10 ou 11 dígitos, com DDD | "Informe um telefone com DDD." |
| Senha | Sim | Mínimo de 8 caracteres (P10) | "Use pelo menos 8 caracteres." |
| Confirmar senha | Sim | Igual à senha | "As senhas não conferem." |

### Login e recuperação de senha

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| E-mail | Sim | Formato de e-mail | "Informe um e-mail válido." |
| Senha (só no login) | Sim | Não vazia | "Informe sua senha." |

### Talhão

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| Nome | Sim | Não vazio | "Informe o nome do talhão." |
| Área (ha) | Sim | Número maior que zero | "Informe uma área maior que zero." |

### Cultura plantada

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| Cultura | Sim | Escolhida no catálogo | "Escolha uma cultura." |
| Data de plantio | Sim | Não futura | "A data não pode ser futura." |

### Colheita

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| Data de colheita | Sim | Não anterior ao plantio e não futura | "A colheita não pode ser antes do plantio." |

### Análise de solo

Os limites abaixo servem só para evitar erro de digitação. Eles não são as faixas de interpretação do documento `02`.

| Campo | Unidade | Obrigatório | Regra de plausibilidade | Mensagem |
|---|---|---|---|---|
| Data da análise | | Sim | Não futura | "A data não pode ser futura." |
| pH (CaCl₂) | | Sim | Entre 0 e 14 | "Informe um valor entre 0 e 14." |
| Fósforo (P resina) | mg/dm³ | Sim | Maior ou igual a zero | "Informe um valor maior ou igual a zero." |
| Potássio (K) | mmolc/dm³ | Sim | Maior ou igual a zero | "Informe um valor maior ou igual a zero." |
| Saturação por bases (V) | % | Sim | Entre 0 e 100 | "Informe um valor entre 0 e 100." |
| Matéria orgânica (MO) | g/dm³ | Não | Maior ou igual a zero, se preenchida | "Informe um valor maior ou igual a zero." |

### Perfil

| Campo | Obrigatório | Regra | Mensagem |
|---|---|---|---|
| Nome | Sim | Não vazio | "Informe seu nome." |
| Telefone | Sim | 10 ou 11 dígitos | "Informe um telefone com DDD." |
| E-mail | | Somente leitura (P11) | |
| Nome da propriedade | Não | Texto livre | |
| Localização | Não | Texto livre | |

### Exclusão de talhão

O campo de confirmação compara o texto digitado com o nome do talhão, ignorando maiúsculas e espaços nas pontas.

---

## 11. Tema e textos oficiais

### Cores (`app_colors.dart`)

| Nome | Valor | Uso |
|---|---|---|
| `fundo` | `#FAF7F2` | Fundo das telas |
| `painel` | `#EDE4D3` | Cartões, campos de texto e áreas de apoio |
| `verdeEscuro` | `#4A5D23` | Títulos, ícones e elementos de destaque |
| `verde` | `#6B8E23` | Botão principal e status Sem alertas |
| `ambar` | `#C6902E` | Status Atenção |
| `terracota` | `#B5533C` | Status Risco e mensagens de erro |
| `texto` | `#3A342B` | Texto principal |
| `textoSecundario` | `#7A7264` | Texto de apoio e status Sem análise |
| `borda` | `#DDD2BB` | Bordas e divisores |

### Status do solo

| Status | Cor | Texto |
|---|---|---|
| `semAlertas` | `verde` | Sem alertas |
| `atencao` | `ambar` | Atenção |
| `risco` | `terracota` | Risco |
| `semAnalise` | `textoSecundario` | Sem análise |

### Tipografia

Títulos em Fraunces e texto corrido em Inter, como no protótipo. As fontes devem ser incluídas como arquivos do projeto (no `pubspec.yaml`), para funcionar sem internet.

### Acessibilidade e usabilidade (RNF01)

- Área de toque de pelo menos 48 por 48 dp em botões e itens clicáveis.
- Texto de corpo com pelo menos 16 sp.
- O status **nunca** depende só da cor: o `StatusChip` sempre mostra o texto e um ícone.
- Poucos elementos por tela e uma ação principal por tela.

### Textos oficiais (`app_textos.dart`)

| Uso | Texto |
|---|---|
| Classificação | Recomendado |
| Classificação | Aceitável |
| Classificação com alerta | Aceitável com alerta |
| Classificação | Não recomendado |
| Aviso da simulação (RF20) | "A recomendação é um apoio à decisão e não substitui um agrônomo." |
| Cenários equivalentes (RN10) | "As opções são equivalentes segundo os critérios avaliados." |
| Ajuda do status Sem alertas | "Sem alerta nos indicadores avaliados. Não é um atestado de saúde do solo." |

As mensagens de cada regra (por exemplo, "Esta cultura foi plantada na safra anterior...") vêm do servidor, junto com a fonte técnica.

---

## 12. Testes

Os testes ficam em `test/`, com a mesma estrutura de pastas de `lib/`. O nome de cada arquivo é o do arquivo testado com o sufixo `_test.dart`.

```
test/
├── core/utils/validators_test.dart
├── core/utils/formatters_test.dart
├── config/routes_test.dart
├── data/repositories/talhao_repository_remote_test.dart
└── ui/talhoes/talhao_list_view_model_test.dart
```

(São exemplos. Cada ViewModel e cada repository remoto deve ter o seu arquivo.)

### O que testar em cada camada

| Camada | O que testar | Como |
|---|---|---|
| Validadores e formatadores | Valores válidos, inválidos e de fronteira | Teste unitário |
| Modelos | `fromJson` com campos presentes e ausentes | Teste unitário |
| Repositories remotos | Conversão de JSON e tradução de erros | `ApiClient` com `MockClient` (`package:http/testing.dart`) |
| ViewModels | Mudanças de status e dados expostos | Repository fake ou que lança `AppException` |
| Rotas | Redirecionamentos de sessão | Teste do `criarRouter` com um `AuthRepository` fake |
| Formulários | Mensagens de erro e botão habilitado ou não | Teste de widget |

### Exemplos de casos

| Teste | Dado | Quando | Então |
|---|---|---|---|
| Vírgula decimal | texto "5,3" | converter em número | resultado 5,3 |
| pH fora da faixa | texto "14,1" | validar pH | mensagem "Informe um valor entre 0 e 14." |
| Lista com sucesso | repository fake com 2 talhões | `carregar()` | status `sucesso` e 2 talhões |
| Falha de rede | repository que lança `AppException(rede)` | `carregar()` | status `erro` com a mensagem |
| Confirmação de exclusão | nome "Talhão 04" | `nomeConfere('  talhão 04 ')` | verdadeiro |
| Rota protegida | sem sessão | abrir `/dashboard` | redireciona para `/login` |
| Repository remoto | `MockClient` devolvendo JSON de 1 talhão | `listar()` | lista com 1 `Talhao` |

Regra mínima: toda ViewModel, todo repository remoto e todo validador tem pelo menos um teste antes de ser integrado.

---

## 13. Como adicionar uma funcionalidade

Siga a ordem, de baixo para cima:

1. **Modelo:** crie ou ajuste a classe em `domain/models/`, com `fromJson`.
2. **Contrato:** acrescente o método na classe abstrata do repository.
3. **Fake:** implemente o método no repository fake, com dados de exemplo.
4. **Remoto:** implemente o método no repository remoto.
5. **ViewModel:** crie a ViewModel em `ui/<funcionalidade>/`, usando `executar`.
6. **Teste:** escreva o teste da ViewModel com o fake.
7. **View:** crie a tela tratando os 4 estados e usando só widgets de `core/widgets` e cores de `AppColors`.
8. **Rota e provider:** registre a rota em `routes.dart` e crie a ViewModel ali.
9. **Documentação:** atualize as tabelas das seções 4, 6.4, 7.4, 8 e 9 deste guia e o Apêndice A.
10. **Git:** branch `feat/<numero-da-issue>-<descricao>` e commits no padrão do `CONTRIBUTING.md`.

Antes de abrir o Pull Request: `dart format .`, `flutter analyze` sem avisos e `flutter test` passando.

---

## 14. Convenções de código

- **Idioma dos nomes:** termos do domínio em português sem acento (`talhao`, `cultura`, `analiseSolo`). Termos técnicos do Flutter em inglês (`View`, `ViewModel`, `Repository`, `Service`).
- **Arquivos:** `snake_case.dart`. Uma classe principal por arquivo.
- **Classes:** `PascalCase`. Variáveis e métodos: `camelCase`. Membros privados começam com `_`.
- **Sufixos:** `_view.dart`, `_view_model.dart`, `_repository.dart`, `_repository_remote.dart`, `_repository_fake.dart`, `_service.dart`.
- **Comentários:** em português, só quando explicam o porquê.
- **Sem código morto:** não deixar código comentado nem `print` no código entregue.
- **Widgets grandes:** se o método `build` passar de cerca de 80 linhas, extrair widgets menores para a pasta `widgets/` da funcionalidade.
- **Cores e textos:** nunca escritos direto na tela. Usar `AppColors` e `AppTextos`.
- **Commits e branches:** seguem o `CONTRIBUTING.md`. Escopos por área: `auth`, `perfil`, `talhao`, `cultura`, `solo`, `simulacao`, `dashboard` e `pdf`. Para a infraestrutura do app (tema, rotas, injeção) propõe-se o escopo `app` (P14).

---

## 15. Pendências

Esta tabela lista tudo que o guia assume sem confirmação. Quando uma pendência for resolvida, atualize o guia e remova a linha.

| ID | Pendência | Quem decide | Padrão assumido neste guia |
|---|---|---|---|
| P1 | Contrato da API: caminhos, formato do JSON e nomes dos campos | Backend e professor | Caminhos e campos ilustrativos, isolados nos repositories remotos e nos `fromJson` |
| P2 | Forma de autenticação | Backend e professor | Token enviado no cabeçalho `Authorization` |
| P3 | Formato do corpo de erro da API | Backend | Status HTTP padrão com mensagem de texto |
| P4 | Quem monta a linha do tempo | Backend | O app junta culturas e análises |
| P5 | PDF: como o app abre ou compartilha o arquivo | Grupo | O servidor gera o PDF, o `ArquivoService` abre. Pacote a definir |
| P6 | Plataforma alvo da demonstração | Professor | Android. iOS opcional |
| P7 | Status de um talhão sem laudo. Não definido no `01` (RF07, RF13) nem no `02` (seção 4.6) | Grupo | Exibido como "Sem análise", fora da contagem de "Sem alertas" |
| P8 | Quando a propriedade é criada | Grupo e backend | Criada no cadastro com nome vazio e preenchida no Perfil |
| P9 | O que acontece depois do cadastro | Grupo | Vai para o login |
| P10 | Política de senha | Grupo | Mínimo de 8 caracteres |
| P11 | E-mail editável no Perfil | Grupo | Somente leitura |
| P12 | Quem escreve a leitura de textura da MO | Backend | O servidor envia o texto em `leituraMo` |
| P13 | Recuperação de senha com envio real de e-mail ou simulada (ponto aberto do `01`) | Grupo | Telas prontas. O fake simula o envio |
| P14 | Escopo `app` no `CONTRIBUTING.md` | Grupo | Propor a inclusão |
| P15 | Layout mobile no Figma | Grupo | O protótipo atual é web. Este guia define comportamento, não aparência |

---

## 16. Glossário

| Termo | Significado |
|---|---|
| Widget | Peça de interface do Flutter. Tudo na tela é um widget |
| View | A tela, escrita como widget. Só exibe e captura entrada |
| ViewModel | Guarda o estado de uma tela e executa as ações dela |
| Repository | Classe que entrega os dados do app às ViewModels, escondendo de onde vêm |
| Service | Classe que conversa com algo externo: servidor, armazenamento ou arquivos |
| Modelo de domínio | Classe que só guarda dados, como `Talhao` |
| Injeção de dependência | Receber de fora os objetos de que uma classe precisa, em vez de ela os criar |
| Provider | Pacote que distribui objetos pela árvore de widgets e avisa as telas quando mudam |
| ChangeNotifier | Classe do Flutter que avisa quem a observa quando seus dados mudam |
| Fake | Versão de mentira de uma classe, com dados de exemplo, usada em testes e demonstrações |
| Rota | Endereço de uma tela dentro do app, como `/talhoes/12` |
| Shell | Moldura fixa (a barra de abas) que envolve as telas principais |
| Token | Código que o servidor entrega no login e que prova quem é o usuário nas chamadas seguintes |
| Status do solo | Resultado da triagem do laudo: Sem alertas, Atenção ou Risco |
| Cenário | Cada cultura candidata comparada na simulação |

---

## Apêndice A — Cobertura dos requisitos

Cada requisito funcional do documento `01` e a tela que o atende.

| Requisito | Descrição resumida | Tela ou arquivo |
|---|---|---|
| RF01 | Criar conta | `cadastro_view.dart` |
| RF02 | Entrar | `login_view.dart` |
| RF03 | Recuperar senha | `esqueci_senha_view.dart` |
| RF04 | Sair da conta | `perfil_view.dart` |
| RF05 | Ver e editar perfil e propriedade | `perfil_view.dart` |
| RF06 | Cadastrar, editar, listar e excluir talhões | `talhao_form_view.dart`, `talhao_list_view.dart`, `excluir_talhao_dialog.dart` |
| RF07 | Lista de talhões com status | `talhao_list_view.dart` |
| RF08 | Registrar cultura plantada | `registrar_cultura_view.dart` |
| RF09 | Registrar colheita | `registrar_colheita_dialog.dart` |
| RF10 | Registrar análise de solo | `registrar_analise_view.dart` |
| RF11 | Linha do tempo do talhão | `talhao_detalhe_view.dart` |
| RF12 | Área total e quantidade de talhões | `dashboard_view.dart` |
| RF13 | Distribuição por status | `dashboard_view.dart` |
| RF14 | Talhões em atenção, com motivo | `dashboard_view.dart` |
| RF15 | Escolher talhão para simular | `simulacao_view.dart` |
| RF16 | Escolher de 2 a 3 culturas | `simulacao_view.dart` |
| RF17 | Comparação lado a lado | `cenario_card.dart` |
| RF18 | Classificação de cada cenário | `cenario_card.dart` |
| RF19 | Regra e fonte na justificativa | `cenario_card.dart` |
| RF20 | Aviso de apoio à decisão | `simulacao_view.dart` |
| RF21 | Exportar prontuário em PDF | `talhao_detalhe_view.dart` |
| RF22 | Aviso do que será apagado na exclusão | `excluir_talhao_dialog.dart` |
| RF23 | Confirmar a exclusão digitando o nome | `excluir_talhao_dialog.dart` |

---

## Referências

- Flutter. *Guide to app architecture*. https://docs.flutter.dev/app-architecture/guide
- Flutter. *Architecture recommendations and resources*. https://docs.flutter.dev/app-architecture/recommendations
- Flutter. *Architecture case study*. https://docs.flutter.dev/app-architecture/case-study

**Aviso sobre os exemplos de código:** os trechos em Dart deste guia são ilustrativos. A sintaxe foi checada com um analisador Dart, mas eles não foram compilados nem executados, porque o ambiente de elaboração não tinha o SDK do Flutter. Antes de copiar, confirme as versões dos pacotes e rode `flutter analyze`.