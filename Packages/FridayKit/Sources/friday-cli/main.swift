// Resumo: Executável `friday` do pacote; só repassa os argumentos para o FridayCommand.
// Tags: assuntos

import FridayCLI

FridayCommand.main(Array(CommandLine.arguments.dropFirst()))
