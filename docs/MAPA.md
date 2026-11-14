# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

## agentes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`AgentSessionID.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentSessionID.swift) | Domain | Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`AgentEvent.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEvent.swift) | Domain | Um acontecimento numa sessão de agente (prompt enviado, ferramenta usada, fim de turno...) já separado do JSON bruto do hook. |
| [`SessionActivity.swift`](../Packages/FridayKit/Sources/FridayDomain/Timeline/SessionActivity.swift) | Domain | Resume uma sessão a partir dos eventos gravados (fase atual, arquivos alterados, ferramentas usadas) sem pedir nada à IA. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`ClaudeSessionHooks.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/ClaudeSessionHooks.swift) | Infrastructure | Prepara uma sessão do Claude Code para reportar hooks ao Friday: settings próprio da sessão, variáveis de ambiente e o flag --settings. |
| [`HookScript.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/HookScript.swift) | Infrastructure | Script de shell que o agente chama a cada hook: repassa o JSON ao socket do Friday e nunca atrasa nem derruba o agente. |
| [`DefaultLaunchPlanner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Terminal/DefaultLaunchPlanner.swift) | Infrastructure | Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`ClaudeSessionHooksTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ClaudeSessionHooksTests.swift) | Teste | Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |

## assuntos

| Arquivo | Camada | Resumo |
|---|---|---|
| [`CommandLineArguments.swift`](../Packages/FridayKit/Sources/FridayCLI/CommandLineArguments.swift) | ? | Separa os argumentos da CLI em posicionais, opções com valor (repetíveis) e chaves sem valor, recusando opção desconhecida. |
| [`SubjectCommandRunner.swift`](../Packages/FridayKit/Sources/FridayCLI/SubjectCommandRunner.swift) | ? | Executa os comandos `friday` (assunto, evidência, pergunta, decisão, frente, alternativa) contra o banco e devolve texto curto e estável. |
| [`SubjectMarkdown.swift`](../Packages/FridayKit/Sources/FridayCLI/SubjectMarkdown.swift) | ? | Escreve o assunto em markdown compacto, para o Claude carregar barato o estado dele. |
| [`Subject.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/Subject.swift) | Domain | O assunto: título, intenção e as partes que o dev e o Claude desenvolvem juntos, com validação de teto em cada escrita. |
| [`SubjectLimits.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectLimits.swift) | Domain | Tetos de caracteres de cada texto do assunto e o erro que recusa texto grande demais, dizendo o tamanho. |
| [`SubjectParts.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectParts.swift) | Domain | As partes de um assunto (evidência, pergunta, alternativa, decisão e frente) e o grau de cada evidência. |
| [`SubjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectRepository.swift) | Domain | Contrato de onde os assuntos ficam guardados: lista ao vivo, leitura, criação e alteração atômica. |
| [`SubjectResume.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectResume.swift) | Domain | Monta o "Onde você parou" (objetivo, confirmado, em aberto, sua vez, depois) só do estado gravado, sem inventar linha. |
| [`SubjectTurn.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectTurn.swift) | Domain | Calcula de quem é a vez no assunto (você, Claude ou parado) e o motivo em texto curto, só do estado gravado. |
| [`SubjectModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectModel.swift) | Features | Estado de um assunto aberto na tela: as partes, a vez e o "Onde você parou", acompanhando o banco ao vivo. |
| [`SubjectsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectsModel.swift) | Features | Lista de assuntos na tela, cada um com a sua vez, acompanhando o banco ao vivo. |
| [`SubjectsPreviewView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectsPreviewView.swift) | Features | Telas mínimas e neutras da lista de assuntos e do "Onde você parou", só para prévia até o tema chegar. |
| [`GRDBSubjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Subjects/GRDBSubjectRepository.swift) | Infrastructure | Guarda os assuntos no banco (partes em JSON, vez e atualização em colunas) e avisa a tela de mudanças, mesmo as feitas pela CLI. |
| [`SubjectChangeSignal.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Subjects/SubjectChangeSignal.swift) | Infrastructure | Aviso entre processos de que um assunto mudou no banco, para o app aberto atualizar quando a CLI escreve. |
| [`main.swift`](../Packages/FridayKit/Sources/friday-cli/main.swift) | ? | Ponto de entrada do comando `friday`: abre o banco (o do app, ou o de FRIDAY_DB), roda o comando e avisa o app se algo foi gravado. |
| [`FridayBinaryTests.swift`](../Packages/FridayKit/Tests/FridayCLITests/FridayBinaryTests.swift) | Teste | Roda o binário `friday` de verdade contra um banco temporário, com o app "aberto" no mesmo arquivo, e prova que a escrita chega nele. |
| [`SubjectCommandRunnerTests.swift`](../Packages/FridayKit/Tests/FridayCLITests/SubjectCommandRunnerTests.swift) | Teste | Prova os comandos da CLI de assunto em processo contra banco em memória: saída, recusa de texto grande e erros de uso. |
| [`SubjectLimitsTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SubjectLimitsTests.swift) | Teste | Prova que cada texto do assunto é recusado acima do teto, com o tamanho na mensagem, e que o limite exato passa. |
| [`SubjectProjectionTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SubjectProjectionTests.swift) | Teste | Prova a vez (você, Claude, parado) e o "Onde você parou" com assuntos de exemplo fixos, incluindo linhas que ficam vazias. |
| [`SubjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/SubjectsModelTests.swift) | Teste | Prova que a lista de assuntos e o assunto aberto na tela acompanham o banco e calculam vez e "Onde você parou". |
| [`GRDBSubjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBSubjectRepositoryTests.swift) | Teste | Prova que o banco guarda os assuntos com todas as partes, altera em transação, consulta a vez e enxerga escrita de outro processo. |

## composicao

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FridayApp.swift`](../Friday/App/FridayApp.swift) | App | Ponto de entrada do app: abre o banco, liga o sensor de hooks e monta as dependências reais de cada funcionalidade. |

