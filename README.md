# Friday

Workspace visual de desenvolvimento para macOS, onde o desenvolvedor e o agente de IA (Claude Code) raciocinam e trabalham juntos. Projeto pessoal, em construção.

## Requisitos

- macOS 26 ou mais novo
- Xcode 26 ou mais novo
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Rodar

```sh
(cd Packages/FridayKit && swift test)
xcodegen generate
xcodebuild -project Friday.xcodeproj -scheme Friday -destination 'platform=macOS' \
  -derivedDataPath build -skipPackagePluginValidation build
open build/Build/Products/Debug/Friday.app
```

O `.xcodeproj` é gerado a partir do `project.yml` e não vai para o git. O código fica no pacote local `Packages/FridayKit`.

## Licença

MIT.
