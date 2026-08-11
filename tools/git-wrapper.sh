#!/usr/bin/env bash
# ==============================================================================
# git-wrapper.sh — Interceptador CLI e Trava Anti-Destrutiva do Git (Bash)
# ==============================================================================

if [ $# -eq 0 ]; then
  exec git
fi

FIRST_ARG="$1"

if [ "$FIRST_ARG" = "add" ]; then
  for arg in "$@"; do
    if [ "$arg" = "." ] || [ "$arg" = "-A" ] || [ "$arg" = "--all" ] || [ "$arg" = "*" ]; then
      echo "======================================================================"
      echo "[ERRO FATAL T-GIT-WRAPPER] STAGING EM MASSA PROIBIDO!"
      echo "Comandos como 'git add .', 'git add -A' ou 'git add *' sao estritamente proibidos."
      echo "Use staging cirurgico especificando cada arquivo:"
      echo "  git add caminho/do/arquivo.ext"
      echo "======================================================================"
      exit 1
    fi
  done
fi

if [ "$FIRST_ARG" = "reset" ]; then
  for arg in "$@"; do
    if [ "$arg" = "--hard" ]; then
      echo "[ERRO FATAL T-GIT-WRAPPER] 'git reset --hard' e um comando destrutivo e proibido."
      exit 1
    fi
  done
fi

if [ "$FIRST_ARG" = "clean" ]; then
  for arg in "$@"; do
    if [ "$arg" = "-fd" ] || [ "$arg" = "-f" ]; then
      echo "[ERRO FATAL T-GIT-WRAPPER] 'git clean' em massa e proibido."
      exit 1
    fi
  done
fi

if [ "$FIRST_ARG" = "restore" ]; then
  for arg in "$@"; do
    if [ "$arg" = "." ]; then
      echo "[ERRO FATAL T-GIT-WRAPPER] 'git restore .' e proibido."
      exit 1
    fi
  done
fi

exec git "$@"