## git

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FileChange.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FileChange.swift) | Domain | Uma mudança observada no disco (arquivo criado, alterado, apagado ou renomeado) entregue em lotes pelo vigia. |
| [`FilesProtocols.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FilesProtocols.swift) | Domain | Contratos de quem lê pastas, quem lê o status do git e quem vigia mudanças, para features e testes não dependerem do disco. |
| [`GitStatus.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/GitStatus.swift) | Domain | Retrato do git de um projeto: branch, quanto está à frente ou atrás do remoto e cada arquivo alterado com seu tipo. |
| [`GitChangePresentation.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/GitChangePresentation.swift) | Features | Como cada tipo de alteração do git aparece na tela: letra, texto para VoiceOver e cor do sistema. |
| [`GitSummaryView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/GitSummaryView.swift) | Features | Resumo do git do projeto: branch, quantos commits à frente ou atrás do remoto e quantos arquivos estão alterados. |
| [`ProjectFilesModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesModel.swift) | Features | Estado da árvore de arquivos e do git de um projeto: abre pastas sob demanda e se atualiza sozinho quando o disco muda. |
| [`ProjectFilesView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesView.swift) | Features | Árvore de arquivos do projeto com pastas que abrem sob demanda e a marca de git (M, A, D, R, ?, U) ao lado de cada item. |
| [`FolderChangeWatcher.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Files/FolderChangeWatcher.swift) | Infrastructure | Vigia uma pasta com FSEvents e entrega lotes de mudanças, ignorando o ruído de dentro de .git exceto o que muda o status. |
| [`GitStatusParser.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Git/GitStatusParser.swift) | Infrastructure | Traduz a saída `git status --porcelain=v2 -z --branch` em branch, ahead/behind e arquivos alterados. |
| [`GitStatusReader.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Git/GitStatusReader.swift) | Infrastructure | Pergunta ao git o status de um projeto e devolve "sem git" quando a pasta não é repositório. |
| [`CommandRunner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Processes/CommandRunner.swift) | Infrastructure | Único ponto que lança um programa de linha de comando, espera terminar e devolve código de saída, saída e erro. |
| [`LocalFolderInspector.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/LocalFolderInspector.swift) | Infrastructure | Olha uma pasta no disco e diz se ela existe e se é repositório git (inclusive worktree). |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`FolderChangeWatcherTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FolderChangeWatcherTests.swift) | Teste | Prova o vigia de pasta com FSEvents real: evento ao escrever, filtro de .git, fim do fluxo ao parar. |
| [`GitStatusParserTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusParserTests.swift) | Teste | Prova que a saída porcelain v2 do git é lida certo: cabeçalho, tipos de mudança, nomes com espaço, renomeação e conflito. |
| [`GitStatusReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusReaderTests.swift) | Teste | Roda o git de verdade num repositório temporário e prova modificado, novo, renomeado, apagado, não rastreado e pasta sem git. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`TemporaryGitRepository.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryGitRepository.swift) | Teste | Cria um repositório git descartável com identidade fictícia, para os testes nunca tocarem repositórios reais. |

## interface

| Arquivo | Camada | Resumo |
|---|---|---|
| [`GitChangePresentation.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/GitChangePresentation.swift) | Features | Como cada tipo de alteração do git aparece na tela: letra, texto para VoiceOver e cor do sistema. |
| [`GitSummaryView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/GitSummaryView.swift) | Features | Resumo do git do projeto: branch, quantos commits à frente ou atrás do remoto e quantos arquivos estão alterados. |
| [`ProjectFilesModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesModel.swift) | Features | Estado da árvore de arquivos e do git de um projeto: abre pastas sob demanda e se atualiza sozinho quando o disco muda. |
| [`ProjectFilesView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesView.swift) | Features | Árvore de arquivos do projeto com pastas que abrem sob demanda e a marca de git (M, A, D, R, ?, U) ao lado de cada item. |
| [`ProjectsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsModel.swift) | Features | Estado da lista de projetos na tela: adiciona com validação, remove e acompanha o banco ao vivo. |
| [`ProjectsSidebar.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsSidebar.swift) | Features | Barra lateral com os projetos: escolher pasta para adicionar, remover pelo menu de contexto e mostrar erros. |
| [`RootView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/RootView.swift) | Features | Janela principal: projetos na lateral, terminais do projeto no centro e, no inspetor, a linha do tempo da sessão ou os arquivos e o git. |
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda por projeto as sessões de terminal, a linha do tempo de cada sessão e a árvore de arquivos, para trocar de projeto sem perder nada. |
| [`SubjectModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectModel.swift) | Features | Estado de um assunto aberto na tela: as partes, a vez e o "Onde você parou", acompanhando o banco ao vivo. |
| [`SubjectsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectsModel.swift) | Features | Lista de assuntos na tela, cada um com a sua vez, acompanhando o banco ao vivo. |
| [`SubjectsPreviewView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Subjects/SubjectsPreviewView.swift) | Features | Telas mínimas e neutras da lista de assuntos e do "Onde você parou", só para prévia até o tema chegar. |
| [`TerminalArea.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalArea.swift) | Features | Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias. |
| [`TerminalSessionView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionView.swift) | Features | Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`SessionTimelineModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Timeline/SessionTimelineModel.swift) | Features | Acompanha ao vivo os eventos de uma sessão de agente e o resumo deduzido deles, para o painel da linha do tempo. |
| [`SessionTimelineView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Timeline/SessionTimelineView.swift) | Features | Painel da sessão: fase atual, arquivos alterados e a linha do tempo dos eventos do agente, mais recente em cima. |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`SubjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/SubjectsModelTests.swift) | Teste | Prova que a lista de assuntos e o assunto aberto na tela acompanham o banco e calculam vez e "Onde você parou". |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |

