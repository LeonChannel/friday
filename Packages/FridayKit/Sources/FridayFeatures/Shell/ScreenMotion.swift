// Resumo: Movimento entre telas pela hierarquia: mergulho ao entrar num projeto, subida ao voltar à seleção, deslize lateral entre projetos e rolagem vertical do conteúdo entre telas do mesmo projeto.
// Tags: interface, visual

import FridayDomain
import SwiftUI

/// Como a janela troca de projeto. Calculado só dos ids, antes de animar, para a tela que sai usar a animação certa.
public enum ProjectMove: Equatable, Sendable {
    /// Seleção → projeto: desce um nível.
    case dive
    /// Projeto → seleção: sobe um nível.
    case surface
    /// Projeto → outro projeto, como a troca de mesa do Mac. `forward` vai para a direita.
    case lateral(forward: Bool)

    /// Movimento entre o projeto exibido (`from`) e o novo (`to`); 0 é a seleção de projetos.
    public static func between(from: Int, to: Int) -> ProjectMove {
        if from == 0 { return .dive }
        if to == 0 { return .surface }
        return .lateral(forward: to > from)
    }

    /// Curva: o mergulho tem um pouco mais de peso; o deslize lateral é firme como o do sistema.
    func animation(reduceMotion: Bool) -> Animation {
        if reduceMotion { return .easeInOut(duration: 0.2) }
        switch self {
        case .dive, .surface: return .spring(duration: 0.55, bounce: 0)
        case .lateral: return .spring(duration: 0.5, bounce: 0)
        }
    }

    /// O movimento desenhado na tela.
    func motion(reduceMotion: Bool) -> ScreenMotion {
        if reduceMotion { return .fade }
        switch self {
        case .dive: return .zoomIn
        case .surface: return .zoomOut
        case .lateral(let forward): return .slide(forward ? .trailing : .leading)
        }
    }
}

/// Como duas telas trocam de lugar. As duas ficam vivas durante a troca e o efeito é aplicado a mão pelo progresso,
/// porque a transição de saída do SwiftUI não move telas feitas de view do AppKit (NavigationSplitView, terminal).
enum ScreenMotion: Equatable, Sendable {
    /// Entrar num nível abaixo: a tela de fora cresce e some por cima; a de dentro vem de trás.
    case zoomIn
    /// Voltar um nível: a de dentro recua e some; a de fora volta da frente.
    case zoomOut
    /// Mesmo nível: a nova entra pelo lado `edge` e empurra a antiga para o lado oposto.
    case slide(Edge)
    /// "Reduzir movimento": só troca de opacidade.
    case fade

    /// A tela que sai fica por cima? Só quando é ela a "de fora" que se atravessa (mergulho).
    var outgoingOnTop: Bool { self == .zoomIn }

    /// Escala, deslocamento e opacidade de uma tela no progresso `p` (0 a 1) da troca.
    func effect(isIncoming: Bool, progress p: Double, size: CGSize) -> (scale: Double, offset: CGSize, opacity: Double) {
        switch self {
        case .fade:
            return (1, .zero, isIncoming ? p : 1 - p)
        case .zoomIn:
            return isIncoming ? (0.94 + 0.06 * p, .zero, p) : (1 + 0.08 * p, .zero, 1 - p)
        case .zoomOut:
            return isIncoming ? (1.08 - 0.08 * p, .zero, p) : (1 - 0.06 * p, .zero, 1 - p)
        case .slide(let edge):
            let unit: CGSize = switch edge {
            case .trailing: CGSize(width: size.width, height: 0)
            case .leading: CGSize(width: -size.width, height: 0)
            case .bottom: CGSize(width: 0, height: size.height)
            case .top: CGSize(width: 0, height: -size.height)
            }
            let k = isIncoming ? 1 - p : -p
            return (1, CGSize(width: unit.width * k, height: unit.height * k), 1)
        }
    }
}

/// Mostra a tela de `key`. Quando `key` muda (venha de onde vier: clique, menu, atalho), pergunta a `movement` como ir
/// da antiga para a nova, mantém as duas vivas e anima até a nova assumir.
struct MotionStack<Key: Hashable, Content: View>: View {
    let key: Key
    /// Recorta à própria área. Só a pilha de dentro do workspace: na de fora (a janela inteira), qualquer recorte tira da
    /// NavigationSplitView o espaço da barra de título e a tela sobe por baixo dela; lá o que passa da borda cai fora da janela.
    var clips = false
    let movement: (_ from: Key, _ to: Key) -> (ScreenMotion, Animation)
    @ViewBuilder let content: (Key) -> Content

    @State private var shown: Key?
    @State private var outgoing: Key?
    @State private var progress: Double = 1
    @State private var motion: ScreenMotion = .fade

    /// Tamanho da área, lido sem `GeometryReader`: ele posiciona o conteúdo ignorando a barra de título e jogava a tela para cima.
    @State private var size: CGSize = .zero

    var body: some View {
        let current = shown ?? key
        ZStack {
            ForEach([outgoing, current].compactMap { $0 }, id: \.self) { layer in
                let incoming = layer == current
                let e = motion.effect(isIncoming: incoming, progress: progress, size: size)
                content(layer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(e.scale)
                    .offset(e.offset)
                    .opacity(e.opacity)
                    .zIndex(incoming == motion.outgoingOnTop ? 0 : 1)
                    .allowsHitTesting(incoming)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ClipIf(clips))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: key) { old, new in start(from: shown ?? old, to: new) }
    }

    private func start(from old: Key, to new: Key) {
        guard old != new else { return }
        let (motion, animation) = movement(old, new)
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            self.motion = motion
            outgoing = old
            shown = new
            progress = 0
        }
        // Próximo ciclo: a nova tela já está no ponto de partida; agora anda até o fim.
        DispatchQueue.main.async {
            withAnimation(animation) { progress = 1 } completion: {
                if shown == new { outgoing = nil }
            }
        }
    }
}

/// `.clipped()` opcional sem mudar a estrutura da view.
struct ClipIf: ViewModifier {
    let active: Bool
    init(_ active: Bool) { self.active = active }

    func body(content: Content) -> some View {
        if active { content.clipped() } else { content }
    }
}

/// Posição de um destino na lateral, de cima para baixo, para o conteúdo rolar no sentido certo.
enum SidebarOrder {
    /// `subjects` e `folders` na ordem em que a lateral mostra; o que não está na lista vai para o fim do seu grupo.
    static func rank(of destination: Destination, subjects: [Int64], projectPath: String, folders: [String]) -> Int {
        switch destination {
        case .desk: return 0
        case .yourTurn: return 1
        case .memory: return 2
        case .backlog: return 3
        case .bugs: return 4
        case .subject(let id): return 100 + (subjects.firstIndex(of: id) ?? subjects.count)
        case .folder(let path):
            if path == projectPath { return 10_000 }
            return 10_001 + (folders.firstIndex(of: path) ?? folders.count)
        }
    }

    /// Lado de onde o conteúdo novo entra: de baixo quando o destino está mais abaixo na lateral.
    static func entryEdge(from old: Int, to new: Int) -> Edge { new >= old ? .bottom : .top }
}
