---
name: friday-assunto
description: Registra no Friday o estado de um assunto (evidência, pergunta, decisão, frente) pela CLI `friday`. Use quando o dev e você estiverem investigando uma hipótese, um problema de arquitetura ou uma decisão de produto que o Friday acompanha, ou quando o dev citar um assunto pelo número.
---

# Assunto no Friday

O Friday guarda o **estado** do assunto, não a conversa. Escreva nele em frases curtas; o dev lê o resumo, não o que você disse no chat.

## Comece lendo

`friday assunto ler <id>` traz tudo em markdown compacto. `friday assunto listar` mostra os assuntos e de quem é a vez. Leia antes de escrever, para não repetir.

## Quando registrar

- **Evidência**: achou um fato que sustenta ou derruba algo. Sempre com fonte e grau.
  `friday evidencia <id> --grau medido|codigo|inferido --fonte "arquivo:linha ou comando" "<fato>"`
- **Pergunta**: surgiu algo que precisa de resposta. Se só o dev pode responder, use `--espera-voce` e dê opções com a consequência de cada.
  `friday pergunta <id> "<texto>" --opcao "A|o que acontece se A" --opcao "B|o que acontece se B" --espera-voce`
- **Decisão**: o dev decidiu (ou você decidiu algo dentro do que ele autorizou). Diga por quê e o que faria mudar de ideia. `--responde <n>` fecha a pergunta que ela respondeu.
  `friday decisao <id> "<decisão>" --porque "..." [--mudaria-se "..."] [--responde <n>]`
- **Frente**: você começou, bloqueou ou terminou um trabalho. Mesmo nome atualiza a frente.
  `friday frente <id> "<nome>" --criterio "como sei que acabou" --estado rodando|esperando-voce|concluida [--passo "..."]... [--feitos <n>]`
- **Alternativa** (opcional): comparar opções. `friday alternativa <id> "<nome>" --ganho ... --risco ... --esforco ... --reversivel ...`

## Graus: não infle

- `medido`: você rodou e viu o número ou resultado.
- `codigo`: você leu no código, sem executar.
- `inferido`: dedução sua. Na dúvida, é este.

Nunca marque `medido` o que você leu ou supôs. O dev decide pelo grau.

## Tetos (recusa com o tamanho)

Título 80 · intenção 300 · pergunta 240 · opção 60 · consequência 140 · evidência 200 · fonte 100 · decisão 200 · porquê 160 · critério 160 · passo 100. Texto acima volta com erro; encurte, não divida em vários.

## Vez

Pergunta com `--espera-voce` aberta ou frente `esperando-voce` passa a vez ao dev. Frente `rodando` é a sua vez. Mude o estado da frente assim que bloquear ou terminar.
