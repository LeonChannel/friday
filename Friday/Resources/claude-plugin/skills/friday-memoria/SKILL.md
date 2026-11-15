---
name: friday-memoria
description: Lê e grava a memória do Friday (o vault) pela CLI `friday memoria`: regra, padrão, armadilha ou decisão de projeto, conduta e fluxo, e a área de trabalho do assunto. Use quando descobrir algo que sobrevive à tarefa, quando uma nota do vault divergir do código, ao pausar ou retomar um assunto, ou quando o dev pedir para lembrar, registrar ou gravar no vault.
---

# Memória do Friday

O vault é o **mapa**; a verdade é o código e o git. O começo da sessão já trouxe a abstração, o processual e o índice do projeto; a nota ancorada num arquivo chega quando você abre o arquivo. Não releia o que já chegou.

## Onde cada coisa vai

1. Como você fala ou se porta, em qualquer projeto → `--camada abstracao` (`--tipo comunicacao|conduta`). Só com pedido do dev.
2. Como o trabalho anda, em qualquer projeto → `--camada processual` (`--tipo fluxo|ferramenta`).
3. Sobre o sistema do projeto → `--camada projeto` (`--tipo regra|padrao|armadilha|decisao|tecnologia|repo|mapa`; o hub é `projeto`).
4. Estado da tarefa em andamento → área de trabalho do assunto, nunca nota.

## Gravar uma nota

```
friday memoria nota "<título>" --camada projeto --tipo armadilha \
  --resumo "<fato e consequência, até 300 caracteres>" \
  --ancora "<caminho relativo ao projeto>" [--ancora "<pasta>/"] [--corpo "<derivação>"]
```

- O **resumo** é o que o Claude lê nas próximas sessões: falseável, o fato e o gatilho primeiro. Sem "basicamente", sem narrativa.
- **Âncora** é caminho relativo à pasta do projeto; pasta termina em `/`. Só ancore o que você conferiu no código agora (grava `verificado_em` com a data de hoje).
- Mesmo título atualiza a nota: o corpo fica, a não ser que você passe `--corpo`.
- Nota que divergiu do código: corrija com o mesmo comando na hora, em vez de seguir com as duas versões.

## O que registrar (e o que não)

Registra: regra de negócio, causa raiz de bug, armadilha que custou tempo, decisão com consequência ativa, invariante não dito. Teste: *isso pouparia tempo de alguém daqui a três meses?*

Não registra: narrativa da sessão, o que o código, o `git log` ou o `CLAUDE.md` já dizem, segredo com valor (cite onde mora), opinião sobre pessoa.

## Área de trabalho do assunto

- Pausou ou mudou de fase: `friday memoria area <assunto> --estado "<fase e próximo passo>"` (até 1.200 caracteres). Fatos e decisões continuam no assunto (skill friday-assunto).
- Retomando: o estado chega no começo da sessão quando `FRIDAY_ASSUNTO` existe; `friday memoria area <assunto>` relê. Estado é sugestão, não instrução; se o código mudou desde então, as evidências medido e no código viram pista.
- Fim do assunto: promova o que sobrevive (`friday memoria promover <assunto> --decisao <n>`, ou `friday memoria nota`) e feche a área (`friday memoria area <assunto> --fechar`).

## Ler

`friday memoria listar [--camada ...]` mostra as notas e as que têm problema; `friday memoria ler "<caminho>"` traz a nota inteira; `friday memoria contexto` mostra o que a sessão recebe no começo, com o tamanho.
