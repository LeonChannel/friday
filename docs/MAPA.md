# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

## agentes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`AgentSessionID.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentSessionID.swift) | Domain | Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |

## composicao

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FridayApp.swift`](../Friday/App/FridayApp.swift) | App | Ponto de entrada do app: abre o banco local e monta as dependências reais de cada funcionalidade. |

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
| [`RootView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/RootView.swift) | Features | Janela principal: barra lateral de projetos e o detalhe do projeto escolhido, com prévias de exemplo. |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |

## pastas

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FileChange.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FileChange.swift) | Domain | Uma mudança observada no disco (arquivo criado, alterado, apagado ou renomeado) entregue em lotes pelo vigia. |
| [`FileNode.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FileNode.swift) | Domain | Um item do disco (arquivo ou pasta) como a árvore de arquivos do projeto o enxerga. |
| [`FilesProtocols.swift`](../Packages/FridayKit/Sources/FridayDomain/Files/FilesProtocols.swift) | Domain | Contratos de quem lê pastas, quem lê o status do git e quem vigia mudanças, para features e testes não dependerem do disco. |
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`ProjectFilesModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesModel.swift) | Features | Estado da árvore de arquivos e do git de um projeto: abre pastas sob demanda e se atualiza sozinho quando o disco muda. |
| [`ProjectFilesView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Files/ProjectFilesView.swift) | Features | Árvore de arquivos do projeto com pastas que abrem sob demanda e a marca de git (M, A, D, R, ?, U) ao lado de cada item. |
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
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`AppDatabase.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Database/AppDatabase.swift) | Infrastructure | Banco SQLite do Friday: onde o arquivo fica no disco e as migrações que montam as tabelas. |
| [`GRDBProjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/GRDBProjectRepository.swift) | Infrastructure | Guarda os projetos no banco e avisa a tela a cada mudança, sem ela precisar recarregar. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |

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

## terminal

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`CommandRunner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Processes/CommandRunner.swift) | Infrastructure | Único ponto que lança um programa de linha de comando, espera terminar e devolve código de saída, saída e erro. |

## testes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`ProjectFilesFlowTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesFlowTests.swift) | Teste | Fluxo ponta a ponta sem tela: repositório git temporário, leitor, git e vigia reais; mexer no disco muda o que o modelo mostra. |
| [`ProjectFilesModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectFilesModelTests.swift) | Teste | Prova a árvore de arquivos e o git na tela: abre pasta sob demanda, marca status e recarrega só o necessário quando o vigia avisa. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`FolderChangeWatcherTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FolderChangeWatcherTests.swift) | Teste | Prova o vigia de pasta com FSEvents real: evento ao escrever, filtro de .git, fim do fluxo ao parar. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`GitStatusParserTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusParserTests.swift) | Teste | Prova que a saída porcelain v2 do git é lida certo: cabeçalho, tipos de mudança, nomes com espaço, renomeação e conflito. |
| [`GitStatusReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GitStatusReaderTests.swift) | Teste | Roda o git de verdade num repositório temporário e prova modificado, novo, renomeado, apagado, não rastreado e pasta sem git. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`LocalFolderReaderTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderReaderTests.swift) | Teste | Prova a leitura de pasta: um nível por vez, pastas primeiro, ordem alfabética e .git e .DS_Store escondidos. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`TemporaryGitRepository.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryGitRepository.swift) | Teste | Cria um repositório git descartável com identidade fictícia, para os testes nunca tocarem repositórios reais. |
| [`mapa.swift`](../scripts/mapa.swift) | Script | Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado. |
