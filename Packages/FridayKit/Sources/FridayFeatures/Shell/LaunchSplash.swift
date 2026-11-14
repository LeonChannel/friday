// Resumo: Abertura do app: o logo se escreve (primeiro o seu traço, depois o do Claude), o nome aparece e a tela some; pula com clique ou tecla.
// Tags: visual, interface

import SwiftUI

/// Abertura curta (cerca de 1,3 s). Com "Reduzir movimento", só aparece e some.
struct LaunchSplash: View {
    let finished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var you: CGFloat = 0
    @State private var claude: CGFloat = 0
    @State private var nameVisible = false
    @State private var leaving = false
    @State private var done = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            FridayMark(size: 120, you: you, claude: claude)
            Text("friday")
                .typography(.marcaAbertura)
                .foregroundStyle(Theme.texto)
                .opacity(nameVisible ? 1 : 0)
                .offset(y: nameVisible || reduceMotion ? 0 : 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.fundo)
        .opacity(leaving ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress { _ in
            finish()
            return .handled
        }
        .task { await play() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Abrindo o Friday")
    }

    private func play() async {
        if reduceMotion {
            you = 1
            claude = 1
            nameVisible = true
            try? await Task.sleep(for: .milliseconds(500))
            finish()
            return
        }
        withAnimation(.easeInOut(duration: 0.45)) { you = 1 }
        try? await Task.sleep(for: .milliseconds(380))
        withAnimation(.easeOut(duration: 0.32)) { claude = 1 }
        try? await Task.sleep(for: .milliseconds(260))
        withAnimation(.smooth(duration: 0.25)) { nameVisible = true }
        try? await Task.sleep(for: .milliseconds(420))
        finish()
    }

    private func finish() {
        guard !done else { return }
        done = true
        withAnimation(.smooth(duration: 0.25)) { leaving = true } completion: { finished() }
    }
}

#Preview("Abertura, escuro") {
    LaunchSplash(finished: {}).frame(width: 900, height: 560).preferredColorScheme(.dark)
}

#Preview("Abertura, claro") {
    LaunchSplash(finished: {}).frame(width: 900, height: 560).preferredColorScheme(.light)
}
