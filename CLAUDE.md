# Friday

App macOS nativo (Swift 6, SwiftUI, macOS 26+). Visão e decisões do produto ficam no vault pessoal, fora deste repo; este arquivo guarda só as regras de engenharia.

## Projeto

- O `Friday.xcodeproj` é gerado: edite `project.yml` e rode `xcodegen generate`. Nunca edite o `.xcodeproj` à mão.
- Dependências por Swift Package Manager, declaradas no `project.yml`.
- Banco local: SQLite via GRDB, em `~/Library/Application Support/Friday/`. Toda mudança de schema é uma migração nova no `DatabaseMigrator`; migração existente não muda.

## Verificar

```sh
xcodegen generate && xcodebuild -project Friday.xcodeproj -scheme Friday -destination 'platform=macOS' -derivedDataPath build -skipPackagePluginValidation test
```

- Testes com Swift Testing (`import Testing`), um arquivo por tipo testado em `FridayTests/`.
- Para ver o app rodando, abra com `open -g` (sem trazer a janela para frente). Nunca roube o foco do usuário.

## Regras

- Repo público: nenhum segredo, caminho pessoal, dado de trabalho ou de cliente no código, em teste ou em commit.
- O Friday nunca altera a configuração global dos agentes (`~/.claude/settings.json`, `~/.codex/`). Configuração por sessão vai por flag (`claude --settings`).
- Economia de cota é requisito: prefira dado que o agente já produz (hooks, arquivos) a pedir texto ao modelo.
- Concorrência estrita do Swift 6 ligada. Não desligue avisos para compilar.
- Comentário só quando o porquê não é óbvio, em uma linha.
- Nomes de arquivo pelo conceito que contêm (`ProjectStore.swift`), nunca `Utils`/`Helpers`.
- Texto da interface em português.
