# Guia visual

O Friday é uma bancada de trabalho: o lugar onde o dev e o agente montam juntos o entendimento de um problema. A interface tem identidade própria, pensada para quem passa o dia ao lado do editor, e não imita Notas nem Finder. A janela continua sendo de Mac (menus, atalhos, folhas, Ajustes), mas a área de trabalho é nossa.

Duas ideias organizam tudo o que vem abaixo:

1. **A cor diz de quem é a vez.** Limão é você, coral é o Claude, ausência de cor é parado. Não existe outra cor de destaque.
2. **O assunto é um espaço, não um texto.** A superfície principal é o mapa; o resto (resumo, dossiê, trilhas) gira em volta dele.

Quando este guia não cobrir um caso, vale o [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) para comportamento (teclado, menus, acessibilidade) e este guia para aparência.

## Estrutura da janela

- A janela é uma `NavigationSplitView` com duas colunas: **lateral** à esquerda e **área de trabalho** à direita. Os botões de fechar, minimizar e zoom são os do sistema.
- A **lateral** tem a marca, as entradas fixas (Mesa, Sua vez), os assuntos, os projetos e, no rodapé, a legenda das três vezes. Cada assunto é um ponto da cor da vez seguido do nome. Nada de ícone por assunto.
- A **barra superior** é a toolbar do sistema com conteúdo e fundo do tema: o caminho (`projeto / assunto`) à esquerda, a troca de visão (Mapa, Dossiê) no centro e o indicador de vez à direita.
- Um assunto aberto tem três regiões fixas:
  - **Onde você parou**: coluna à esquerda do mapa com as cinco linhas (Objetivo, Confirmado, Em aberto, Sua vez, Depois). Pode ser recolhida.
  - **Mapa**: a superfície principal, ocupando o resto.
  - **Trilhas**: faixa embaixo, uma linha por frente; o terminal abre como gaveta dela.
- **Mesa** (tela inicial): a pergunta "O que está te incomodando?" no topo, como barra de comando, e os assuntos em três colunas por vez: Sua vez, Com o Claude, Parados.
- **Sua vez**: fila de triagem. Lista curta à esquerda, decisão em foco à direita.
- Estado vazio é sempre uma frase curta que diz o próximo passo, com borda tracejada ou centralizado na área. Nunca uma tela em branco.
- Preferências moram na cena `Settings` (⌘,). Comandos do app ficam no menu (`.commands`) com atalho; se uma ação tem botão, ela também tem item de menu.

## Cor

Toda cor vem de um único tipo, `Theme`, com uma entrada no catálogo de cores (variante escura e clara) por token. View nunca tem valor hexadecimal. O escuro é o tema de referência: desenhe nele primeiro e confira o claro depois.

| Token | Escuro | Claro | Uso |
|---|---|---|---|
| `fundo` | `#0E0F11` | `#EEF0F2` | fundo da janela e do mapa |
| `superficie` | `#15171A` | `#FFFFFF` | lateral, barra, coluna de retorno, peças |
| `superficieElevada` | `#1C1F23` | `#F6F7F8` | notas, campos, controle segmentado |
| `superficieAtiva` | `#262A30` | `#E3E6EA` | item selecionado, trilho vazio |
| `linha` | `#2C3036` | `#DADDE2` | bordas e divisórias |
| `texto` | `#ECEDEE` | `#111316` | texto principal |
| `textoSecundario` | `#9BA1A8` | `#565D66` | metadado, rótulo, legenda |
| `concluido` | `#5C636B` | `#9AA0A8` | passo feito, ligação do mapa (nunca texto) |
| `voce` | `#C8F169` | `#B8E94A` | preenchimento: sua vez, sua nota, ação principal |
| `voceTexto` | `#C8F169` | `#3F6600` | texto na cor da sua vez |
| `textoSobreVoce` | `#11140A` | `#11140A` | texto em cima de `voce` |
| `claude` | `#FF8A65` | `#F26B43` | preenchimento: vez do Claude, nota do Claude |
| `claudeTexto` | `#FF9D7E` | `#B23A12` | texto na cor do Claude |
| `erro` | `#FF6B6B` | `#C42B2B` | falha de frente ou de processo |

As versões de fundo e de borda das cores de vez são o mesmo token com opacidade (`voce` a 8% no fundo e 35% na borda, no escuro; `claude` a 10% e 35%), definidas no `Theme`, não na view.

Regras:

