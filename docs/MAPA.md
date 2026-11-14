# Mapa do código

Gerado por `swift scripts/mapa.swift` a partir do cabeçalho de cada arquivo. Não edite à mão: mude o cabeçalho e rode o script. Tags e significados em [VOCABULARIO.md](VOCABULARIO.md).

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
| [`RootView.swift`](../Packages/FridayKit/Sources/FridayFeatures/Shell/RootView.swift) | Features | Janela principal: barra lateral de projetos e o detalhe do projeto escolhido, com prévias de exemplo. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |

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

## testes

| Arquivo | Camada | Resumo |
|---|---|---|
| [`ProjectTests.swift`](../Packages/FridayKit/Tests/FridayDomainTests/ProjectTests.swift) | Teste | Prova as regras de caminho e nome de projeto. |
| [`ProjectsModelTests.swift`](../Packages/FridayKit/Tests/FridayFeaturesTests/ProjectsModelTests.swift) | Teste | Prova o cadastro de projetos na tela: normaliza caminho, recusa inválido e duplicado, espelha o banco. |
| [`GRDBProjectRepositoryTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/GRDBProjectRepositoryTests.swift) | Teste | Prova que o banco guarda, apaga e avisa mudanças de projetos na ordem certa. |
| [`LocalFolderInspectorTests.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/LocalFolderInspectorTests.swift) | Teste | Prova a detecção de pasta comum, clone git, worktree, caminho inexistente e arquivo. |
| [`TemporaryDirectory.swift`](../Packages/FridayKit/Tests/FridayInfrastructureTests/TemporaryDirectory.swift) | Teste | Pasta temporária descartável para os testes não tocarem nos arquivos reais do usuário. |
| [`mapa.swift`](../scripts/mapa.swift) | Script | Gera o docs/MAPA.md a partir dos cabeçalhos dos arquivos e confere resumo, tags e mapa atualizado. |
