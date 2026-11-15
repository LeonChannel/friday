# Guia de testes

Código implementado não é funcionalidade entregue. Uma fase do Friday só está pronta quando existe evidência de que o resultado esperado acontece: teste automatizado onde dá, e verificação no app rodando onde o teste não alcança.

## Ferramentas

- **Swift Testing** (`import Testing`, `@Test`, `#expect`) para tudo que é teste novo. XCTest só se uma API exigir.
- Testes ficam no pacote `FridayKit`, um alvo de teste por módulo (`FridayDomainTests`, `FridayInfrastructureTests`, `FridayFeaturesTests`). Rodam com `swift test`, sem abrir o app.
- O target do app quase não tem lógica, então quase não tem teste.

## Níveis

| Nível | O que cobre | Regras |
|---|---|---|
| **Unitário** | Domain e Models: regras, projeções, transições de estado | rápido, sem disco, sem rede, sem processo. É onde fica a maior parte dos testes |
| **Integração** | Infrastructure contra o recurso real: banco GRDB em memória, PTY com `/bin/echo`, socket num diretório temporário, FSEvents numa pasta temporária, `git` num repo criado no teste | cada teste cria e apaga o próprio ambiente; marcado com `@Tag(.integration)` |
| **Fluxo** | uma funcionalidade de ponta a ponta sem interface: evento de hook entra pelo socket → é gravado → a projeção muda | prova que as peças se ligam |
| **Visual** | `#Preview` de cada view com fixtures, em claro e escuro; verificação no app rodando ao fim de cada fase | o app abre com `open -g`, sem roubar foco; captura da janela por `screencapture -l` |

Teste de interface automatizado (XCUITest) só para um fluxo crítico que os níveis acima não provem, porque é lento e frágil.

## Regras

- **Teste não toca o mundo real do usuário.** Nada de `~/.claude`, `~/Library/Application Support/Friday`, rede ou repositórios de verdade. Tudo em diretório temporário criado pelo teste.
- **Agente de IA real não roda em teste automatizado.** Eventos de hook são reproduzidos a partir de payloads gravados em `Fixtures/` (capturados de uma sessão real, com identificadores trocados por valores fictícios).
- **Um bug corrigido ganha um teste de regressão** que falha sem a correção. Confira que ele falha antes de corrigir.
- **Tempo nunca é `sleep`.** Esperas usam o evento que se espera (`AsyncStream`, `confirmation`) com limite de tempo, para o teste não ficar instável.
- **Nome do teste diz o comportamento**, em inglês curto: `rejectsDuplicateAndNonDirectory`, não `test1`.
- **Fixture pequena e legível.** Se o dado de teste não cabe numa tela, o teste está provando coisa demais.

## O que provar em cada fase

| Fase | Evidência mínima |
|---|---|
| Projetos | unitário do cadastro (adicionar, duplicado, inválido, remover) |
| Terminal | integração: processo inicia na pasta certa, saída chega, encerrar mata o processo; no app: `claude` abre dentro do Friday |
| Sensor (hooks) | integração do socket; fluxo com payloads gravados do Claude; no app: um evento real de uma sessão aparece gravado |
| Pastas e git | integração com pasta e repo temporários: mudança de arquivo vira evento, `git status` refletido |
| Linha do tempo e esteira | unitário das projeções a partir de uma sequência de eventos fixa; no app: uma sessão real vira linha do tempo |
| Backlog | unitário da hierarquia, dos tetos, do código e das projeções (colunas, árvore, duplicata); integração do repositório (número por projeto, pai na transação) e do espelho numa pasta temporária; CLI com banco em memória e o hook; no app: um bug anotado pelo Claude aparece em "Novo" no quadro |
| Jornadas | unitário da limpeza da jornada, do briefing (texto exato), do avanço das etapas e da vez; integração do catálogo de skills numa `.claude` temporária e das etapas no banco (incluindo assunto antigo sem etapas); CLI `friday etapa`; persistência nos Ajustes; no app: escolher o tipo, começar e ver a etapa mudar na lousa quando o Claude roda `friday etapa` |
| Memória | unitário do formato da nota, da ordem e do teto do contexto; integração do vault numa pasta temporária e do hook pela CLI com eventos gravados; no app: uma sessão real do Claude recebe o contexto de início |

## Antes de considerar uma fase pronta

1. `swift test` no `FridayKit` verde.
2. `xcodebuild ... test` do app verde (garante que o app compila com o pacote).
3. Prévias revisadas em claro e escuro.
4. App aberto e o fluxo da fase executado de verdade, com o resultado registrado no PR.
5. CI verde.
