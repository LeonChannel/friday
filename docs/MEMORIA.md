# Guia da memória (o vault)

O Friday mantém a memória do Claude numa pasta de markdown escolhida pelo dev, o **vault**. A memória é organizada em três camadas e uma área de trabalho por assunto, e chega ao agente sozinha, por sessão, sem tocar na configuração global dele. Este guia define o formato, o que entra, como chega e o que nunca entra.

## Princípios

1. **O vault é o mapa; a verdade é o código e o git.** Toda nota lida é hipótese até ser conferida no código da sessão. Nota que divergiu do código está errada e é corrigida na hora.
2. **Carrega o resumo, não a nota.** Cada nota tem um `resumo` curto (até 300 caracteres) que é o que entra no contexto. O corpo é derivação, para humano, e só é lido sob demanda (`friday memoria ler`).
3. **Chega sozinha, na hora certa.** O começo da sessão recebe as regras de conduta e o índice; a nota ancorada num arquivo chega quando o arquivo é aberto. Ninguém precisa lembrar de consultar.
4. **Custo medido.** O contexto de início tem teto e a tela de Memória mostra exatamente o que a sessão recebe, com o tamanho. Economia de cota é requisito, não detalhe.
5. **O vault é do dev.** A pasta é legível fora do app (Obsidian, editor, `git`). O Friday lê e escreve arquivos; não guarda nota no banco.

## As três camadas

| Camada | Pasta | Responde | Chega |
|---|---|---|---|
| **Abstração** | `Abstracao/` | como o Claude fala e se porta: idioma, tom, nível de certeza, quando parar e perguntar | inteira, no começo de toda sessão |
| **Processual** | `Processual/` | como o trabalho se organiza no Friday: assunto, vez, área de trabalho, registro, destilação, uso das ferramentas | as marcadas `sempre: true` inteiras; o resto como índice |
| **Projeto** | `Projetos/<projeto>/` | regras, padrões, armadilhas, decisões, tecnologias, repositórios e mapa de arquivos de um projeto | o hub do projeto inteiro, o resto como índice; nota ancorada ao abrir o arquivo |

Regra de desempate ao gravar:

1. Fala de **como o Claude se comunica ou se comporta**, em qualquer projeto? → Abstração.
2. Fala de **como o trabalho anda** (fluxo, ferramenta, ritual), em qualquer projeto? → Processual.
3. Fala de **um sistema** (regra, padrão, armadilha, decisão, tecnologia, repositório)? → Projeto.
4. É **estado de uma tarefa em andamento**? → área de trabalho do assunto, nunca nota.

## Estrutura no disco

```
<vault>/
├── 00 - Friday.md                 ← hub: o que é cada camada (criado pelo Friday)
├── Abstracao/                     ← Comunicacao.md, Conduta.md
├── Processual/                    ← Fluxo.md, Area de trabalho.md, ...
└── Projetos/<projeto>/
    ├── 00 - <Projeto>.md          ← hub: tecnologias, repositórios, mapa
    ├── Regras/  Padroes/  Armadilhas/  Decisoes/  Tecnologias/  Repos/
    ├── Backlog/                   ← espelho do backlog, gerado pelo Friday (não é nota)
    │   ├── 00 - Backlog.md
    │   └── FRI-12.md
    └── Trabalho/assunto-<id>/     ← área de trabalho (ver abaixo)
        ├── estado.md
        └── cache/                 ← nunca lido pelo Friday
```

- `<projeto>` é o nome do projeto no Friday em ASCII, sem acento, com `-` no lugar do que não for letra, número, espaço ou `-` (`Lousa de Refinamento` → `Lousa de Refinamento`, `Ação/API` → `Acao-API`).
- Nome de arquivo em ASCII sem acento, pelo mesmo motivo do vault EVUP: vira link, precisa ser digitável e estável. Acento é livre no título e no corpo.
- `Backlog/` é do Friday: regravada a cada escrita no backlog, nunca lida como memória. Edite pelo app ou por `friday item`.
- O Friday cria a estrutura e as notas iniciais na primeira vez (Ajustes → Memória, ou a tela de Memória). Nunca sobrescreve nota que já existe.

## Formato da nota

```markdown
---
tipo: regra
resumo: "Toda escrita no banco passa pelo repositório; a view nunca grava. Quebrar isso faz a tela divergir do banco."
ancoras: [Packages/FridayKit/Sources/FridayInfrastructure/Subjects/, Friday/App/FridayApp.swift]
sempre: false
verificado_em: 2026-11-14
---

# Escrita só pelo repositório

Derivação: por que é assim, como se provou, exemplos. Não entra no contexto.
```

| Campo | Obrigatório | Regra |
|---|---|---|
| `tipo` | sim | lista fechada por camada (abaixo). Valor fora dela é erro |
| `resumo` | sim | até 300 caracteres. O fato e a consequência, falseáveis. É o que o Claude lê |
| `ancoras` | não, só projeto | caminhos relativos à pasta do projeto. Pasta termina em `/` e vale para tudo dentro dela |
| `sempre` | não | `true` faz a nota entrar inteira no começo da sessão. Padrão: `true` na abstração, `false` no resto |
| `verificado_em` | não | data em que alguém **conferiu no código**, não a data da escrita |

