// Resumo: Prova as regras de caminho e nome de projeto.
// Tags: projetos, testes

import FridayDomain
import Testing

struct ProjectTests {
    @Test func normalizesTrailingSlashAndDotSegments() {
        #expect(Project.normalizedPath("/tmp/a/b/") == Project.normalizedPath("/tmp/a/b"))
        #expect(Project.normalizedPath("/tmp/a/x/../b") == Project.normalizedPath("/tmp/a/b"))
    }

    @Test func defaultNameIsLastPathComponent() {
        #expect(Project.defaultName(forPath: "/Users/exemplo/Projetos/friday") == "friday")
    }
}
