// Resumo: Rodapé da lateral com a cota do Claude: uso das janelas de 5 horas e 7 dias, quanto falta para renovar e de quando é a leitura.
// Tags: cota, interface

import FridayDomain
import SwiftUI

/// Cota no rodapé da lateral. Número medido, então ganha barra (trilho `superficieAtiva`, preenchimento `texto`).
struct QuotaBar: View {
    let quota: UsageQuota?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Theme.linha).frame(height: 1) }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let current = quota?.current(at: now)
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                MonoLabel("Cota", kind: .secao)
                Spacer(minLength: 0)
                if let quota {
                    MonoLabel("lida \(quota.capturedAt.formatted(.relative(presentation: .named, unitsStyle: .narrow)))").lineLimit(1)
                }
            }
            if let current, current.fiveHour != nil || current.sevenDay != nil {
                if let window = current.fiveHour { QuotaMeter(name: "5 horas", window: window, now: now) }
                if let window = current.sevenDay { QuotaMeter(name: "7 dias", window: window, now: now) }
            } else {
                Text(quota == nil
                     ? "Aparece depois da primeira resposta do Claude numa sessão aberta aqui."
                     : "A janela renovou. A leitura nova chega na próxima resposta do Claude.")
                    .typography(.secundario)
                    .foregroundStyle(Theme.textoSecundario)
                    // Nada de fixedSize: medida com largura quase zero, a frase pedia altura de uma letra por linha e esticava a janela.
                    .lineLimit(3)
            }
        }
    }
}

/// Uma janela da cota: nome, porcentagem, barra e quando renova.
struct QuotaMeter: View {
    let name: String
    let window: QuotaWindow
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(name).typography(.secundario).foregroundStyle(Theme.texto)
                Text("\(Int(window.usedPercentage.rounded()))%").typography(.metadado).foregroundStyle(Theme.texto)
                Spacer(minLength: 0)
                MonoLabel("renova em \(window.timeToReset(from: now))").lineLimit(1)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.superficieAtiva)
                    Capsule().fill(Theme.texto).frame(width: max(proxy.size.width * window.fraction, window.fraction > 0 ? 3 : 0))
                }
            }
            .frame(height: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cota de \(name): \(Int(window.usedPercentage.rounded())) por cento usada, renova em \(window.timeToReset(from: now))")
    }
}

#Preview("Cota, escuro") {
    let now = Date()
    VStack(spacing: 0) {
        QuotaBar(quota: UsageQuota(
            fiveHour: QuotaWindow(usedPercentage: 26, resetsAt: now.addingTimeInterval(7_980)),
            sevenDay: QuotaWindow(usedPercentage: 39, resetsAt: now.addingTimeInterval(97_200)),
            capturedAt: now.addingTimeInterval(-120)
        ))
        QuotaBar(quota: nil)
    }
    .frame(width: 260)
    .background(Theme.superficie)
    .preferredColorScheme(.dark)
}

#Preview("Cota, claro") {
    QuotaBar(quota: UsageQuota(fiveHour: QuotaWindow(usedPercentage: 81, resetsAt: .now.addingTimeInterval(1_500)), sevenDay: nil, capturedAt: .now))
        .frame(width: 260)
        .background(Theme.superficie)
        .preferredColorScheme(.light)
}
