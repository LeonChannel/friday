# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

## agentes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`AgentSessionID.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentSessionID.swift) | Domain | Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`DefaultLaunchPlanner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Terminal/DefaultLaunchPlanner.swift) | Infrastructure | Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |

## composicao

| Arquivo | Camada | Resumo |
|---|---|---|
| [`FridayApp.swift`](../Friday/App/FridayApp.swift) | App | Ponto de entrada do app: abre o banco local e monta as dependências reais de cada funcionalidade. |

## git

| Arquivo | Camada | Resumo |
|---|---|---|
| [`LocalFolderInspector.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/LocalFolderInspector.swift) | Infrastructure | Olha uma pasta no disco e diz se ela existe e se é repositório git (inclusive worktree). |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |

## interface

| Arquivo | Camada | Resumo |
|---|---|---|
| [`ProjectsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsModel.swift) | Features | Estado da lista de projetos na tela: adiciona com validação, remove e acompanha o banco ao vivo. |
| [`ProjectsSidebar.swift`](../Packages/FridayKit/Sources/FridayFeatures/Projects/ProjectsSidebar.swift) | Features | Barra lateral com os projetos: escolher pasta para adicionar, remover pelo menu de contexto e mostrar erros. |
| [`RootView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/RootView.swift) | Features | Janela principal: barra lateral de projetos e, à direita, os terminais do projeto escolhido, com prévias de exemplo. |
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda as sessões de terminal de cada projeto aberto, para trocar de projeto sem matar o que está rodando. |
| [`TerminalArea.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalArea.swift) | Features | Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias. |
| [`TerminalSessionView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionView.swift) | Features | Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |

## pastas

| Arquivo | Camada | Resumo |
|---|---|---|
| [`ProjectRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Projects/ProjectRepository.swift) | Domain | Contratos que a lista de projetos usa: onde os projetos são guardados e como saber se uma pasta é repositório git. |
| [`LocalFolderInspector.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/LocalFolderInspector.swift) | Infrastructure | Olha uma pasta no disco e diz se ela existe e se é repositório git (inclusive worktree). |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |

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
| [`WorkspaceModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/WorkspaceModel.swift) | Features | Guarda as sessões de terminal de cada projeto aberto, para trocar de projeto sem matar o que está rodando. |
| [`TerminalArea.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalArea.swift) | Features | Área de terminais de um projeto: abas das sessões, botões para abrir shell, Claude Code e Codex, e prévias. |
| [`TerminalSessionView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionView.swift) | Features | Mostra um terminal de verdade (SwiftTerm) rodando a receita de uma sessão e avisa quando o processo termina. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`DefaultLaunchPlanner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Terminal/DefaultLaunchPlanner.swift) | Infrastructure | Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis. |
| [`LocalProcessIntegrationTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/LocalProcessIntegrationTests.swift) | Teste | Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |

## testes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`LocalProcessIntegrationTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/LocalProcessIntegrationTests.swift) | Teste | Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`mapa.swift`](../scripts/mapa.swift) | Script | Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado. |
