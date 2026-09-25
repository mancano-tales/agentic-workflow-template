#!/usr/bin/env bash
# ==============================================================================
# guard-git-command.sh — Trava PreToolUse: bloqueia comandos git destrutivos
# ==============================================================================
#
# Por que este arquivo existe: `tools/git-wrapper.sh|ps1` só protege quem
# escolhe chamar o wrapper. Um agente chama `git` direto, então o wrapper
# nunca era exercido — era trava sem interposição. Este guard roda como hook
# PreToolUse do Claude Code, ANTES do Bash executar, e por isso é o ponto em
# que a proibição deixa de ser pedido e passa a ser impedimento.
#
# Contrato do hook: recebe o payload JSON da chamada em stdin; sair com
# código 2 bloqueia a execução e devolve o stderr ao agente.
#
# A ANÁLISE vive em `guard-git-command.py`: ela tokeniza respeitando aspas e
# continuação de linha e identifica o subcomando depois das opções globais.
# Duas versões anteriores baseadas em regex foram descartadas — a primeira
# não via opção global nenhuma (`git -C /outro clean -fdx` passava), e a
# segunda enumerava as globais numa lista, o que deixava passar `-P`,
# `--no-advice`, `--no-lazy-fetch` e caminho citado com espaços. Enumerar
# opção de uma ferramenta que evolui é corrida perdida; tokenizar não é.
#
# Custo real já pago: durante a implementação desta trava, em 2026-08-11, um
# `git clean -fdx` rodado para TESTAR a versão então quebrada do wrapper
# apagou os arquivos não rastreados do repositório de trabalho — inclusive
# uma versão anterior deste mesmo arquivo. Teste comando destrutivo em
# diretório descartável, nunca no repositório em uso.
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$DIR/guard-git-command.py"

for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1; then
    exec "$cand" "$PY"
  fi
done

# ── Sem Python: fallback conservador ─────────────────────────────────────────
# Não dá para tokenizar com segurança aqui. Em vez de deixar passar (falha
# aberta), bloqueia qualquer invocação de git que contenha um verbo destrutivo
# em qualquer posição. É deliberadamente grosseiro: pode gerar falso positivo,
# mas o custo do falso positivo é uma mensagem, e o do falso negativo é perda
# de trabalho.
PAYLOAD=$(cat)

if echo "$PAYLOAD" | grep -q "git"; then
  if echo "$PAYLOAD" | grep -qE '(clean[^|;&]*(-[A-Za-z]*f|--force)|reset[^|;&]*--hard|push[^|;&]*(-[A-Za-z]*f|--force)|add[[:space:]]+[^|;&]*(-[A-Za-z]*[Au]|--all|--update|--renormalize|\.|\*|:/)|(restore|checkout)[[:space:]]+[^|;&]*(\.|:/)([[:space:]]|"|$))'; then
    echo "======================================================================" >&2
    echo " [BLOQUEADO — T-GIT-GUARD] Comando git potencialmente destrutivo." >&2
    echo "" >&2
    echo " Python nao esta disponivel, entao a analise precisa desta trava nao" >&2
    echo " pode rodar e ela bloqueia por precaucao (falha fechada). Instale o" >&2
    echo " Python 3 para a checagem exata, ou execute a acao manualmente apos" >&2
    echo " conferir o que ela afeta." >&2
    echo "======================================================================" >&2
    exit 2
  fi
fi

exit 0
