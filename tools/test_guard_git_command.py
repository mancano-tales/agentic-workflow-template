#!/usr/bin/env python3
# ==============================================================================
# test_guard_git_command.py — Testes da trava PreToolUse (guard-git-command.py)
# ==============================================================================
#
# Sem dependencias: so a biblioteca padrao. Rode da raiz do repositorio:
#
#     python tools/test_guard_git_command.py
#
# Cada caso manda o payload JSON do hook (o mesmo formato que o Claude Code
# envia) ao guard e confere o codigo de saida: 2 = bloqueado, 0 = liberado.
# Nenhum comando e EXECUTADO — o guard so analisa o texto. Mesmo assim, nunca
# teste comando destrutivo de verdade no repositorio em uso (ver o incidente
# registrado no cabecalho de guard-git-command.sh).
#
# Sai com 0 se todos os casos passam e 1 se algum falha.
# ==============================================================================

import base64
import json
import os
import subprocess
import sys

GUARD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "guard-git-command.py")


def ps_enc(cmd):
    return base64.b64encode(cmd.encode("utf-16-le")).decode("ascii")


BLOQUEADOS = [
    # Defeito B2 do PR #12: passavam com rc=0.
    "git status\ngit clean -fdx",
    "git status\ngit add .",
    'bash -c "git reset --hard"',
    "git push origin +main",
    # Variantes de separador e embrulho.
    "git status\r\ngit reset --hard",
    "echo ok # comentario\ngit clean -fdx",
    "(git clean -fd)",
    "git status; git add -A",
    "git status && git add --all",
    "git log | git reset --hard",
    "sh -c 'git clean -f'",
    "bash -lc 'cd x && git add .'",
    "/usr/bin/bash -c \"git push --force\"",
    "cmd /c git reset --hard",
    "cmd.exe /C \"git clean -fdx\"",
    'powershell -Command "git reset --hard"',
    "pwsh -c 'git add .'",
    "powershell -EncodedCommand " + ps_enc("git clean -fdx"),
    "eval 'git reset --hard'",
    "echo $(git reset --hard)",
    "echo `git clean -fdx`",
    'bash -c "bash -c \\"git add .\\""',
    # LIMITE CONHECIDO (falso positivo aceito, ver cabecalho do guard): crase
    # dentro de aspas simples e literal para o shell, mas e analisada.
    "git commit -m 'veja `git add .`'",
    # Force-push por refspec.
    "git push origin +HEAD:main",
    "git push origin main +feature",
    "git push --force-with-lease",
    "git push -f origin main",
    # Descarte e delecao forcados.
    "git checkout -f",
    "git checkout --force main",
    "git switch --discard-changes main",
    "git switch -f main",
    "git branch -D velha",
    "git branch -d -f velha",
    "git branch --delete --force velha",
    # Revisao do Codex no PR #15 (2026-10-04).
    # Aspas ANSI-C e de localizacao: o bash executa o conteudo decodificado.
    "bash -c $'git reset --hard'",
    "bash -c $'\\x67it clean -fdx'",
    "bash -c $'git status\\ngit reset --hard'",
    'bash -c $"git reset --hard"',
    # Force refspec e alias vindos de `git -c`.
    "git -c remote.origin.push=+HEAD:main push origin",
    "git -c alias.limpa='!git clean -fdx' limpa",
    "git -c alias.zera='reset --hard' zera",
    "git --config-env=alias.x=VAR x",
    # Embrulho depois de prefixos que executam o que vem a seguir.
    "env FOO=1 bash -c 'git reset --hard'",
    "sudo -u ana sh -c 'git clean -fdx'",
    "time bash -c 'git push --force'",
    "xargs -0 sh -c 'git add .'",
    "find . -name x -exec sh -c 'git reset --hard' \\;",
    "if true; then bash -c 'git add -A'; fi",
    # Shell sem -c le o script por pipe ou here-string.
    "echo 'git reset --hard' | bash",
    "printf 'git clean -fdx' | sh -s",
    "bash <<< 'git add .'",
    # Casos que ja eram bloqueados (regressao).
    "git add .",
    "git add -A",
    "git add -u",
    "git clean -fdx",
    "git -C /outro clean -fdx",
    'git -C "/tmp/repo com espaco" clean -fdx',
    "git reset --hard",
    "git restore .",
    "git checkout .",
    "git push --force",
    "git \\\n  clean -fdx",
]

LIBERADOS = [
    "git add arquivo.R",
    "git add tools/guard-git-command.py NEWS.md",
    "git status",
    "git log --oneline -5",
    "git push origin minha-branch",
    "git push -u origin minha-branch",
    'git commit -m "texto com git add . dentro da mensagem"',
    'git commit -m "fix: limpa o cache e faz reset --hard no mock"',
    "git commit -m \"linha 1\ngit clean -fdx na linha 2 da mensagem\"",
    "grep -rn 'git add .' docs/",
    "git -C /outro status",
    "git checkout -b nova-branch",
    "git checkout main",
    "git switch main",
    "git branch -d mergeada",
    "git clean -n",
    "git reset --soft HEAD~1",
    "git status 2>&1 | head",
    'bash -c "git status"',
    "cmd /c git log",
    'powershell -Command "git diff"',
    "ls -la",
    "echo 'aspas desbalanceadas",  # sem git: nao e assunto da trava
    'bash -c "echo it\'s"',  # string interna sem git, mesmo mal formada
    # Revisao do Codex no PR #15: `bash` como argumento nao executa nada.
    "echo bash -c 'git reset --hard'",
    "grep -n \"bash -c 'git add .'\" README.md",
    "git -c user.name=Fulano commit -m ok",
    "git -c remote.origin.push=refs/heads/main:refs/heads/main push origin",
    "git -c alias.st=status st",
    "bash -c $'git status\\n'",
    "echo 'git status' | bash",
    "echo ok | bash -c 'git status'",
]


def rodar(comando):
    payload = json.dumps({"tool_input": {"command": comando}})
    r = subprocess.run(
        [sys.executable, GUARD],
        input=payload,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return r.returncode


def main():
    falhas = 0
    total = 0
    for esperado, casos in ((2, BLOQUEADOS), (0, LIBERADOS)):
        rotulo = "bloqueado" if esperado == 2 else "liberado "
        for c in casos:
            total += 1
            rc = rodar(c)
            ok = rc == esperado
            if not ok:
                falhas += 1
            print(f"[{'OK' if ok else 'FALHA'}] esperado {rotulo} rc={rc}  {c!r}")
    print()
    print(f"{total - falhas}/{total} casos passaram "
          f"({len(BLOQUEADOS)} bloqueados, {len(LIBERADOS)} liberados).")
    sys.exit(1 if falhas else 0)


if __name__ == "__main__":
    main()
