#!/usr/bin/env bash
# ==============================================================================
# git-wrapper.sh — Interceptador CLI e Trava Anti-Destrutiva do Git (Bash)
# ==============================================================================
#
# Escopo: uso INTERATIVO por humanos que escolhem chamar o wrapper.
# Para agentes, a trava que de fato interpõe é o hook PreToolUse em
# `.claude/settings.json`, que chama `tools/guard-git-command.sh` antes do
# Bash executar — um agente chama `git` direto e nunca passaria por aqui.
# Os dois cobrem o mesmo conjunto de comandos; mantenha-os em sincronia.
# ==============================================================================

if [ $# -eq 0 ]; then
  exec git
fi

recusar() {
  echo "======================================================================"
  echo "[ERRO FATAL T-GIT-WRAPPER] $1"
  echo ""
  echo "$2"
  echo "======================================================================"
  exit 1
}

# Junta os argumentos para permitir casamento por padrão, e não por igualdade
# exata: a revisão do PR #12 mostrou que comparar cada arg contra "-fd"/"-f"
# deixava passar `git clean -fdx`, que é a forma mais destrutiva do comando.
ARGS="$*"

# O subcomando NÃO é necessariamente o primeiro argumento: `git -C /outro/repo
# clean -fdx` é válido e destrutivo. Tratar `$1` como subcomando fazia toda
# forma com opção global passar batido (achado do CodeRabbit no PR #12).
# Percorre as opções globais até achar o subcomando de verdade.
SUB=""
i=1
while [ $i -le $# ]; do
  eval "tok=\${$i}"
  case "$tok" in
    -C|-c|--git-dir|--work-tree|--namespace|--exec-path|--config-env)
      i=$((i + 2)); continue ;;                 # consome a opção e seu valor
    --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--config-env=*)
      i=$((i + 1)); continue ;;                 # valor embutido no próprio token
    -p|--paginate|--no-pager|--bare|--literal-pathspecs|--glob-pathspecs|--icase-pathspecs|--noglob-pathspecs|--no-optional-locks|--no-replace-objects)
      i=$((i + 1)); continue ;;                 # booleana
    -*)
      i=$((i + 1)); continue ;;                 # outra global desconhecida: pula
    *)
      SUB="$tok"; break ;;
  esac
done

case "$SUB" in
  add)
    # `-u` faz stage de todos os rastreados: é staging em massa ainda que
    # não pareça. Estava fora da versão original desta trava.
    if echo "$ARGS" | grep -qE '(^|[[:space:]])((-[A-Za-z]*[Au])|--all|\.|\*|:/)([[:space:]]|$)'; then
      recusar "Staging em massa proibido." \
        "Use staging cirurgico, um arquivo por vez: git add caminho/do/arquivo.ext"
    fi
    ;;
  reset)
    if echo "$ARGS" | grep -qE -- '--hard'; then
      recusar "'git reset --hard' descarta trabalho nao comitado." \
        "Prefira 'git stash' ou reverta arquivos especificos."
    fi
    ;;
  clean)
    if echo "$ARGS" | grep -qE '([[:space:]]-[A-Za-z]*f|--force)'; then
      recusar "'git clean' com -f apaga arquivos nao rastreados." \
        "Rode 'git clean -n' primeiro para ver o que seria apagado."
    fi
    ;;
  restore|checkout)
    if echo "$ARGS" | grep -qE '(^|[[:space:]])(\.|:/)([[:space:]]|$)'; then
      recusar "Descarte em massa de alteracoes no working tree." \
        "Restaure arquivos especificos: git restore caminho/do/arquivo.ext"
    fi
    ;;
  push)
    if echo "$ARGS" | grep -qE '([[:space:]]-[A-Za-z]*f|--force)'; then
      recusar "Force-push reescreve historico ja publicado." \
        "Se for mesmo necessario, o autor humano deve autorizar e executar manualmente."
    fi
    ;;
esac

exec git "$@"
