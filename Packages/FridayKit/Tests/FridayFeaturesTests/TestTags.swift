// Resumo: Tags de teste compartilhadas deste módulo, declaradas num lugar só para não colidir.
// Tags: testes

import Testing

extension Tag {
    /// Teste que usa recurso real do sistema (processo, disco, git, FSEvents).
    @Tag static var integration: Self
}
