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
# Decisão de desenho — casar contra o payload cru, sem parsear JSON:
# não há `jq` garantido no ambiente, e parsear JSON em bash com sed quebra
# em aspas escapadas. Casar o padrão contra o texto bruto pode gerar falso
# positivo (um comando que apenas MENCIONE "git add ."), mas o custo do
# falso positivo é uma mensagem pedindo staging cirúrgico, enquanto o custo
# do falso negativo é perda de trabalho. Falha fechado por construção.
#
# OPÇÕES GLOBAIS: `git -C /outro/repo clean -fdx` é válido e destrutivo. Uma
# versão anterior desta trava procurava o subcomando imediatamente após
# `git`, então TODAS as formas com opção global passavam batido — medido:
# `-C`, `-c` e `--git-dir` contornavam guard e os dois wrappers (achado do
# CodeRabbit no PR #12). O subcomando agora é procurado depois de zero ou
# mais opções globais.
#
# Custo real já pago: durante a implementação desta trava, em 2026-08-11, um
# `git clean -fdx` rodado para TESTAR a versão então quebrada do wrapper
# apagou os arquivos não rastreados do repositório de trabalho — inclusive
# uma versão anterior deste mesmo arquivo. Teste comando destrutivo em
# diretório descartável, nunca no repositório em uso.
# ==============================================================================

PAYLOAD=$(cat)

# Opções globais do git aceitas ANTES do subcomando. As que consomem valor
# aparecem com o valor; as booleanas, sozinhas.
G='(-[Cc][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|exec-path|config-env)[=[:space:]][^[:space:]]+|--(paginate|no-pager|bare|literal-pathspecs|glob-pathspecs|icase-pathspecs|noglob-pathspecs|no-optional-locks|no-replace-objects)|-p)'
# Prefixo: a palavra `git` seguida de zero ou mais opções globais.
PRE="(^|[^A-Za-z0-9_-])git([[:space:]]+$G)*[[:space:]]+"

bloquear() {
  echo "======================================================================" >&2
  echo " [BLOQUEADO — T-GIT-GUARD] $1" >&2
  echo "" >&2
  echo " $2" >&2
  echo "======================================================================" >&2
  exit 2
}

casa() { echo "$PAYLOAD" | grep -qE "$1"; }

# ── Staging em massa ─────────────────────────────────────────────────────────
# Cobre: git add . / -A / --all / * / -u / :/
# `-u` entra porque faz stage de todos os rastreados — é staging em massa
# ainda que não pareça (lacuna encontrada na revisão do PR #12).
if casa "${PRE}add[[:space:]]+((-[A-Za-z]*[Au])|--all|\\.|\\*|:/)([[:space:]]|\\\\\"|\"|$)"; then
  bloquear "Staging em massa proibido." \
    "Use staging cirurgico, um arquivo por vez: git add caminho/do/arquivo.ext"
fi

# ── Descarte destrutivo de trabalho ──────────────────────────────────────────
if casa "${PRE}reset[^|;&]*--hard"; then
  bloquear "'git reset --hard' descarta trabalho nao comitado." \
    "Prefira 'git stash' ou reverta arquivos especificos."
fi

# Qualquer aglomerado de flags curtas contendo 'f' (-f, -fd, -fdx, -xdf...)
# ou --force. A revisao do PR #12 mostrou que casar exatamente '-fd'/'-f'
# deixava passar justamente 'git clean -fdx', a forma mais destrutiva.
# `-n`/`--dry-run` NAO desarma: 'git clean -nf' ainda apaga.
if casa "${PRE}clean[^|;&]*([[:space:]]-[A-Za-z]*f|--force)"; then
  bloquear "'git clean' com -f apaga arquivos nao rastreados." \
    "Rode 'git clean -n' primeiro para ver o que seria apagado, e remova o que precisar manualmente."
fi

if casa "${PRE}(restore|checkout)[[:space:]]+[^|;&]*(\\.|:/)([[:space:]]|\\\\\"|\"|$)"; then
  bloquear "Descarte em massa de alteracoes no working tree." \
    "Restaure arquivos especificos: git restore caminho/do/arquivo.ext"
fi

# ── Reescrita de historico publicado ─────────────────────────────────────────
# Nao estava coberto pelo wrapper original (lacuna da revisao do PR #12).
if casa "${PRE}push[^|;&]*([[:space:]]-[A-Za-z]*f|--force)"; then
  bloquear "Force-push reescreve historico ja publicado." \
    "Se for mesmo necessario, o autor humano deve autorizar e executar manualmente."
fi

exit 0
