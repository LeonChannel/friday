// Resumo: Contrato de onde os itens do backlog ficam guardados: lista ao vivo por projeto, busca pelo número, criação numerada e alteração atômica.
// Tags: backlog, persistencia

import Foundation

/// Onde os itens do backlog ficam guardados. Produção usa o banco; teste usa banco em memória.
public protocol BacklogRepository: Sendable {
    /// Itens do projeto em ordem de número, agora e a cada mudança (inclusive de outro processo).
    func observeAll(projectID: Int64) -> AsyncThrowingStream<[BacklogItem], any Error>
    /// Itens do projeto agora, em ordem de número.
    func all(projectID: Int64) throws -> [BacklogItem]
    func item(projectID: Int64, number: Int) throws -> BacklogItem?
    func item(id: Int64) throws -> BacklogItem?
    /// Grava com o próximo número livre do projeto, conferindo o pai na mesma transação.
    @discardableResult func insert(_ item: BacklogItem) throws -> BacklogItem
    /// Lê, altera e grava numa transação só. O pai, se mudou, é conferido antes de gravar.
    @discardableResult func update(id: Int64, _ change: @Sendable (inout BacklogItem) throws -> Void) throws -> BacklogItem
    /// Apaga o item; recusa se houver itens dentro dele.
    func delete(id: Int64) throws
}

/// Projeções do backlog usadas pela tela e pela CLI, sem IO.
public enum BacklogProjection {
    /// Bug aberto com o mesmo título (sem diferenciar maiúsculas e acento): evita o Claude registrar o mesmo achado duas vezes.
    public static func openDuplicate(of title: String, kind: BacklogKind, in items: [BacklogItem]) -> BacklogItem? {
        let key = normalized(title)
        return items.first { $0.kind == kind && !$0.status.isClosed && normalized($0.title) == key }
    }

    /// Itens de cada coluna do quadro, na ordem das colunas: prioridade maior primeiro, depois o mais antigo.
    public static func columns(_ items: [BacklogItem], statuses: [BacklogStatus]) -> [(status: BacklogStatus, items: [BacklogItem])] {
        statuses.map { status in
            let column = items.filter { $0.status == status }.sorted {
                $0.priority != $1.priority ? $0.priority > $1.priority : $0.number < $1.number
            }
            return (status, column)
        }
    }

    /// Filhos diretos de cada item (e os da raiz em `nil`), em ordem de número.
    public static func children(_ items: [BacklogItem]) -> [Int64?: [BacklogItem]] {
        let ids = Set(items.compactMap(\.id))
        // Pai que sumiu (apagado em outro processo) não esconde o filho: ele sobe para a raiz.
        return Dictionary(grouping: items.sorted { $0.number < $1.number }) { item in
            item.parentID.flatMap { ids.contains($0) ? $0 : nil }
        }
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