- **Limão só para o que é seu.** Sua vez, sua nota, a decisão que espera você e a única ação principal da tela. Se algo limão não depende de você, está errado.
- **Coral só para o Claude.** Vez dele, nota dele, frente rodando.
- **Parado não tem cor**: ponto vazado em `textoSecundario`.
- **Concluído é neutro**, nunca verde. Coisa feita não pede atenção.
- Não existe azul, roxo, gradiente ou cor decorativa. Erro é a única exceção às cores de vez.
- **Cor nunca é a única pista**: toda vez também tem texto ("Sua vez", "Vez do Claude", "parado"), e todo estado tem forma.
- Contraste medido (WCAG) dos pares de texto: `textoSecundario` 6,9:1 sobre `superficie` no escuro e 6,7:1 no claro; `voceTexto` 6,8:1 no claro; `claudeTexto` 6,0:1 no claro; `textoSobreVoce` 13:1. Token novo de texto só entra com o contraste medido e anotado aqui.

## A vez

A vez é o conceito visual central. Ela é calculada a partir do estado gravado (eventos, decisões pendentes), nunca pedida ao modelo.

- Três valores, sempre com a mesma forma: **você** (ponto cheio limão), **Claude** (ponto cheio coral), **parado** (ponto vazado). Ponto de 8 pt.
- O **indicador de vez** fica na barra superior: pílula com o ponto e o rótulo, uma linha secundária com o motivo ("1 decisão esperando", "mapa só para leitura") e o botão "Passar a vez" / "Retomar" com atalho ⌘↵.
- Na vez do Claude, o mapa fica **só para leitura**: contorno interno de 1 pt em coral, faixa no topo dizendo o que ele está fazendo, conteúdo a ~78% de opacidade. Nada de cadeado piscando ou overlay escuro.
- Decidir uma pergunta passa a vez para o Claude no mesmo gesto. A tela troca de limão para coral sem animação de atenção.

## Grau da evidência

Todo fato mostra de onde veio. O grau é desenhado por **forma**, não por cor, e é um componente único (`EvidenceGrade`).

| Grau | Marca | Texto |
|---|---|---|
| medido | quadrado cheio de 7 pt na cor `texto` | "medido" |
| visto no código | `</>` em mono, peso semibold | "no código" |
| inferido | círculo tracejado de 7 pt | "inferido", em itálico |

- O texto de um fato inferido também vai em itálico e `textoSecundario`. Uma peça do mapa cujo conteúdo é inferido tem borda tracejada.
- Número medido pode ganhar uma barra proporcional (trilho `superficieAtiva`, preenchimento `texto`). Número inferido nunca ganha barra: barra sugere precisão.

## O mapa

- Fundo `fundo` com grade de pontos (1 pt, espaçamento 20 pt, `texto` a ~7%). A grade só existe em superfícies onde se pode mexer; área de leitura é lisa.
- **Faixas por área**, na ordem Telas, Fluxos, Serviços, Infra, separadas por linha tracejada, com o nome no topo em rótulo mono maiúsculo.
- **Peça**: `superficie`, borda `linha`, raio 10, sombra discreta. Primeira linha é o tipo (rótulo mono), segunda o nome (semibold), depois o número com o grau. A peça mais importante para a pergunta atual pode ter borda `textoSecundario` e o número em destaque (mono, ~30 pt).
- **Ligação**: linha de 1,5 pt em `concluido`, seta só no sentido do fluxo, rótulo mono curto quando a relação não é óbvia ("chama").
- **Nota**: `superficieElevada`, borda na cor do autor a 35%, ponto do autor e nome em mono. Notas ficam presas a uma peça. Pergunta do Claude que depende de você ganha uma linha em `voceTexto` apontando para a decisão.
- Controles flutuantes (zoom, ferramentas) ficam num canto, em `superficie` com borda e sombra. Um grupo por canto, no máximo.
- O layout das peças é automático por faixa; a posição manual que o usuário der é persistida.

## Trilhas

