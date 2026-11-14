# Friday

App macOS nativo (Swift 6, SwiftUI, macOS 26+). Visão e decisões do produto ficam no vault pessoal, fora deste repo; este arquivo guarda só as regras de engenharia.

## Guias obrigatórios

Leia o guia da área antes de mexer nela. Eles valem como regra, não como sugestão.

- [`docs/VISUAL.md`](docs/VISUAL.md): toda interface. Identidade própria, cores de vez (você/Claude), grau da evidência, mapa, tipografia Geist, acessibilidade.
- [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md): camadas, fluxo de dados, concorrência, persistência, processos e agentes.
- [`docs/TESTES.md`](docs/TESTES.md): níveis de teste, regras e a evidência mínima de cada fase.
- [`docs/VOCABULARIO.md`](docs/VOCABULARIO.md): cabeçalho obrigatório de cada arquivo (`// Resumo:` e `// Tags:`) e a lista fechada de tags.

Para achar código: comece pelo [`docs/MAPA.md`](docs/MAPA.md), o índice por tag gerado dos cabeçalhos. Mudou ou criou arquivo? Atualize o cabeçalho e rode `swift scripts/mapa.swift`; o CI recusa mapa desatualizado.

Mudou uma decisão de qualquer uma dessas áreas? O guia muda no mesmo PR.

## Projeto

- O `Friday.xcodeproj` é gerado: edite `project.yml` e rode `xcodegen generate`. Nunca edite o `.xcodeproj` à mão.
- Dependências externas no `Package.swift` do `FridayKit`; o `project.yml` só aponta para o pacote local.

## Verificar

```sh
swift scripts/mapa.swift --check
(cd Packages/FridayKit && swift test)
xcodegen generate && xcodebuild -project Friday.xcodeproj -scheme Friday -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation build
```

O código e os testes moram no pacote `Packages/FridayKit` (Domain, Infrastructure, Features). O target do app só compõe as dependências.

Para ver o app rodando, abra com `open -g` (sem trazer a janela para frente). Nunca roube o foco do usuário.

## Regras

- Repo público: nenhum segredo, caminho pessoal, dado de trabalho ou de cliente no código, em teste ou em commit.
- O Friday nunca altera a configuração global dos agentes (`~/.claude/settings.json`, `~/.codex/`). Configuração por sessão vai por flag (`claude --settings`).
- Economia de cota é requisito: prefira dado que o agente já produz (hooks, arquivos) a pedir texto ao modelo.
- Concorrência estrita do Swift 6 ligada. Não desligue avisos para compilar.
- Todo arquivo tem o cabeçalho de resumo e tags; todo tipo e função pública tem `///` com resumo funcional em português. Fora isso, comentário só quando o porquê não é óbvio, em uma linha.
- Nomes de arquivo pelo conceito que contêm (`ProjectStore.swift`), nunca `Utils`/`Helpers`.
- Texto da interface em português.
