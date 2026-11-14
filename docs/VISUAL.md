# Guia visual

O Friday é um app de Mac e deve parecer um app da Apple: Xcode, Finder, Notas, Ajustes do Sistema. A referência é o [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) para macOS, na linguagem visual do macOS 26 (Liquid Glass). Quando este guia não cobrir um caso, vale o HIG; quando o HIG não cobrir, copie o que um app da Apple faz no mesmo caso.

A regra de ouro é **usar o sistema em vez de imitá-lo**. Componente nativo, cor semântica, estilo de texto e SF Symbol ganham de qualquer coisa desenhada à mão, porque se adaptam sozinhos a modo claro e escuro, contraste, acessibilidade e às próximas versões do macOS.

## Estrutura da janela

- A janela principal é um `NavigationSplitView`: **barra lateral** (navegação), **conteúdo** e, quando houver detalhe contextual, um **inspetor** à direita com `.inspector(isPresented:)`. Não invente painéis laterais próprios.
- A barra lateral usa `List` com `.listStyle(.sidebar)` e seções com título (`Section("Assuntos")`). Item de barra lateral é `Label` com SF Symbol, nunca ícone solto.
- A toolbar é a do sistema (`.toolbar`), com itens agrupados por função. Use `ToolbarSpacer` para separar grupos, não `Spacer()` dentro de `HStack`.
- O conteúdo se estende por baixo da barra lateral e da toolbar quando faz sentido (`.backgroundExtensionEffect()` em imagem ou canvas de fundo).
- Estado vazio é sempre `ContentUnavailableView`, com SF Symbol, título curto e uma frase que diz o próximo passo.
- Preferências moram numa cena `Settings`, aberta por ⌘,. Nunca numa folha ou janela improvisada.
- Comandos do app ficam no menu (`.commands`) com atalho de teclado. Se uma ação tem botão, ela também tem item de menu.

## Liquid Glass

O vidro é a camada de **controles e navegação**, que flutua sobre o conteúdo. O conteúdo em si (texto, canvas, terminal, listas) nunca é de vidro.

- Toolbar, barra lateral e folhas já recebem o vidro do sistema. Não adicione fundo próprio a elas.
- Controle flutuante sobre o conteúdo (barra de ferramentas do canvas, controles de zoom) usa `.glassEffect()`. Vários vizinhos ficam dentro de um `GlassEffectContainer`, para o sistema fundir as formas.
- Botões: `.buttonStyle(.glass)` para ação comum sobre vidro e `.buttonStyle(.glassProminent)` só para a ação principal da tela. No máximo **uma** ação proeminente visível por vez.
- Não empilhe vidro sobre vidro, e não use vidro como decoração.
- Respeite "Reduzir transparência" e "Aumentar contraste": usando os componentes do sistema, isso vem de graça. Efeito próprio precisa testar os dois.

## Cor

- Só cores semânticas: `.primary`, `.secondary`, `.tertiary`, `Color.accentColor`, `.background`, `Color(nsColor: .controlBackgroundColor)`, `.separator`. Nada de valor hexadecimal na view.
- Cor de status vem de um único lugar (`StatusStyle`) e usa cor do sistema: `.green` concluído, `.orange` precisa de você, `.red` erro, `.blue` em andamento, `.secondary` parado.
- Cor nunca é a única pista: todo status tem também ícone ou texto, por acessibilidade.
- A cor de destaque é a escolhida pelo usuário no sistema. O Friday não define cor de marca própria nos controles.

## Tipografia

- Só estilos de texto do sistema: `.largeTitle`, `.title`, `.title2`, `.title3`, `.headline`, `.body`, `.callout`, `.subheadline`, `.footnote`, `.caption`. Nunca `.font(.system(size:))` com número.
- Peso só para hierarquia: `.bold()` em títulos, `.headline` para rótulo de seção. No máximo três níveis de hierarquia por tela.
- Código, caminho de arquivo e saída de terminal: `.monospaced()`.
- Texto que o usuário pode querer copiar (caminho, ID, comando) tem `.textSelection(.enabled)`.

## Espaçamento e forma

- Use o padrão do sistema primeiro: `padding()` sem número, `Form` com `.formStyle(.grouped)`, `LabeledContent` para pares rótulo/valor.
- Quando precisar de número, use a escala de 4 pontos: 4, 8, 12, 16, 20, 24, 32. Esses valores ficam num tipo `Spacing`, não espalhados.
- Cantos arredondados seguem o contêiner: `RoundedRectangle(cornerRadius:style: .continuous)` com o raio do contêiner pai, para os cantos ficarem concêntricos.

## Ícones

- Só SF Symbols. Prefira a variante que o sistema usa no mesmo papel (`folder`, `arrow.triangle.branch`, `terminal`, `sparkles` para IA).
- Estado em ícone usa `.symbolVariant` e `.symbolRenderingMode(.hierarchical)`, não troca de imagem.
- Animação de símbolo (`.symbolEffect`) só para comunicar mudança de estado (agente começou ou terminou), nunca em loop decorativo.

## Movimento

- Transições com as animações padrão do SwiftUI (`.smooth`, `.snappy`). Sem durações inventadas.
- Respeite "Reduzir movimento" (`@Environment(\.accessibilityReduceMotion)`): troque movimento por fade.
- Nada pisca, pulsa ou se move sem o usuário ter um motivo para olhar. **Atenção do usuário é recurso escasso**, e este é o princípio central do Friday.

## Comunicação na interface

- Português, frase curta, conclusão primeiro.
- Título de botão é verbo no infinitivo ("Adicionar projeto"), não substantivo.
- Erro diz o que aconteceu e o que fazer, sem jargão: "Essa pasta já está na lista." em vez de "Unique constraint failed".
- Confirmação só para ação destrutiva e irreversível, com o botão destrutivo marcado com `role: .destructive`.

## Acessibilidade

- Todo controle sem texto visível tem `.accessibilityLabel`.
- Navegação completa por teclado: foco visível, Tab entre áreas, atalhos para as ações frequentes.
- Teste com VoiceOver as telas novas antes de considerar uma fase concluída.
- Contraste: confira no modo claro, no escuro e com "Aumentar contraste".

## Prévias

Toda view nova tem `#Preview` com dados de exemplo (fixtures), em modo claro e escuro. A prévia é a primeira revisão visual, antes de abrir o app.
