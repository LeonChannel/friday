// Resumo: Lateral do projeto aberto: troca de projeto no topo, Mesa, Sua vez, Memória, Backlog, Bugs, os assuntos, os repositórios (recolhíveis, branch embaixo do nome) e a cota do Claude no rodapé.
// Tags: interface, assuntos, projetos, memoria, cota, backlog

import FridayDomain
import SwiftUI

/// Lateral principal, sempre dentro de um projeto.
struct MainSidebar: View {
    let project: Project
    @Environment(ProjectsModel.self) private var projects
    @Environment(SubjectsModel.self) private var subjects
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(UsageQuotaModel.self) private var usage
    @Binding var selection: Destination?
    /// Repositórios começam recolhidos: numa pasta com muitos projetos a lista tomaria a lateral. A escolha fica guardada.
    @AppStorage("sidebar.repositoriesExpanded") private var showsRepositories = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let switchProject: (Project?) -> Void

    private var backlog: BacklogModel? { workspace.backlog(for: project) }

    var body: some View {
        let repositories = workspace.repositories(for: project)
        List(selection: $selection) {
            Section {
                // Folga do tamanho do esmaecimento do topo: parada, a lista começa inteira à vista.
                Color.clear.frame(height: SidebarFade.topHeight).listRowBackground(Color.clear).listRowSeparator(.hidden).selectionDisabled()
                row(.desk) { Text("Mesa").typography(.corpo) }
                row(.yourTurn) {
                    HStack {
                        Text("Sua vez").typography(.corpo)
                        Spacer()
                        let count = subjects.rows(for: .you).count
                        if count > 0 {
                            Text("\(count)").typography(.metadado).foregroundStyle(Theme.voceTexto)
                                .accessibilityLabel("\(count) esperando você")
                        }
                    }
                }
                row(.memory) { Text("Memória").typography(.corpo) }
                row(.backlog) { Text("Backlog").typography(.corpo) }
                row(.bugs) {
                    HStack {
                        Text("Bugs").typography(.corpo)
                        Spacer()
                        // Triagem não é urgência: o número fica neutro, para não puxar você para fora do que está fazendo.
                        if let count = backlog?.newBugCount, count > 0 {
                            Text("\(count)").typography(.metadado).foregroundStyle(Theme.textoSecundario)
                                .accessibilityLabel("\(count) bugs para triar")
                        }
                    }
                }
            }
            Section {
                if subjects.rows.isEmpty {
                    Text("Nenhum assunto ainda").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                }
                ForEach(subjects.rows) { row in
                    if let id = row.subject.id {
                        self.row(.subject(id)) {
                            HStack(spacing: Spacing.sm) {
                                TurnDot(TurnStyle(row.turn.holder))
                                Text(row.subject.title).typography(.corpo).lineLimit(1)
                            }
                            // Sem a legenda no rodapé, a vez ganha texto no próprio item (cor nunca é a única pista).
                            .help("\(TurnStyle(row.turn.holder).label): \(row.turn.reason)")
                        }
                    }
                }
            } header: {
                MonoLabel("Assuntos", kind: .secao)
            }
            Section {
                if project.kind == .folder, showsRepositories || selection == .folder(project.path) {
                    row(.folder(project.path)) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Pasta do projeto").typography(.corpo)
                            MonoLabel("raiz")
                        }
                    }
                }
                // Recolhida, a seção ainda mostra o repositório aberto, para você saber onde está.
                ForEach(repositories.summaries.filter { showsRepositories || selection == .folder($0.repository.path) }) { summary in
                    row(.folder(summary.repository.path)) { RepositoryRow(summary: summary) }
                }
                if showsRepositories, repositories.isLoading, repositories.summaries.isEmpty {
                    Text("Procurando repositórios…").typography(.secundario).foregroundStyle(Theme.textoSecundario)
                }
                // Folga no fim: o último item consegue subir acima do esmaecimento e ser lido inteiro.
                Color.clear.frame(height: SidebarFade.height).listRowBackground(Color.clear).listRowSeparator(.hidden).selectionDisabled()
            } header: {
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { showsRepositories.toggle() }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.right")
                            .imageScale(.small)
                            .rotationEffect(.degrees(showsRepositories ? 90 : 0))
                            .foregroundStyle(Theme.textoSecundario)
                        MonoLabel(repositories.summaries.isEmpty ? "Repositórios" : "Repositórios · \(repositories.summaries.count)", kind: .secao)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(showsRepositories ? "Recolher repositórios" : "Mostrar repositórios")
                .accessibilityLabel(showsRepositories ? "Recolher repositórios" : "Mostrar repositórios")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Theme.superficie)
        // O topo cobre a lista até a borda da janela (atrás dos botões de fechar), e a lista esmaece ao passar por baixo dele.
        .safeAreaInset(edge: .top, spacing: 0) {
            projectSwitcher
                .background(Theme.superficie.ignoresSafeArea(edges: .top))
                .overlay(alignment: .bottom) {
                    SidebarFade(height: SidebarFade.topHeight).rotationEffect(.degrees(180)).offset(y: SidebarFade.topHeight).allowsHitTesting(false)
                }
        }
        // Encaixada como a legenda era (VStack com a lista quebrou a altura da janela inteira).
        // O esmaecimento é um degradê da cor da lateral subindo da barra: o fundo é sólido, então o efeito é o mesmo de uma máscara.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            QuotaBar(quota: usage.quota)
                .background(Theme.superficie)
                .overlay(alignment: .top) { SidebarFade().offset(y: -SidebarFade.height).allowsHitTesting(false) }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .task(id: project.path) { await repositories.refresh() }
        .task(id: project.path) { await backlog?.observe() }
    }

    /// Topo da lateral: marca e o projeto aberto, com os recentes e a volta à seleção.
    private var projectSwitcher: some View {
        HStack(spacing: Spacing.sm) {
            FridayMark(size: 20)
            Menu {
                ForEach(projects.projects.filter { $0.id != project.id }.prefix(8)) { other in
                    Button(other.name) { switchProject(other) }
                }
                Divider()
                Button("Todos os projetos…") { switchProject(nil) }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text(project.name).typography(.corpo).fontWeight(.semibold).foregroundStyle(Theme.texto).lineLimit(1)
                    Image(systemName: "chevron.down").imageScale(.small).foregroundStyle(Theme.textoSecundario)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Trocar de projeto (⌘⇧O)")
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private func row(_ destination: Destination, @ViewBuilder label: () -> some View) -> some View {
        return label()
            .foregroundStyle(Theme.texto)
            .tag(destination)
            .listRowBackground(
                RoundedRectangle(cornerRadius: Radius.botao)
                    .fill(selection == destination ? Theme.superficieAtiva : .clear)
                    .padding(.horizontal, Spacing.sm)
            )
            .listRowSeparator(.hidden)
    }
}

/// Esmaecimento acima da barra da cota: a cor da lateral cobrindo a lista numa curva suave (não linear).
struct SidebarFade: View {
    /// Altura da faixa de esmaecimento do rodapé: cerca de um item e meio.
    static let height: CGFloat = 44
    /// Faixa do topo, mais curta: com a lista parada ela não pode cobrir a Mesa.
    static let topHeight: CGFloat = 16
    var height: CGFloat = SidebarFade.height

    var body: some View {
        // Paradas de uma curva ease-in: cobre devagar no começo e rápido só no último terço, sem virar degrau.
        LinearGradient(stops: [
            .init(color: Theme.superficie.opacity(0), location: 0),
            .init(color: Theme.superficie.opacity(0.06), location: 0.2),
            .init(color: Theme.superficie.opacity(0.2), location: 0.4),
            .init(color: Theme.superficie.opacity(0.42), location: 0.6),
            .init(color: Theme.superficie.opacity(0.7), location: 0.8),
            .init(color: Theme.superficie.opacity(0.92), location: 0.95),
            .init(color: Theme.superficie, location: 1),
        ], startPoint: .top, endPoint: .bottom)
        .frame(height: height)
    }
}

/// Repositório na lateral: o nome e, embaixo, a branch e quantos arquivos alterados.
struct RepositoryRow: View {
    let summary: RepositorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(summary.repository.name).typography(.corpo).lineLimit(1).truncationMode(.middle)
            if let branch = summary.branch {
                MonoLabel(summary.changedFiles > 0 ? "\(branch) · \(summary.changedFiles) alterados" : branch)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.repository.name), branch \(summary.branch ?? "desconhecida"), \(summary.changedFiles) alterados")
    }
}