## linha-do-tempo

| Arquivo | Camada | Resumo |
|---|---|---|
| [`SessionActivity.swift`](../Packages/FridayKit/Sources/FridayDomain/Timeline/SessionActivity.swift) | Domain | Resume uma sessão a partir dos eventos gravados (fase atual, arquivos alterados, ferramentas usadas) sem pedir nada à IA. |
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda por projeto as sessões de terminal, a linha do tempo de cada sessão e a árvore de arquivos, para trocar de projeto sem perder nada. |
| [`SessionTimelineModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Timeline/SessionTimelineModel.swift) | Features | Acompanha ao vivo os eventos de uma sessão de agente e o resumo deduzido deles, para o painel da linha do tempo. |
| [`SessionTimelineView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Timeline/SessionTimelineView.swift) | Features | Painel da sessão: fase atual, arquivos alterados e a linha do tempo dos eventos do agente, mais recente em cima. |
| [`SessionActivityTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SessionActivityTests.swift) | Teste | Prova que a fase da sessão, os arquivos alterados e as contagens saem certos de uma sequência de eventos. |

## pastas

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FileChange.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FileChange.swift) | Domain | Uma mudança observada no disco (arquivo criado, alterado, apagado ou renomeado) entregue em lotes pelo vigia. |
| [`FileNode.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FileNode.swift) | Domain | Um item do disco (arquivo ou pasta) como a árvore de arquivos do projeto o enxerga. |
| [`FilesProtocols.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FilesProtocols.swift) | Domain | Contratos de quem lê pastas, quem lê o status do git e quem vigia mudanças, para features e testes não dependerem do disco. |
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`ProjectFilesModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesModel.swift) | Features | Estado da árvore de arquivos e do git de um projeto: abre pastas sob demanda e se atualiza sozinho quando o disco muda. |
| [`ProjectFilesView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesView.swift) | Features | Árvore de arquivos do projeto com pastas que abrem sob demanda e a marca de git (M, A, D, R, ?, U) ao lado de cada item. |
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda por projeto as sessões de terminal, a linha do tempo de cada sessão e a árvore de arquivos, para trocar de projeto sem perder nada. |
| [`FolderChangeWatcher.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Files/FolderChangeWatcher.swift) | Infrastructure | Vigia uma pasta com FSEvents e entrega lotes de mudanças, ignorando o ruído de dentro de .git exceto o que muda o status. |
| [`LocalFolderReader.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Files/LocalFolderReader.swift) | Infrastructure | Lista uma pasta do disco um nível por vez, pastas primeiro e em ordem alfabética, escondendo .git e .DS_Store. |
| [`LocalFolderInspector.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/LocalFolderInspector.swift) | Infrastructure | Olha uma pasta no disco e diz se ela existe e se é repositório git (inclusive worktree). |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`FolderChangeWatcherTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FolderChangeWatcherTests.swift) | Teste | Prova o vigia de pasta com FSEvents real: evento ao escrever, filtro de .git, fim do fluxo ao parar. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`LocalFolderReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderReaderTests.swift) | Teste | Prova a leitura de pasta: um nível por vez, pastas primeiro, ordem alfabética e .git e .DS_Store escondidos. |

