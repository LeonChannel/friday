// Resumo: Notas iniciais do vault (hub, comunicação, conduta, fluxo, registro e hub do projeto) escritas na primeira vez, para o dev editar.
// Tags: memoria

import FridayDomain
import Foundation

/// Conteúdo das notas que o Friday cria quando a estrutura falta. São ponto de partida: o dev edita, o Friday nunca sobrescreve.
enum MemorySeeds {
    static let hub = """
        # Friday

        Memória do Claude nas sessões abertas pelo Friday. A ordem de leitura é a das camadas:

        | Camada | Pasta | Responde | Chega ao Claude |
        |---|---|---|---|
        | Abstração | `Abstracao/` | como falar e se portar | inteira, no começo de toda sessão |
        | Processual | `Processual/` | como o trabalho anda no Friday | `sempre: true` inteira; o resto como índice |
        | Projeto | `Projetos/<projeto>/` | regras, padrões, armadilhas, decisões, tecnologias, repositórios | hub inteiro; o resto como índice; nota ancorada ao abrir o arquivo |

        A área de trabalho de cada assunto fica em `Projetos/<projeto>/Trabalho/assunto-<id>/` e morre no fim do assunto, depois de destilada.

        Cada nota tem um cabeçalho com `tipo` e `resumo` (até 300 caracteres). O resumo é o que o Claude lê; o corpo é para você.
        O vault é o mapa; a verdade é o código e o git.

        """

    static let layerNotes: [(String, String)] = [
        ("Abstracao/Comunicacao.md", """
            ---
            tipo: comunicacao
            resumo: "Fale em português, direto e natural, com a conclusão primeiro. Deixe claro o nível de certeza (fato, inferência, hipótese, opinião) e diga quando não sabe."
            ---

            # Comunicação

            - Português do Brasil. Termo técnico, nome de API e comando ficam no original.
            - Conclusão primeiro: resposta, erro, bloqueio ou risco no começo; contexto depois.
            - Frase curta, sem preâmbulo, sem recapitular o pedido, sem narrar o que vai fazer.
            - Nível de certeza explícito: fato, inferência, hipótese e opinião não se confundem.
            - Não sabe? Diga que não sabe. Não invente para preencher.
            - Opinião sincera quando houver julgamento em jogo, com o porquê em uma linha.
            - Texto que sai para outra pessoa (commit, PR, documentação) segue o tom do público, não o da conversa.

            Esta nota é sua: edite à vontade, ou use "Importar…" na tela de Memória para trazer as regras que você já usa.
            """),
        ("Abstracao/Conduta.md", """
            ---
            tipo: conduta
            resumo: "Vá do pedido ao resultado sem parar para narrar. Pare só em dúvida que três caminhos diferentes não resolveram, em desvio grande do padrão do projeto ou antes de ação difícil de desfazer."
            ---

            # Conduta

            ## Quando parar e falar com o dev

            1. Dúvida que você não resolveu sozinho depois de três caminhos diferentes. Chegue com o que tentou, as alternativas com custo e a sua recomendação.
            2. Iniciativa que foge do padrão do projeto: arquitetura nova, caminho que não existe, contrariar uma decisão registrada.
            3. Ação difícil de desfazer ou que sai da máquina: apagar, publicar, enviar.

            Fora disso, siga. O que não muda o que você faz agora vira uma linha no relatório final.

            ## Como trabalhar

            - Simples antes de genérico: abstração nova só com um segundo caso real.
            - Evidência vence opinião. O grau de cada fato (medido, no código, inferido) não se infla.
            - Relate o resultado como ele é: teste falhou, diga; passo pulado, diga.
            """),
        ("Processual/Fluxo.md", """
            ---
            tipo: fluxo
            resumo: "Antes: a memória chega sozinha. Durante: o estado vai para o assunto e para a área de trabalho. Depois: o que sobrevive ao assunto vira nota de projeto e a área é fechada."
            sempre: true
            ---

            # Fluxo de trabalho no Friday

            - **Antes.** A memória chega sozinha: abstração e processual no começo da sessão, a nota ancorada quando você abre o arquivo. Sem arquivo na mão, o índice aponta a nota; `friday memoria ler "<caminho>"` traz a inteira.
            - **Durante.** O assunto guarda o estado, não a conversa: evidência com grau, pergunta, decisão, frente (skill friday-assunto). Fase e próximo passo: `friday memoria area <assunto> --estado "..."`. Nota usada é reconferida no código; divergiu, corrija a nota na hora.
            - **Depois.** Isso pouparia tempo de alguém daqui a três meses? Então vira nota de projeto (`friday memoria nota ...` ou `friday memoria promover <assunto> --decisao <n>`). Estado e cache morrem: `friday memoria area <assunto> --fechar`.
            """),
        ("Processual/Registro.md", """
            ---
            tipo: fluxo
            resumo: "Vira nota: regra, causa raiz de bug, armadilha que custou tempo, decisão com consequência ativa, invariante não dito. Não vira: narrativa da sessão, o que o código, o git ou o CLAUDE.md já dizem, segredo com valor."
            ---

            # O que registrar

            ## Registra

            - Regra de negócio e sua condição de contorno.
            - Causa raiz de bug, com a regra que evita a repetição.
            - Armadilha que já custou tempo.
            - Decisão com consequência ativa, com o porquê.
            - Invariante que o código assume sem dizer; comportamento contraintuitivo.

            ## Não registra

            - Narrativa do que foi feito na sessão.
            - O que o `git log`, o código ou o `CLAUDE.md` do repo já contam.
            - Estado de tarefa: vai na área de trabalho do assunto.
            - Segredo com valor (cite onde ele mora, nunca o valor) e opinião sobre pessoa.

            ## Onde

            1. Como o Claude fala ou se porta → `Abstracao/`.
            2. Como o trabalho anda, em qualquer projeto → `Processual/`.
            3. Sobre um sistema → `Projetos/<projeto>/` (`Regras/`, `Padroes/`, `Armadilhas/`, `Decisoes/`, `Tecnologias/`, `Repos/`).

            ## Formato

            `resumo` com até 300 caracteres, falseável: o fato e a consequência. `ancoras` com caminhos relativos à pasta do projeto (pasta termina em `/`). `verificado_em` é a data em que alguém conferiu no código.
            """),
    ]

    /// Hub de um projeto com os repositórios que o Friday enxerga nele.
    static func projectHub(_ project: Project, repositories: [CodeRepository]) -> String {
        let root = URL(fileURLWithPath: project.path).standardizedFileURL.path
        let repoLines = repositories.isEmpty ? ["- (nenhum repositório git encontrado)"] : repositories.map { repo -> String in
            let path = URL(fileURLWithPath: repo.path).standardizedFileURL.path
            let relative = path == root ? "." : path.hasPrefix(root + "/") ? String(path.dropFirst(root.count + 1)) : path
            return "- `\(repo.name)`: `\(relative)`"
        }
        return """
            ---
            tipo: projeto
            resumo: \(MemoryFrontmatter.quoted("Hub do projeto \(project.name): o que é, tecnologias, repositórios e onde achar regras, padrões e decisões."))
            ---

            # \(project.name)

            ## O que é

            (uma frase: o problema que o projeto resolve)

            ## Tecnologias

            - (linguagem, framework, banco: só o que o código não deixa óbvio)

            ## Repositórios

            \(repoLines.joined(separator: "\n"))

            ## Onde achar o resto

            Regras, padrões, armadilhas e decisões ficam nas pastas ao lado deste hub. O índice delas chega no começo da sessão; a nota ancorada chega ao abrir o arquivo.
            """
    }
}
