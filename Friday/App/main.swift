// Resumo: Início do processo: o mesmo executável serve de app e, com --friday-cli, de comando `friday` para os agentes.
// Tags: composicao

import FridayCLI

let arguments = CommandLine.arguments
if arguments.count > 1, arguments[1] == "--friday-cli" {
    FridayCommand.main(Array(arguments.dropFirst(2)))
}
FridayApp.main()