## persistencia

| Arquivo | Camada | Resumo |
|---|---|---|
| [`SubjectCommandRunner.swift`](../Packages/FridayKit/Sources/FridayCLI/SubjectCommandRunner.swift) | ? | Executa os comandos `friday` (assunto, evidência, pergunta, decisão, frente, alternativa) contra o banco e devolve texto curto e estável. |
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`AgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEventRepository.swift) | Domain | Contrato de onde os eventos dos agentes ficam guardados e como a tela os acompanha ao vivo. |
| [`SubjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Subjects/SubjectRepository.swift) | Domain | Contrato de onde os assuntos ficam guardados: lista ao vivo, leitura, criação e alteração atômica. |
| [`AppDatabase.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Database/AppDatabase.swift) | Infrastructure | Banco SQLite do Friday: onde o arquivo fica no disco e as migrações que montam as tabelas. |
| [`GRDBProjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/GRDBProjectRepository.swift) | Infrastructure | Guarda os projetos no banco e avisa a tela a cada mudança, sem ela precisar recarregar. |
| [`GRDBAgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/GRDBAgentEventRepository.swift) | Infrastructure | Guarda os eventos dos agentes no banco e avisa a tela a cada novo evento, por sessão ou os mais recentes de todas. |
| [`SensorService.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/SensorService.swift) | Infrastructure | Liga o sensor: abre o socket dos hooks, decodifica cada mensagem recebida e grava o evento no banco. |
| [`GRDBSubjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Subjects/GRDBSubjectRepository.swift) | Infrastructure | Guarda os assuntos no banco (partes em JSON, vez e atualização em colunas) e avisa a tela de mudanças, mesmo as feitas pela CLI. |
| [`SubjectChangeSignal.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Subjects/SubjectChangeSignal.swift) | Infrastructure | Aviso entre processos de que um assunto mudou no banco, para o app aberto atualizar quando a CLI escreve. |
| [`main.swift`](../Packages/FridayKit/Sources/friday-cli/main.swift) | ? | Ponto de entrada do comando `friday`: abre o banco (o do app, ou o de FRIDAY_DB), roda o comando e avisa o app se algo foi gravado. |
| [`FridayBinaryTests.swift`](../Packages/FridayKit/Tests/FridayCLITests/FridayBinaryTests.swift) | Teste | Roda o binário `friday` de verdade contra um banco temporário, com o app "aberto" no mesmo arquivo, e prova que a escrita chega nele. |
| [`GRDBAgentEventRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBAgentEventRepositoryTests.swift) | Teste | Testa a gravação e a observação dos eventos dos agentes no banco em memória. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`GRDBSubjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBSubjectRepositoryTests.swift) | Teste | Prova que o banco guarda os assuntos com todas as partes, altera em transação, consulta a vez e enxerga escrita de outro processo. |
| [`SensorServiceFlowTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/SensorServiceFlowTests.swift) | Teste | Teste de fluxo do sensor: o script de hook envia payloads reais do Claude pelo socket e eles aparecem gravados, sem lixo. |

## projetos

| Arquivo | Camada | Resumo |
|---|---|---|
| [`Project.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/Project.swift) | Domain | O que é um projeto no Friday (pasta ou repositório git) e as regras de caminho e nome que valem em todo lugar. |
| [`ProjectError.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectError.swift) | Domain | Erros de cadastro de projeto, com a mensagem em português que o usuário vê. |
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`ProjectsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsModel.swift) | Features | Estado da lista de projetos na tela: adiciona com validação, remove e acompanha o banco ao vivo. |
| [`ProjectsSidebar.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsSidebar.swift) | Features | Barra lateral com os projetos: escolher pasta para adicionar, remover pelo menu de contexto e mostrar erros. |
| [`GRDBProjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/GRDBProjectRepository.swift) | Infrastructure | Guarda os projetos no banco e avisa a tela a cada mudança, sem ela precisar recarregar. |
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |

