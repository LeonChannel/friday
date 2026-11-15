// Resumo: Aba Jornadas dos Ajustes: para cada tipo de atividade, o prompt de como conduzir, as etapas da lousa e as skills instaladas que a sessão usa.
// Tags: configuracoes, jornadas, interface

import FridayDomain
import SwiftUI

/// Configuração das jornadas. Cada mudança grava na hora e vale para os próximos assuntos.
struct JourneysSettingsView: View {
    @Bindable var settings: AppSettings
    let catalog: (any SkillCataloging)?
    @State private var kind: ActivityKind = .error
    @State private var installed: [InstalledSkill] = []

    var body: some View {
        HStack(spacing: 0) {
            List(ActivityKind.allCases, selection: Binding(get: { kind }, set: { if let new = $0 { kind = new } })) { kind in
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.displayName)
                    Text(settings.journey(for: kind).isEmpty ? "vazia" : "configurada")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .tag(kind)
            }
            .listStyle(.sidebar)
            .frame(width: 170)
            Divider()
            JourneyEditor(journey: binding(for: kind), installed: installed)
                .id(kind)
        }
        .frame(width: 780, height: 620)
        .task { installed = catalog?.installedSkills() ?? [] }
    }

    private func binding(for kind: ActivityKind) -> Binding<Journey> {
        Binding(get: { settings.journey(for: kind) }, set: { settings.setJourney($0) })
    }
}

/// Formulário de uma jornada: prompt, etapas e skills.
private struct JourneyEditor: View {
    @Binding var journey: Journey
    let installed: [InstalledSkill]
    @State private var newStage = ""
    @State private var manualSkill = ""
    @State private var filter = ""

    var body: some View {
        Form {
            Section {
                TextEditor(text: $journey.prompt)
                    .font(.body)
                    .frame(minHeight: 140)
                    .onChange(of: journey.prompt) { _, new in
                        if new.count > Journey.promptLimit { journey.prompt = String(new.prefix(Journey.promptLimit)) }
                    }
                Text("\(journey.prompt.count) de \(Journey.promptLimit) caracteres. Vai como primeira mensagem do Claude, junto com o pedido e as etapas.")
                    .font(.callout).foregroundStyle(.secondary)
            } header: {
                Text("\(journey.kind.displayName): como o Claude conduz")
            }

            Section {
                ForEach(Array(journey.stages.enumerated()), id: \.offset) { index, _ in
                    HStack {
                        Text("\(index + 1)").font(.callout.monospaced()).foregroundStyle(.secondary)
                        TextField("Etapa", text: stageBinding(index))
                        Button("Subir", systemImage: "chevron.up") { move(index, by: -1) }.disabled(index == 0)
                        Button("Descer", systemImage: "chevron.down") { move(index, by: 1) }.disabled(index == journey.stages.count - 1)
                        Button("Remover", systemImage: "minus.circle") { journey.stages.remove(at: index) }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                }
                HStack {
                    TextField("Nova etapa (ex.: Reproduzir)", text: $newStage).onSubmit(addStage)
                    Button("Adicionar", action: addStage)
                        .disabled(newStage.trimmingCharacters(in: .whitespaces).isEmpty || journey.stages.count >= Journey.stageLimit)
                }
            } header: {
                Text("Etapas da lousa")
            } footer: {
                Text("Até \(Journey.stageLimit) etapas de \(SubjectLimits.stageName) caracteres. Viram o trilho de progresso do assunto; o Claude marca cada uma com `friday etapa`.")
                    .font(.callout).foregroundStyle(.secondary)
            }

            Section {
                if journey.skills.isEmpty {
                    Text("Nenhuma skill escolhida.").foregroundStyle(.secondary)
                }
                ForEach(journey.skills, id: \.self) { name in
                    HStack {
                        Text(name).font(.callout.monospaced())
                        if !installed.isEmpty && !installed.contains(where: { $0.name == name }) {
                            Text("não encontrada").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Remover", systemImage: "minus.circle") { journey.skills.removeAll { $0 == name } }
                            .labelStyle(.iconOnly).buttonStyle(.borderless)
                    }
                }
                HStack {
                    TextField("Nome à mão (skill ou plugin:skill)", text: $manualSkill).onSubmit(addManual)
                    Button("Adicionar", action: addManual).disabled(manualSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Skills desta jornada")
            }

            Section {
                TextField("Filtrar", text: $filter)
                if installed.isEmpty {
                    Text("Nenhuma skill encontrada em ~/.claude/skills nem nos plugins instalados.").foregroundStyle(.secondary)
                }
                ForEach(filtered) { skill in
                    Toggle(isOn: skillBinding(skill.name)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name).font(.callout.monospaced())
                            if !skill.summary.isEmpty {
                                Text(skill.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            } header: {
                Text("Instaladas (\(installed.count))")
            } footer: {
                Text("Lidas de ~/.claude só para listar; o Friday não altera a configuração do Claude.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var filtered: [InstalledSkill] {
        let term = filter.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return installed }
        return installed.filter { $0.name.localizedCaseInsensitiveContains(term) || $0.summary.localizedCaseInsensitiveContains(term) }
    }

    private func stageBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { journey.stages.indices.contains(index) ? journey.stages[index] : "" },
            set: { if journey.stages.indices.contains(index) { journey.stages[index] = String($0.prefix(SubjectLimits.stageName)) } }
        )
    }

    private func skillBinding(_ name: String) -> Binding<Bool> {
        Binding(
            get: { journey.skills.contains(name) },
            set: { on in
                if on { if !journey.skills.contains(name) { journey.skills.append(name) } } else { journey.skills.removeAll { $0 == name } }
            }
        )
    }

    private func move(_ index: Int, by offset: Int) {
        let target = index + offset
        guard journey.stages.indices.contains(target) else { return }
        journey.stages.swapAt(index, target)
    }

    private func addStage() {
        let name = String(newStage.trimmingCharacters(in: .whitespaces).prefix(SubjectLimits.stageName))
        guard !name.isEmpty, journey.stages.count < Journey.stageLimit else { return }
        journey.stages.append(name)
        newStage = ""
    }

    private func addManual() {
        let name = manualSkill.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if !journey.skills.contains(name) { journey.skills.append(name) }
        manualSkill = ""
    }
}

#if DEBUG
private struct PreviewCatalog: SkillCataloging {
    func installedSkills() -> [InstalledSkill] {
        [
            InstalledSkill(name: "investigar", summary: "Investiga um erro a partir do log.", origin: "usuário"),
            InstalledSkill(name: "plugin:revisar", summary: "Revisa o diff antes do commit.", origin: "plugin"),
        ]
    }
}

#Preview("Jornadas") {
    JourneysSettingsView(settings: AppSettings(defaults: UserDefaults(suiteName: "friday.preview.journeys") ?? .standard), catalog: PreviewCatalog())
}
#endif