- Uma linha por frente: nome, trilho segmentado (um segmento por passo) e estado à direita, com ponto da vez.
- Segmento feito: `concluido`. Rodando: `claude`. Esperando você: contorno `voce` com fundo `voce` a 8%. Futuro: `superficieAtiva`.
- Nada anima dentro do trilho. Progresso muda quando o passo muda.
- O **terminal** abre como gaveta das trilhas (atalho ⌃\`), escondido por padrão. Ele serve para conferir, não para acompanhar.

## Tipografia

- Duas famílias, embarcadas no app (licença SIL OFL): **Geist** para interface e **Geist Mono** para números, metadados, rótulos, caminhos, código e saída de terminal.
- Toda fonte passa por um tipo `Typography`, com `Font.custom(_:size:relativeTo:)` ligado ao estilo de texto do sistema equivalente, para respeitar o tamanho de texto do usuário. Nunca `.font(.system(size:))` nem tamanho solto na view.

| Papel | Família | Tamanho / peso | Relativo a |
|---|---|---|---|
| Título da tela | Geist | 26 / semibold, tracking −2% | `.largeTitle` |
| Título do assunto | Geist | 20–24 / semibold | `.title` |
| Corpo | Geist | 13 / regular | `.body` |
| Secundário | Geist | 12 / regular | `.callout` |
| Rótulo de seção | Geist Mono | 10,5 / semibold, maiúsculas, tracking +8% | `.caption` |
| Metadado e atalho | Geist Mono | 11 / regular | `.caption` |
| Número em destaque | Geist Mono | 30 / semibold, tracking −3% | `.title` |

- No máximo três níveis de hierarquia por tela. Peso semibold é o único destaque; negrito pesado não entra.
- Texto que o usuário pode querer copiar (caminho, ID, comando, saída) tem `.textSelection(.enabled)`.

## Espaçamento e forma

- Escala de 4 pt num tipo `Spacing`: 4, 8, 12, 16, 20, 24, 32, 40. Nenhum número fora dela.
- Raios num tipo `Radius`: 4 (tecla, chip), 6 (botão, controle pequeno), 8 (nota, campo, controle segmentado), 10 (peça, item da mesa), 12 (bloco, campo de comando). Pílula (raio total) só para o indicador de vez.
- Borda de 1 pt em `linha` separa; sombra só em peça do mapa e em elemento flutuante.
- Densidade é de ferramenta: linhas de lista com 6–12 pt de respiro vertical, não 20.

## Componentes

- Botão comum: `superficieElevada`, borda `linha`, raio 6. Botão principal: preenchimento `voce`, texto `textoSobreVoce`. **Um botão principal por tela**, e só quando a ação é sua.
- Opções de uma decisão têm o mesmo peso visual, nunca uma principal e outra secundária: o desenho não empurra a escolha. Cada opção mostra a consequência e a tecla (1, 2).
- Atalho de teclado aparece junto do controle, em mono e `textoSecundario` (`⌘↵`, `⌃\``, `J/K`).
- Menus, menus de contexto, folhas, alertas, seletor de arquivo e Ajustes continuam sendo os do sistema, com o vidro e a aparência que o macOS der. A identidade própria vale para a área de trabalho, não para esses elementos.
- Ícones: SF Symbols, com moderação. Vez e grau são desenhados (ponto, quadrado, `</>`), não ícones. Título e botão não ganham ícone decorativo.
- A marca é o logo de dois traços (`FridayMark`): a haste do f, escrita por você (`voce`), e a barra que a atravessa, escrita pelo Claude (`claude`). Ao lado, a palavra `friday` em Geist semibold. A geometria mora só em `FridayMarkShapes.swift`; o ícone do app sai dela por `scripts/icone.swift`.
- **Abertura**: o logo se escreve na ordem da vez (primeiro o seu traço, depois o do Claude), o nome aparece e a tela some, em cerca de 1,3 s. Clique ou tecla pulam; com "Reduzir movimento" vira só aparecer e sumir. É a única animação de marca do app: ela não se repete nem vira indicador de carregamento.

## Movimento

- Transições com `.smooth` ou `.snappy`. Sem durações inventadas.
- Respeite "Reduzir movimento" (`@Environment(\.accessibilityReduceMotion)`): troque movimento por fade.
- Nada pisca, pulsa ou se move sem o usuário ter um motivo para olhar. Troca de vez é troca de cor, não animação. **Atenção do usuário é recurso escasso**, e este é o princípio central do Friday.

## Comunicação na interface

- Português, frase curta, conclusão primeiro.
- Título de botão é verbo no infinitivo ("Passar a vez", "Começar"), não substantivo.
- Todo resumo diz de onde saiu ("fonte: 14 eventos · 2 arquivos · 3 commits"). Nada na tela é texto inventado pelo modelo para preencher espaço.
- Erro diz o que aconteceu e o que fazer, sem jargão.
- Confirmação só para ação destrutiva e irreversível, com `role: .destructive`.

## O que não entra

- Painel de métricas, gráfico decorativo ou número sem fonte.
- Card em volta de tudo. Card é para objeto (peça, assunto, decisão), não para agrupar texto.
- Faixa colorida na borda esquerda como destaque, gradiente, brilho, emoji.
- Cor nova fora da tabela. Se surgir a necessidade, ela muda este guia primeiro.

## Acessibilidade

- Todo controle sem texto visível tem `.accessibilityLabel`. Trilho e régua de percurso têm rótulo com o valor ("passo 1 de 3, rodando").
- Navegação completa por teclado: foco visível, Tab entre lateral, coluna de retorno, mapa e trilhas; atalhos para as ações frequentes.
- "Aumentar contraste" engrossa bordas e linhas do mapa para 2 pt e troca `textoSecundario` por `texto`. "Reduzir transparência" troca as cores de vez com opacidade por versões sólidas.
- Teste com VoiceOver as telas novas antes de considerar uma fase concluída.

## Prévias

Toda view nova tem `#Preview` com dados de exemplo (fixtures), no escuro e no claro, e ao menos uma prévia de cada vez (você, Claude, parado) quando a view depende dela. A prévia é a primeira revisão visual, antes de abrir o app.