## sensor

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentSessionID.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentSessionID.swift) | Domain | Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`AgentEvent.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEvent.swift) | Domain | Um acontecimento numa sessão de agente (prompt enviado, ferramenta usada, fim de turno...) já separado do JSON bruto do hook. |
| [`AgentEventDecoder.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEventDecoder.swift) | Domain | Lê a mensagem que o script de hook manda (linha de cabeçalho com agente e sessão, depois o JSON) e monta o evento. |
| [`AgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEventRepository.swift) | Domain | Contrato de onde os eventos dos agentes ficam guardados e como a tela os acompanha ao vivo. |
| [`ClaudeSessionHooks.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/ClaudeSessionHooks.swift) | Infrastructure | Prepara uma sessão do Claude Code para reportar hooks ao Friday: settings próprio da sessão, variáveis de ambiente e o flag --settings. |
| [`GRDBAgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/GRDBAgentEventRepository.swift) | Infrastructure | Guarda os eventos dos agentes no banco e avisa a tela a cada novo evento, por sessão ou os mais recentes de todas. |
| [`HookScript.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/HookScript.swift) | Infrastructure | Script de shell que o agente chama a cada hook: repassa o JSON ao socket do Friday e nunca atrasa nem derruba o agente. |
| [`HookSocketServer.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/HookSocketServer.swift) | Infrastructure | Servidor local (Unix socket) que recebe uma mensagem por conexão dos scripts de hook dos agentes e a entrega ao app. |
| [`SensorLocations.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/SensorLocations.swift) | Infrastructure | Define onde ficam o socket dos hooks, o script de hook e os arquivos de settings por sessão, respeitando o limite de tamanho do caminho do socket. |
| [`SensorService.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/SensorService.swift) | Infrastructure | Liga o sensor: abre o socket dos hooks, decodifica cada mensagem recebida e grava o evento no banco. |
| [`AgentEventDecoderTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/AgentEventDecoderTests.swift) | Teste | Testa a leitura de payloads reais do Claude Code (e de eventos desconhecidos) e a rejeição de mensagens inválidas. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayDomainTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`ClaudeSessionHooksTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ClaudeSessionHooksTests.swift) | Teste | Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`GRDBAgentEventRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBAgentEventRepositoryTests.swift) | Teste | Testa a gravação e a observação dos eventos dos agentes no banco em memória. |
| [`HookScriptTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookScriptTests.swift) | Teste | Prova o script de hook de verdade: entrega ao servidor, sai 0 rápido com o Friday fechado e não trava com servidor parado. |
| [`HookSocketServerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookSocketServerTests.swift) | Teste | Testa o servidor de socket dos hooks: ida e volta, permissões, lixo, limite de tamanho e cliente parado. |
| [`SensorServiceFlowTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/SensorServiceFlowTests.swift) | Teste | Teste de fluxo do sensor: o script de hook envia payloads reais do Claude pelo socket e eles aparecem gravados, sem lixo. |
| [`ShortTemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ShortTemporaryDirectory.swift) | Teste | Pasta temporária de caminho curto, necessária porque o caminho de um Unix socket tem limite de 104 bytes. |