Título: o primeiro `# ` do corpo; sem ele, o nome do arquivo.

| Camada | Tipos |
|---|---|
| Abstração | `comunicacao` · `conduta` |
| Processual | `fluxo` · `ferramenta` |
| Projeto | `projeto` (o hub) · `regra` · `padrao` · `armadilha` · `decisao` · `tecnologia` · `repo` · `mapa` |

## Como chega ao agente

Tudo por sessão, pelo plugin que o Friday já entrega com `--plugin-dir`. Nada em `~/.claude`.

- O Friday exporta `FRIDAY_VAULT` (a pasta do vault) para toda sessão aberta nele. Sem vault escolhido, a memória fica calada.
- **Início da sessão** (hook `SessionStart`, também depois de `/compact` e `/clear`): `friday memoria hook` monta o contexto nesta ordem, até o teto de **12.000 caracteres** (~3 mil tokens):
  1. abstração, inteira;
  2. área de trabalho do assunto da sessão (`FRIDAY_ASSUNTO`), quando houver;
  3. processual `sempre: true`, inteira;
  4. hub do projeto, inteiro;
  5. índice do resto: `- [tipo] Título — resumo (caminho)`.
  Cada nota inteira tem teto de 2.000 caracteres; acima disso entra cortada com o caminho para ler o resto. O que passa do teto total vira uma linha: `+N notas fora do teto: friday memoria listar`.
- **Ao abrir um arquivo** (hook `PreToolUse` de `Read`, `Edit`, `MultiEdit` e `Write`): as notas do projeto ancoradas naquele arquivo chegam como resumo, no máximo 5 por arquivo, uma vez por sessão (o registro de entregues mora numa pasta temporária e zera no início da sessão).
- O projeto da sessão é o projeto do Friday cuja pasta contém o `cwd` (o mais específico ganha).
- O hook nunca falha nem atrasa o agente: erro vira silêncio, sempre sai 0.

## Área de trabalho

A área protege o **entendimento** de uma tarefa em andamento. No Friday ela é presa ao **assunto**, e o assunto já guarda a maior parte do que no vault EVUP ficava em arquivo:

| No vault EVUP (`Trabalho/<ID>/`) | No Friday |
|---|---|
| `fatos.md` | evidências do assunto (com grau) |
| `decisoes.md` | decisões do assunto |
| `estado.md` | `Trabalho/assunto-<id>/estado.md`: fase e próximo passo |
| `cache/` | `Trabalho/assunto-<id>/cache/` |

`estado.md` guarda no cabeçalho quando foi escrito (`atualizado_em`) e o commit do projeto naquele momento (`head`). Ao retomar:

| Conteúdo | Com qualquer idade |
|---|---|
| decisões do assunto | entram como estão; decisão vale até alguém mudar |
| evidências `medido` e `no código` | se o `head` mudou desde o estado, viram **pista**: confira antes de usar |
| `estado.md` | sugestão de próximo passo, nunca instrução |

Comandos: `friday memoria area <assunto>` lê; `--estado "<texto>"` grava (até 1.200 caracteres); `--fechar` apaga a área depois de destilada.

## Destilação

No fim do assunto, o que sobrevive a ele vira nota de projeto e a área é fechada. Estado e cache morrem; decisão com consequência ativa, regra descoberta e armadilha que custou tempo sobem.

- Pela tela de Memória: cada decisão do assunto tem **Promover**, que grava uma nota `decisao` em `Decisoes/` com o porquê e a origem.
- Pela CLI: `friday memoria promover <assunto> --decisao <n>` faz o mesmo; `friday memoria nota` grava qualquer nota nova.
- Teste para promover: *isso pouparia tempo de alguém daqui a três meses?* Se não, não sobe.

## O que nunca entra

- Segredo com valor (token, senha, chave). Cite onde o segredo mora, nunca o valor.
- Narrativa da sessão ("tentei X, depois Y"). Sobra a regra, não a história.
- O que o código, o `git log` ou o `CLAUDE.md` do repo já dizem.
- Estado de tarefa em nota de projeto: vai na área de trabalho.
- Opinião sobre pessoa. Conhecimento é sobre o sistema.

## CLI

```
friday memoria hook                      # usado pelos hooks; lê o JSON do evento na entrada
friday memoria contexto [--assunto <id>] # o que a sessão recebe no início, com o tamanho
friday memoria listar [--camada abstracao|processual|projeto]
friday memoria ler <caminho relativo ao vault>
friday memoria nota "<título>" --camada <c> --tipo <t> --resumo "..." [--ancora <caminho>]... [--corpo "..."] [--sempre]
friday memoria area <assunto> [--estado "..."] [--fechar]
friday memoria promover <assunto> --decisao <n>
```

O projeto vem da pasta atual; o vault, de `FRIDAY_VAULT` ou da preferência do app.

## Quando mudar este guia

Camada nova, tipo novo, campo novo ou mudança no que chega ao agente entram aqui no mesmo PR, com o porquê em uma linha.
