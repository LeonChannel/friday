---
name: friday-backlog
description: Anota no backlog do Friday, pela CLI `friday bug` e `friday item`, todo bug, falha, risco ou dívida que você encontrar no projeto e que não é a tarefa atual, sem interromper o dev. Também cria e organiza épicos, histórias, tasks e subtasks, move itens no quadro e registra o card externo (Jira, Azure DevOps) para onde o item foi levado. Use sempre que achar algo errado fora do escopo, ou quando o dev citar um código como FRI-12.
---

# Backlog do Friday

O Friday guarda o que você acha de errado no projeto para o dev não perder o flow nem caçar o bug no histórico da conversa. O dev tria depois, no quadro de bugs do app.

## Achou um bug fora da tarefa? Anote e siga

Não pare, não corrija sem pedido e não comente no chat. Uma linha e volte ao trabalho:

```
friday bug "<título curto: o defeito, não a solução>" \
  --onde "arquivo:linha" --grau codigo|medido|inferido \
  --detalhe "o que acontece, como reproduzir, o efeito" [--prioridade baixa|media|alta|critica]
```

- **Título** até 120 caracteres, o sintoma: "Token de sessão aparece no log de erro do login".
- **`--onde`**: caminho relativo ao projeto com linha, ou tela, ou comando. Sempre que souber.
- **`--grau`**: `medido` só se você rodou e viu; `codigo` se leu no código; `inferido` se é dedução. Na dúvida, `inferido`.
- **`--detalhe`** até 2.000 caracteres: passos, entrada que dispara, efeito. Sem narrativa da sessão.
- **`--prioridade`**: `critica` para perda de dado, segurança ou produção fora; `alta` para quebra de fluxo principal; o resto é `media` (padrão) ou `baixa`.
- O mesmo título com bug ainda aberto não duplica: a CLI devolve o código que já existe.
- O que você anota entra em **Novo** (triagem). Quem move para "A fazer" é o dev.

Anote: bug real, caso de borda sem tratamento, risco de segurança, teste que passa pelo motivo errado, dívida que vai morder. Não anote: estilo, preferência pessoal, o que você já vai corrigir na tarefa atual.

## Hierarquia

Épico → História → Task → Subtask. Bug fica solto (no quadro) ou dentro de um épico ou história. Subtask sempre tem pai (história, task ou bug).

```
friday item novo epico "<título>"
friday item novo historia "<título>" --pai FRI-1
friday item novo task "<título>" --pai FRI-2
friday item novo subtask "<título>" --pai FRI-3
friday item pai FRI-7 FRI-1        # pendura FRI-7 dentro de FRI-1 (nenhum = raiz)
```

Crie épicos e histórias só quando o dev pedir. Bug você anota sozinho.

## Ler e mover

```
friday item listar [--tipo bug] [--estado novo] [--fechados]
friday item ler FRI-12
friday item mover FRI-12 novo|a-fazer|fazendo|revisao|feito|descartado
friday item editar FRI-12 [--titulo ...] [--detalhe ...] [--onde ...] [--grau ...] [--prioridade ...]
```

Começou a corrigir um item a pedido do dev: mova para `fazendo`; terminou: `revisao`. Quem fecha (`feito`) é o dev, a não ser que ele peça.

## Levar para a sprint

O backlog do Friday não suja o board da empresa. Quando o dev levar um item para a sprint (Jira, Azure DevOps), registre o card:

```
friday item externo FRI-12 "AB#68134"      # ou o link do card; nenhum desfaz
```

## Onde fica

Banco do Friday (fonte) e um espelho em markdown no vault: `Projetos/<projeto>/Backlog/FRI-12.md` e o índice `00 - Backlog.md`. O espelho é só leitura: edite pelo app ou pela CLI.
