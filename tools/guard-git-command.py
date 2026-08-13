#!/usr/bin/env python3
# ==============================================================================
# guard-git-command.py — Analise de tokens do comando git (trava PreToolUse)
# ==============================================================================
#
# Chamado por tools/guard-git-command.sh. Le o payload JSON do hook em stdin,
# extrai o comando, tokeniza respeitando aspas e continuacao de linha, e
# identifica o subcomando git DEPOIS das opcoes globais.
#
# Por que substituiu a versao com regex: enumerar as opcoes globais numa lista
# (`-C`, `-c`, `--git-dir`, ...) e uma corrida perdida — `-P`, `--no-advice` e
# `--no-lazy-fetch` ja escapavam, alem de caminho citado com espacos e
# continuacao de linha, e cada versao do git pode adicionar outras. Aqui
# QUALQUER token iniciado por `-` antes do subcomando e tratado como opcao
# global, entao opcoes futuras ficam cobertas sem manutencao.
#
# Falha fechada: se o comando menciona `git` e a analise falhar por qualquer
# motivo, bloqueia. Comando sem `git` nao e assunto desta trava e passa.
#
# Saida: codigo 2 bloqueia a chamada (contrato do PreToolUse); 0 libera.
# ==============================================================================

import json
import re
import shlex
import sys

# Opcoes globais que CONSOMEM o proximo token como valor.
VALUE_OPTS = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace",
    "--exec-path", "--config-env", "--super-prefix",
}

# Operadores que separam comandos distintos numa mesma linha.
SEPARATORS = {";", "&&", "||", "|", "&", "\n"}


def bloquear(titulo, alternativa):
    print("=" * 70, file=sys.stderr)
    print(f" [BLOQUEADO - T-GIT-GUARD] {titulo}", file=sys.stderr)
    print("", file=sys.stderr)
    print(f" {alternativa}", file=sys.stderr)
    print("=" * 70, file=sys.stderr)
    sys.exit(2)


def flag_curta_com(letra, tok):
    """-f, -fd, -fdx, -xdf... (aglomerado de flags curtas contendo `letra`)."""
    return bool(re.match(rf"^-[A-Za-z]*{letra}[A-Za-z]*$", tok))


def analisar(argv):
    """Recebe os tokens DEPOIS de `git`; devolve (subcomando, args) ou None."""
    i = 0
    while i < len(argv):
        tok = argv[i]
        if tok in VALUE_OPTS:
            i += 2
            continue
        if tok.startswith("-"):
            # Catch-all: qualquer opcao global, conhecida ou futura.
            i += 1
            continue
        return tok, argv[i + 1:]
    return None


def checar(sub, args):
    if sub == "add":
        for a in args:
            if a in (".", "*", ":/", "--all", "-u", "--update", "--renormalize"):
                bloquear(
                    "Staging em massa proibido.",
                    "Use staging cirurgico, um arquivo por vez: git add caminho/do/arquivo.ext",
                )
            if re.match(r"^-[A-Za-z]*[Au][A-Za-z]*$", a):
                bloquear(
                    "Staging em massa proibido.",
                    "Use staging cirurgico, um arquivo por vez: git add caminho/do/arquivo.ext",
                )
            if a.startswith("--pathspec-from-file"):
                bloquear(
                    "'--pathspec-from-file' seleciona multiplos caminhos de uma vez.",
                    "Enumere os arquivos explicitamente no comando.",
                )
    elif sub == "reset":
        if "--hard" in args:
            bloquear(
                "'git reset --hard' descarta trabalho nao comitado.",
                "Prefira 'git stash' ou reverta arquivos especificos.",
            )
    elif sub == "clean":
        for a in args:
            if a == "--force" or flag_curta_com("f", a):
                bloquear(
                    "'git clean' com -f apaga arquivos nao rastreados.",
                    "Rode 'git clean -n' primeiro para ver o que seria apagado.",
                )
    elif sub in ("restore", "checkout"):
        for a in args:
            if a in (".", ":/", "*"):
                bloquear(
                    "Descarte em massa de alteracoes no working tree.",
                    "Restaure arquivos especificos: git restore caminho/do/arquivo.ext",
                )
            if a.startswith("--pathspec-from-file"):
                bloquear(
                    "'--pathspec-from-file' seleciona multiplos caminhos de uma vez.",
                    "Enumere os arquivos explicitamente no comando.",
                )
    elif sub == "push":
        for a in args:
            if a.startswith("--force") or flag_curta_com("f", a):
                bloquear(
                    "Force-push reescreve historico ja publicado.",
                    "Se for mesmo necessario, o autor humano deve autorizar e executar manualmente.",
                )


def main():
    bruto = sys.stdin.read()

    try:
        dados = json.loads(bruto)
        comando = dados.get("tool_input", {}).get("command", "")
    except Exception:
        comando = bruto

    if not isinstance(comando, str) or "git" not in comando:
        sys.exit(0)

    try:
        lexer = shlex.shlex(comando, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        # `git` esta presente mas nao conseguimos tokenizar (aspas
        # desbalanceadas, por exemplo). Falha fechada, por design.
        bloquear(
            "Nao foi possivel analisar com seguranca um comando que invoca git.",
            "Reescreva o comando de forma mais simples (aspas balanceadas, uma acao por chamada).",
        )
        return

    # Divide em segmentos nos operadores de shell e checa cada um.
    segmento = []
    for tok in tokens + [";"]:
        if tok in SEPARATORS:
            if segmento:
                for idx, t in enumerate(segmento):
                    if t == "git" or t.endswith("/git") or t.endswith("\\git.exe") or t == "git.exe":
                        r = analisar(segmento[idx + 1:])
                        if r:
                            checar(r[0], r[1])
                        break
            segmento = []
        else:
            segmento.append(tok)

    sys.exit(0)


if __name__ == "__main__":
    main()
