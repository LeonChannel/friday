// Resumo: Prova que o destino da janela é guardado e lido de volta, e que texto estranho cai na Mesa.
// Tags: interface, testes

import FridayFeatures
import Testing

struct DestinationTests {
    @Test(arguments: [Destination.desk, .yourTurn, .subject(3), .project(42)])
    func roundTrips(destination: Destination) {
        #expect(Destination(storageKey: destination.storageKey) == destination)
    }

    @Test(arguments: ["", "assunto:", "assunto:x", "outra:1", "projeto"])
    func rejectsUnknownText(text: String) {
        #expect(Destination(storageKey: text) == nil)
    }
}
