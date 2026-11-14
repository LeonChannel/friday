# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

## agentes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`AgentKind.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentKind.swift) | Domain | Quais programas o Friday sabe abrir num terminal: shell comum, Claude Code e Codex. |
| [`AgentSessionID.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/AgentSessionID.swift) | Domain | Identificador único de uma sessão de agente aberta pelo Friday, que liga terminal, hooks e eventos. |
| [`LaunchPlan.swift`](../Packages/FridayKit/Sources/FridayDomain/Agents/LaunchPlan.swift) | Domain | Receita para abrir um programa no terminal (executável, argumentos, ambiente e pasta) e quem monta essa receita. |
| [`AgentEvent.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEvent.swift) | Domain | Um acontecimento numa sessão de agente (prompt enviado, ferramenta usada, fim de turno...) já separado do JSON bruto do hook. |
| [`TerminalSessionsModel.swift`](../Packages/FridayKit/Sources/FridayFeatures/Terminal/TerminalSessionsModel.swift) | Features | Sessões de terminal abertas num projeto: abrir shell, Claude ou Codex, fechar, escolher a ativa e registrar o fim do processo. |
| [`ClaudeSessionHooks.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/ClaudeSessionHooks.swift) | Infrastructure | Prepara uma sessão do Claude Code para reportar hooks ao Friday: settings próprio da sessão, variáveis de ambiente e o flag --settings. |
| [`HookScript.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/HookScript.swift) | Infrastructure | Script de shell que o agente chama a cada hook: repassa o JSON ao socket do Friday e nunca atrasa nem derruba o agente. |
| [`DefaultLaunchPlanner.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Terminal/DefaultLaunchPlanner.swift) | Infrastructure | Monta a receita de cada sessão (shell, Claude, Codex) passando pelo shell de login do usuário para achar os executáveis. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`ClaudeSessionHooksTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ClaudeSessionHooksTests.swift) | Teste | Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global. |
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
| [`AgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayDomain/Sensor/AgentEventRepository.swift) | Domain | Contrato de onde os eventos dos agentes ficam guardados e como a tela os acompanha ao vivo. |
| [`AppDatabase.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Database/AppDatabase.swift) | Infrastructure | Banco SQLite do Friday: onde o arquivo fica no disco e as migrações que montam as tabelas. |
| [`GRDBProjectRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Projects/GRDBProjectRepository.swift) | Infrastructure | Guarda os projetos no banco e avisa a tela a cada mudança, sem ela precisar recarregar. |
| [`GRDBAgentEventRepository.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/GRDBAgentEventRepository.swift) | Infrastructure | Guarda os eventos dos agentes no banco e avisa a tela a cada novo evento, por sessão ou os mais recentes de todas. |
| [`SensorService.swift`](../Packages/FridayKit/Sources/FridayInfrastructure/Sensor/SensorService.swift) | Infrastructure | Liga o sensor: abre o socket dos hooks, decodifica cada mensagem recebida e grava o evento no banco. |
| [`GRDBAgentEventRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBAgentEventRepositoryTests.swift) | Teste | Testa a gravação e a observação dos eventos dos agentes no banco em memória. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
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
| [`AgentEventDecoderTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/AgentEventDecoderTests.swift) | Teste | Testa a leitura de payloads reais do Claude Code (e de eventos desconhecidos) e a rejeição de mensagens inválidas. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayDomainTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`LocalProcessIntegrationTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/LocalProcessIntegrationTests.swift) | Teste | Integração com processo real curto no LocalProcess do SwiftTerm, sem view: a saída chega, a pasta é a certa e o término é detectado. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`TerminalSessionsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/TerminalSessionsModelTests.swift) | Teste | Prova o estado das sessões de terminal: abrir, numerar títulos, selecionar, fechar e registrar o fim do processo. |
| [`WorkspaceModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/WorkspaceModelTests.swift) | Teste | Prova que cada projeto mantém as mesmas sessões de terminal ao ir e voltar. |
| [`ClaudeSessionHooksTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ClaudeSessionHooksTests.swift) | Teste | Testa que o plano do Claude ganha --settings e as variáveis do Friday, e que o settings gerado cobre os hooks sem tocar na config global. |
| [`DefaultLaunchPlannerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/DefaultLaunchPlannerTests.swift) | Teste | Prova a receita de cada agente: executável, argumentos, ambiente limpo e pasta do projeto. |
| [`FixtureLoader.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/FixtureLoader.swift) | Teste | Lê os payloads de hook gravados em Tests/Fixtures para os testes de domínio. |
| [`GRDBAgentEventRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBAgentEventRepositoryTests.swift) | Teste | Testa a gravação e a observação dos eventos dos agentes no banco em memória. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`HookScriptTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookScriptTests.swift) | Teste | Prova o script de hook de verdade: entrega ao servidor, sai 0 rápido com o Friday fechado e não trava com servidor parado. |
| [`HookSocketServerTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/HookSocketServerTests.swift) | Teste | Testa o servidor de socket dos hooks: ida e volta, permissões, lixo, limite de tamanho e cliente parado. |
| [`LaunchCustomizationTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LaunchCustomizationTests.swift) | Teste | Prova que os acréscimos por sessão chegam ao agente intactos, mesmo com espaço e aspas no caminho. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`SensorServiceFlowTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/SensorServiceFlowTests.swift) | Teste | Teste de fluxo do sensor: o script de hook envia payloads reais do Claude pelo socket e eles aparecem gravados, sem lixo. |
| [`ShortTemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/ShortTemporaryDirectory.swift) | Teste | Pasta temporária de caminho curto, necessária porque o caminho de um Unix socket tem limite de 104 bytes. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`mapa.swift`](../scripts/mapa.swift) | Script | Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado. |