## terminal

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda por projeto as sessões de terminal, a linha do tempo de cada sessão e a árvore de arquivos, para trocar de projeto sem perder nada. |
| [`TerminalArea.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalArea.swift) | Features | Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias. |
| [`TerminalSessionView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionView.swift) | Features | Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`CommandRunner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Processes/CommandRunner.swift) | Infrastructure | Único ponto que lança um programa de linha de comando, espera terminar e devolve código de saída, saída e erro. |
| [`DefaultLaunchPlanner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Terminal/DefaultLaunchPlanner.swift) | Infrastructure | Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis. |
| [`LocalProcessIntegrationTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/LocalProcessIntegrationTests.swift) | Teste | Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |

## testes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FridayBinaryTests.swift`](../Packages/FridayKit/Tests/FridayCLITests/FridayBinaryTests.swift) | Teste | Roda o binário `friday` de verdade contra um banco temporário, com o app "aberto" no mesmo arquivo, e prova que a escrita chega nele. |
| [`SubjectCommandRunnerTests.swift`](../Packages/FridayKit/Tests/FridayCLITests/SubjectCommandRunnerTests.swift) | Teste | Prova os comandos da CLI de assunto em processo contra banco em memória: saída, recusa de texto grande e erros de uso. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayCLITests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`TestTags.swift`](../Packages/FridayKit/Tests/FridayCLITests/TestTags.swift) | Teste | Tags de teste deste módulo, declaradas num lugar só para não colidir. |
| [`AgentEventDecoderTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/AgentEventDecoderTests.swift) | Teste | Testa a leitura de payloads reais do Claude Code (e de eventos desconhecidos) e a rejeição de mensagens inválidas. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayDomainTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`SessionActivityTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SessionActivityTests.swift) | Teste | Prova que a fase da sessão, os arquivos alterados e as contagens saem certos de uma sequência de eventos. |
| [`SubjectLimitsTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SubjectLimitsTests.swift) | Teste | Prova que cada texto do assunto é recusado acima do teto, com o tamanho na mensagem, e que o limite exato passa. |
| [`SubjectProjectionTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/SubjectProjectionTests.swift) | Teste | Prova a vez (você, Claude, parado) e o "Onde você parou" com assuntos de exemplo fixos, incluindo linhas que ficam vazias. |
| [`LocalProcessIntegrationTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/LocalProcessIntegrationTests.swift) | Teste | Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado. |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`SubjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/SubjectsModelTests.swift) | Teste | Prova que a lista de assuntos e o assunto aberto na tela acompanham o banco e calculam vez e "Onde você parou". |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`TestTags.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TestTags.swift) | Teste | Tags de teste compartilhadas deste módulo, declaradas num lugar só para não colidir. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |
| [`ClaudeSessionHooksTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ClaudeSessionHooksTests.swift) | Teste | Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`FolderChangeWatcherTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FolderChangeWatcherTests.swift) | Teste | Prova o vigia de pasta com FSEvents real: evento ao escrever, filtro de .git, fim do fluxo ao parar. |
| [`GRDBAgentEventRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBAgentEventRepositoryTests.swift) | Teste | Testa a gravação e a observação dos eventos dos agentes no banco em memória. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`GRDBSubjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBSubjectRepositoryTests.swift) | Teste | Prova que o banco guarda os assuntos com todas as partes, altera em transação, consulta a vez e enxerga escrita de outro processo. |
| [`GitStatusParserTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusParserTests.swift) | Teste | Prova que a saída porcelain v2 do git é lida certo: cabeçalho, tipos de mudança, nomes com espaço, renomeação e conflito. |
| [`GitStatusReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusReaderTests.swift) | Teste | Roda o git de verdade num repositório temporário e prova modificado, novo, renomeado, apagado, não rastreado e pasta sem git. |
| [`HookScriptTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookScriptTests.swift) | Teste | Prova o script de hook de verdade: entrega ao servidor, sai 0 rápido com o Friday fechado e não trava com servidor parado. |
| [`HookSocketServerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookSocketServerTests.swift) | Teste | Testa o servidor de socket dos hooks: ida e volta, permissões, lixo, limite de tamanho e cliente parado. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`LocalFolderReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderReaderTests.swift) | Teste | Prova a leitura de pasta: um nível por vez, pastas primeiro, ordem alfabética e .git e .DS_Store escondidos. |
| [`SensorServiceFlowTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/SensorServiceFlowTests.swift) | Teste | Teste de fluxo do sensor: o script de hook envia payloads reais do Claude pelo socket e eles aparecem gravados, sem lixo. |
| [`ShortTemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ShortTemporaryDirectory.swift) | Teste | Pasta temporária de caminho curto, necessária porque o caminho de um Unix socket tem limite de 104 bytes. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`TemporaryGitRepository.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryGitRepository.swift) | Teste | Cria um repositório git descartável com identidade fictícia, para os testes nunca tocarem repositórios reais. |
| [`TestTags.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TestTags.swift) | Teste | Tags de teste compartilhadas deste módulo, declaradas num lugar só para não colidir. |
| [`mapa.swift`](../scripts/mapa.swift) | Script | Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado. |
