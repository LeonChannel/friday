# Friday

App macOS nativo (Swift 6, SwiftUI, macOS 26+). Visão e decisões do produto ficam no vault pessoal, fora deste repo; este arquivo guarda só as regras de engenharia.

## Guias obrigatórios

Leia o guia da área antes de mexer nela. Eles valem como regra, não como sugestão.

- [`docs/VISUAL.md`](docs/VISUAL.md): toda interface. Componentes do sistema, Liquid Glass, cor semântica, estilos de texto, SF Symbols, acessibilidade.
- [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md): camadas, fluxo de dados, concorrência, persistência, processos e agentes.
- [`docs/TESTES.md`](docs/TESTES.md): níveis de teste, regras e a evidência mínima de cada fase.

Mudou uma decisão de qualquer uma dessas áreas? O guia muda no mesmo PR.

## Projeto

- O `Friday.xcodeproj` é gerado: edite `project.yml` e rode `xcodegen generate`. Nunca edite o `.xcodeproj` à mão.
- Dependências por Swift Package Manager, declaradas no `project.yml`.

## Verificar

```sh
xcodegen generate && xcodebuild -project Friday.xcodeproj -scheme Friday -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation test
```

Para ver o app rodando, abra com `open -g` (sem trazer a janela para frente). Nunca roube o foco do usuário.

## Regras

- Repo público: nenhum segredo, caminho pessoal, dado de trabalho ou de cliente no código, em teste ou em commit.
- O Friday nunca altera a configuração global dos agentes (`~/.claude/settings.json`, `~/.codex/`). Configuração por sessão vai por flag (`claude --settings`).
- Economia de cota é requisito: prefira dado que o agente já produz (hooks, arquivos) a pedir texto ao modelo.
- Concorrência estrita do Swift 6 ligada. Não desligue avisos para compilar.
- Comentário só quando o porquê não é óbvio, em uma linha.
- Nomes de arquivo pelo conceito que contêm (`ProjectStore.swift`), nunca `Utils`/`Helpers`.
- Texto da interface em português.
