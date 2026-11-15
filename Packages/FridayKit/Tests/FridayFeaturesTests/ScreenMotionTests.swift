// Resumo: Prova o movimento entre telas: mergulho e subida pela hierarquia, sentido do deslize entre projetos e da rolagem do conteúdo pela ordem da lateral.
// Tags: interface, testes

import FridayDomain
import SwiftUI
import Testing
@testable import FridayFeatures

struct ScreenMotionTests {
    @Test func projectMoveFollowsHierarchy() {
        #expect(ProjectMove.between(from: 0, to: 3) == .dive)
        #expect(ProjectMove.between(from: 3, to: 0) == .surface)
        #expect(ProjectMove.between(from: 2, to: 5) == .lateral(forward: true))
        #expect(ProjectMove.between(from: 5, to: 2) == .lateral(forward: false))
    }

    @Test func contentScrollsInSidebarOrder() {
        let subjects: [Int64] = [9, 4]
        let folders = ["/p/a", "/p/b"]
        func rank(_ d: Destination) -> Int { SidebarOrder.rank(of: d, subjects: subjects, projectPath: "/p", folders: folders) }
        let order: [Destination] = [.desk, .yourTurn, .memory, .backlog, .bugs, .subject(9), .subject(4), .subject(77), .folder("/p"), .folder("/p/a"), .folder("/p/b")]
        #expect(order.map(rank) == order.map(rank).sorted())
        #expect(Set(order.map(rank)).count == order.count)
        #expect(SidebarOrder.entryEdge(from: rank(.desk), to: rank(.memory)) == .bottom)
        #expect(SidebarOrder.entryEdge(from: rank(.folder("/p/b")), to: rank(.yourTurn)) == .top)
    }
}
