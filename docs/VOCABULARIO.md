# Vocabulário de tags

Todo arquivo `.swift` do Friday começa com um cabeçalho de duas linhas:

```swift
// Resumo: o que este arquivo faz, em linguagem funcional, numa frase.
// Tags: projetos, persistencia
```

- **Resumo:** uma frase em português, até 200 caracteres, dizendo o que o arquivo faz para o produto, não como faz.
- **Tags:** uma ou mais da lista abaixo, separadas por vírgula. **A lista é fechada**: tag fora dela é erro, e o CI recusa. Precisa de uma nova? Acrescente aqui com o significado, no mesmo PR.

Tipos e funções públicas também levam `///` com um resumo funcional em português (o Xcode e o VS Code mostram ao passar o mouse).

O índice `docs/MAPA.md` é gerado a partir desses cabeçalhos com `swift scripts/mapa.swift` e conferido no CI com `--check`. Para achar tudo de um assunto: abra o mapa ou rode `rg 'Tags:.*persistencia'`.

| Tag | Significado |
|---|---|
| `projetos` | cadastro e lista dos projetos (pastas e repositórios) que o Friday acompanha |
| `persistencia` | banco local, migrações e tudo que grava ou lê do SQLite |
| `pastas` | leitura e inspeção de pastas e arquivos no disco |
| `git` | qualquer coisa que entende ou consulta repositórios git |
| `interface` | telas, componentes visuais e estado de tela |
| `composicao` | montagem das dependências reais do app (composition root) |
| `testes` | apoio a testes e os próprios testes |
| `agentes` | sessões de agentes de IA (Claude Code, Codex): tipos, identificação e como são abertos |
| `terminal` | terminal embutido, processos e PTY |
| `sensor` | recebimento dos eventos dos agentes (hooks), socket local e gravação desses eventos |
| `linha-do-tempo` | projeções dos eventos em linha do tempo, status e esteira |
| `visual` | tema, cores, tipografia, espaçamentos e componentes visuais próprios do Friday |
| `assuntos` | o assunto e suas partes (intenção, perguntas, evidências, alternativas, decisões, frentes) e a vez |
| `configuracoes` | preferências do usuário e a tela de Ajustes |
| `cota` | uso das cotas do Claude (janelas de 5 horas e 7 dias) lido da statusline e mostrado no rodapé da lateral |
| `backlog` | épico, história, task, subtask e bug do projeto: o quadro de bugs, a árvore, a CLI `friday bug`/`friday item` e o espelho no vault |
| `memoria` | o vault: camadas (abstração, processual, projeto), notas, área de trabalho do assunto e o que chega ao agente pelos hooks |
| `jornadas` | tipo de atividade (erro, teste, tarefa, marco, dúvida), a jornada que o dev configura para cada um (prompt, skills, etapas), o briefing do Claude e a lousa de etapas |
