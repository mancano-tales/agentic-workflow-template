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
# Rodada pos-PR #12 (2026-09-25) — quatro bypasses medidos e fechados:
#   1. Quebra de linha nao separava comandos: o shlex a tratava como espaco, e
#      `git status<NL>git clean -fdx` virava UM segmento em que so o primeiro
#      `git` era analisado. Agora a quebra de linha e separador como `;`, e
#      TODO `git` de cada segmento e analisado, nao so o primeiro.
#   2. Comando embrulhado: `bash -c "git reset --hard"` chegava como uma
#      string unica. Agora `bash|sh|zsh -c`, `cmd /c`, `powershell|pwsh
#      -Command` (e `-EncodedCommand`, decodificado) e `eval` tem a string
#      interna analisada recursivamente. Idem `$(...)` e crases.
#   3. Force-push por refspec: `git push origin +main` forca sem `--force`.
#   4. Descarte e delecao forcados: `git checkout -f`, `git switch
#      --discard-changes|-f` e `git branch -D` (ou `-d` com `-f`).
#
# Revisao do Codex no PR #15 (2026-10-04) — mais quatro:
#   5. Aspas ANSI-C: `bash -c $'git reset --hard'` (e `$'\x67it ...'`, que
#      esconde a palavra git) e decodificado antes de tudo; `$"..."` idem.
#   6. Configuracao na linha de comando: `git -c remote.origin.push=+HEAD:main
#      push` forca sem `+` nos argumentos, e `-c alias.x='!git reset --hard' x`
#      roda outro comando. Os valores de `-c`/`--config-env` sao conferidos.
#   7. Embrulho so conta em posicao de comando: `echo bash -c '...'` nao
#      executa nada e passa; `env`, `sudo`, `time`, `xargs`, `find -exec` e
#      palavras-chave (`if`, `then`...) sao atravessados ate o comando real.
#   8. Shell sem `-c` le o script da entrada: `echo '...' | bash` e
#      `bash <<< '...'` tem o texto analisado.
# Segunda revisao do Codex (2026-10-05):
#   9. Opcao longa de prefixo (`sudo --user ana bash -c ...`): depois de um
#      prefixo, todo token seguinte conta como possivel comando (falha
#      fechada, sem tabela de opcoes que envelhece).
#  10. Aliases encadeados em `-c` (`a` -> `b` -> `reset --hard`) sao seguidos
#      ate o fim, com teto e deteccao de laco; refspec `+` em `-c` bloqueia
#      seja qual for o subcomando.
#  11. Pipeline com varios estagios (`echo '...' | cat | bash`): todos os
#      estagios que alimentam o shell sao analisados.
#
# Limite conhecido (documentado, nao escondido): depois de tokenizar, nao se
# sabe mais se uma string veio entre aspas simples ou duplas. Por isso um
# `$(...)` ou crase DENTRO de aspas simples (literal, que o shell nao executa)
# e analisado como se fosse executado: `git commit -m 'veja `git add .`'` e
# bloqueado (falso positivo). O mesmo texto entre aspas DUPLAS seria executado
# de verdade pelo bash, entao bloquear e o lado certo do erro. Texto comum
# dentro da mensagem — `git commit -m "nao use git add ."` — passa.
#
# Falha fechada: se o comando menciona `git` e a analise falhar por qualquer
# motivo, bloqueia. Comando sem `git` nao e assunto desta trava e passa.
#
# Saida: codigo 2 bloqueia a chamada (contrato do PreToolUse); 0 libera.
# ==============================================================================

import base64
import codecs
import json
import re
import shlex
import sys

# Opcoes globais que CONSOMEM o proximo token como valor.
VALUE_OPTS = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace",
    "--exec-path", "--config-env", "--super-prefix",
}

# Caracteres que o shlex agrupa como pontuacao. A quebra de linha entra aqui
# (e sai do conjunto de espacos) para virar separador de comando.
PUNCT = "();<>|&\n"
# Um token de pontuacao e separador de comando se so contem estes caracteres
# (`;`, `&&`, `||`, `|`, `&`, quebra de linha, parenteses de subshell). `>&` e
# `2>&1` contem `>` e por isso NAO sao separadores — sao redirecionamentos.
SEP_CHARS = set(";&|\n()")

# Profundidade maxima de embrulho (bash -c "bash -c '...'"). Acima disso,
# falha fechada.
MAX_DEPTH = 5

SHELLS_C = {"bash", "sh", "zsh", "dash", "ksh"}
POWERSHELLS = {"powershell", "pwsh"}

# Palavras-chave do shell que podem preceder um comando no mesmo segmento.
PALAVRAS_CHAVE = {"if", "then", "else", "elif", "do", "while", "until", "!", "{", "}"}
# Prefixos que executam o comando que vem depois deles (e suas opcoes que
# consomem um valor, para nao confundir o valor com o comando).
PREFIXOS = {"env", "sudo", "doas", "nohup", "time", "command", "builtin", "exec",
            "nice", "stdbuf", "timeout", "xargs", "unbuffer"}
# Teto de expansao de aliases encadeados (`alias.a=b`, `alias.b=...`).
MAX_ALIAS = 10


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


def nome_base(tok):
    """`/usr/bin/bash`, `C:\\...\\bash.exe`, `Bash.EXE` -> `bash`."""
    base = re.split(r"[\\/]", tok)[-1].lower()
    if base.endswith(".exe"):
        base = base[:-4]
    return base


def eh_separador(tok):
    return bool(tok) and set(tok) <= SEP_CHARS


def analisar(argv):
    """Recebe os tokens DEPOIS de `git`; devolve (subcomando, args, configs) ou None.

    `configs` sao os valores de `-c nome=valor` e `--config-env nome=VAR`: eles
    podem forcar um push (`remote.<r>.push=+...`) ou definir um alias que roda
    outro comando, entao nao basta pula-los."""
    i, configs = 0, []
    while i < len(argv):
        tok = argv[i]
        if tok.startswith("--config-env="):
            configs.append(("env", tok.split("=", 1)[1]))
            i += 1
            continue
        if tok in VALUE_OPTS:
            if tok in ("-c", "--config-env") and i + 1 < len(argv):
                configs.append(("c" if tok == "-c" else "env", argv[i + 1]))
            i += 2
            continue
        if tok.startswith("-"):
            # Catch-all: qualquer opcao global, conhecida ou futura.
            i += 1
            continue
        return tok, argv[i + 1:], configs
    return None


def checar_configs(sub, args, configs, prof):
    """Force refspec e aliases vindos de `-c`/`--config-env`."""
    for origem, item in configs:
        nome, _, valor = item.partition("=")
        nome = nome.lower()
        eh_push = re.fullmatch(r"remote\..+\.push", nome) is not None
        eh_alias = nome.startswith("alias.")
        if origem == "env" and (eh_push or eh_alias):
            bloquear(
                f"'--config-env {nome}' traz o valor de uma variavel de ambiente que a trava nao enxerga.",
                "Passe o comando git explicitamente, sem alias nem refspec vindos de configuracao.",
            )
        # Qualquer subcomando: um alias pode virar `push` (`-c alias.p=push p`).
        if eh_push and valor.lstrip().startswith("+"):
            bloquear(
                f"Refspec '{valor}' com '+' em '-c {nome}' e force-push.",
                "Tire o '+'. Se o force for mesmo necessario, o autor humano executa manualmente.",
            )
    expandir_alias(sub, args, configs, prof)


def expandir_alias(sub, args, configs, prof):
    """Segue a cadeia de aliases definidos em `-c` (`a` -> `b` -> `reset
    --hard`), como o git faz, e confere o comando final. Laco ou cadeia longa
    demais: falha fechada."""
    aliases = {}
    for _origem, item in configs:
        nome, _, valor = item.partition("=")
        if nome.lower().startswith("alias."):
            aliases[nome[len("alias."):].lower()] = valor.strip()
    vistos = set()
    while sub.lower() in aliases:
        if sub.lower() in vistos or len(vistos) >= MAX_ALIAS:
            bloquear(
                f"Cadeia de aliases em '-c' com laco ou longa demais ('{sub}').",
                "Rode o comando git diretamente, sem alias definido em '-c'.",
            )
        vistos.add(sub.lower())
        expansao = aliases[sub.lower()]
        if expansao.startswith("!"):
            # Alias de shell: o git roda a string num shell.
            examinar(expansao[1:], prof + 1)
            return
        try:
            r = analisar(shlex.split(expansao) + list(args))
        except ValueError:
            bloquear(
                f"Alias '{sub}' ilegivel: nao da para conferir o que ele executa.",
                "Rode o comando git diretamente, sem alias definido em '-c'.",
            )
        if not r:
            return
        sub, args = r[0], r[1]
        checar(sub, args)


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
    elif sub in ("restore", "checkout", "switch"):
        for a in args:
            if a == "--":
                break  # dali em diante sao caminhos, nao opcoes
            if sub in ("checkout", "switch") and (
                a in ("--force", "--discard-changes") or flag_curta_com("f", a)
            ):
                bloquear(
                    f"'git {sub}' forcado descarta alteracoes locais.",
                    "Faca 'git stash' antes, ou troque de branch sem forcar.",
                )
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
    elif sub == "branch":
        deletar = forcar = False
        for a in args:
            if a == "--":
                break
            if a == "--delete" or flag_curta_com("d", a):
                deletar = True
            if a == "--force" or flag_curta_com("f", a):
                forcar = True
            if flag_curta_com("D", a):
                deletar = forcar = True
        if deletar and forcar:
            bloquear(
                "'git branch -D' apaga a branch mesmo sem merge (trabalho pode se perder).",
                "Use 'git branch -d', que recusa apagar branch nao mergeada.",
            )
    elif sub == "push":
        for a in args:
            if a.startswith("--force") or flag_curta_com("f", a):
                bloquear(
                    "Force-push reescreve historico ja publicado.",
                    "Se for mesmo necessario, o autor humano deve autorizar e executar manualmente.",
                )
            if a.startswith("+") and len(a) > 1:
                bloquear(
                    f"Refspec '{a}' com '+' e force-push (reescreve historico publicado).",
                    "Tire o '+'. Se o force for mesmo necessario, o autor humano executa manualmente.",
                )


def tokenizar(comando):
    # Continuacao de linha (barra invertida + quebra) nao separa comandos.
    comando = comando.replace("\\\r\n", " ").replace("\\\n", " ")
    lexer = shlex.shlex(comando, posix=True, punctuation_chars=PUNCT)
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    return list(lexer)


def subcomandos_embutidos(tok):
    """Conteudo de `$(...)` dentro de um token (ver limite no topo). Crases
    sao tratadas em `examinar`, sobre o texto cru."""
    internos = []
    for m in re.finditer(r"\$\(", tok):
        # Casa parenteses aninhados a partir do `$(`.
        prof, ini = 0, m.end()
        for j in range(m.start() + 1, len(tok)):
            if tok[j] == "(":
                prof += 1
            elif tok[j] == ")":
                prof -= 1
                if prof == 0:
                    internos.append(tok[ini:j])
                    break
        else:
            internos.append(tok[ini:])
    return internos


def posicoes_de_comando(seg):
    """Indices de `seg` em que o shell EXECUTA o token como comando.

    Um `bash` que e so argumento (`echo bash -c '...'`) nao roda nada; o que
    importa e o inicio do segmento, o que vem depois de atribuicoes (`FOO=1`),
    de palavras-chave (`if`, `then`, `!`...) e de prefixos que executam o
    resto da linha (`env`, `sudo`, `time`, `xargs`...), e o que vem depois de
    `-exec` do `find`."""
    posicoes = set()
    i = 0
    while i < len(seg):
        tok = seg[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tok) or tok in PALAVRAS_CHAVE:
            i += 1
            continue
        posicoes.add(i)
        if nome_base(tok) in PREFIXOS:
            # Depois de um prefixo, nao da para saber com seguranca quais
            # tokens sao opcoes e valores dele (`sudo --user ana`, opcoes
            # futuras...). Falha fechada: todo token seguinte conta como
            # possivel comando. Custo: `sudo echo bash -c '...'` e bloqueado.
            posicoes.update(range(i + 1, len(seg)))
        break
    for j, tok in enumerate(seg[:-1]):
        if tok in ("-exec", "-execdir", "-ok", "-okdir"):
            posicoes.add(j + 1)
    return sorted(posicoes)


def desembrulhar(seg):
    """Devolve as strings de comando que `seg` executa por meio de outro shell."""
    internos = []
    for tok in seg:
        internos.extend(subcomandos_embutidos(tok))
    for idx in posicoes_de_comando(seg):
        tok = seg[idx]
        base = nome_base(tok)
        resto = seg[idx + 1:]
        if base in SHELLS_C:
            for j, a in enumerate(resto):
                if re.match(r"^-[A-Za-z]*c[A-Za-z]*$", a) and j + 1 < len(resto):
                    internos.append(resto[j + 1])
                    break
        elif base == "cmd":
            for j, a in enumerate(resto):
                if a.lower() in ("/c", "/k", "/r"):
                    internos.append(" ".join(resto[j + 1:]))
                    break
        elif base in POWERSHELLS:
            for j, a in enumerate(resto):
                al = a.lower()
                # -e / -ec / -enc... : prefixos aceitos de -EncodedCommand.
                if al in ("-e", "-ec") or (len(al) >= 4 and "-encodedcommand".startswith(al)):
                    if j + 1 >= len(resto):
                        continue
                    try:
                        decod = base64.b64decode(resto[j + 1]).decode("utf-16-le")
                    except Exception:
                        bloquear(
                            "PowerShell -EncodedCommand ilegivel: nao da para conferir se invoca git.",
                            "Passe o comando em texto claro.",
                        )
                    internos.append(decod)
                    break
                if al.startswith("-c") and "-command".startswith(al):
                    internos.append(" ".join(resto[j + 1:]))
                    break
        elif base == "eval":
            internos.append(" ".join(resto))
    return internos


def eh_git(tok):
    return nome_base(tok) == "git"


def menciona_git(comando):
    """Atalho: sem `git` visivel nao ha o que checar — exceto PowerShell, cujo
    -EncodedCommand traz o texto em base64."""
    baixo = comando.lower()
    return "git" in baixo or "powershell" in baixo or "pwsh" in baixo


def decodificar_aspas_especiais(comando):
    """`$'...'` (ANSI-C) vira o texto que o bash executaria, entre aspas
    simples; `$"..."` (localizacao) vira aspas duplas comuns. Sem isso o shlex
    entrega `$git reset --hard` e a trava nao reconhece o `git`. Roda antes do
    atalho `menciona_git`, porque `$'\\x67it'` esconde a palavra."""

    def ansi_c(m):
        try:
            texto = codecs.decode(
                m.group(1).encode("latin-1", "backslashreplace"), "unicode_escape"
            )
        except Exception:
            bloquear(
                "Aspas ANSI-C ($'...') ilegiveis: nao da para conferir o que executam.",
                "Escreva o comando em texto claro.",
            )
        return shlex.quote(texto)

    comando = re.sub(r"\$'((?:[^'\\]|\\.)*)'", ansi_c, comando, flags=re.S)
    return comando.replace('$"', '"')


def examinar(comando, prof=0):
    if "$'" in comando or '$"' in comando:
        comando = decodificar_aspas_especiais(comando)
    if not menciona_git(comando):
        return
    if prof > MAX_DEPTH:
        bloquear(
            "Comando embrulhado em shells demais para analisar com seguranca.",
            "Rode o comando git diretamente, sem camadas de 'bash -c'.",
        )
    try:
        tokens = tokenizar(comando)
    except ValueError:
        # `git` esta presente mas nao conseguimos tokenizar (aspas
        # desbalanceadas, por exemplo). Falha fechada, por design.
        bloquear(
            "Nao foi possivel analisar com seguranca um comando que invoca git.",
            "Reescreva o comando de forma mais simples (aspas balanceadas, uma acao por chamada).",
        )

    # Crases sem aspas viram tokens soltos (`git`, clean, -fdx`) que nenhum
    # token isolado denuncia; por isso sao extraidas do texto cru.
    for interno in re.findall(r"`([^`]*)`", comando):
        examinar(interno, prof + 1)

    segmentos, atual, sep = [], [], ""
    seps = []  # separador que precede cada segmento
    for tok in tokens:
        if eh_separador(tok):
            if atual:
                segmentos.append(atual)
                seps.append(sep)
            atual, sep = [], tok
        else:
            atual.append(tok)
    if atual:
        segmentos.append(atual)
        seps.append(sep)

    # Shell sem `-c` le o script da entrada: `echo 'git reset --hard' | bash`
    # e `bash <<< 'git add .'` executam o texto que chega por pipe/here-string.
    for n, seg in enumerate(segmentos):
        for idx in posicoes_de_comando(seg):
            if nome_base(seg[idx]) not in SHELLS_C | POWERSHELLS:
                continue
            resto = seg[idx + 1:]
            if any(re.match(r"^-[A-Za-z]*c[A-Za-z]*$", a) or a.lower().startswith("-com")
                   for a in resto):
                continue  # -c/-Command: tratado em desembrulhar
            for j, a in enumerate(resto[:-1]):
                if a == "<<<":
                    examinar(resto[j + 1], prof + 1)
            # Todos os estagios do pipeline que alimentam o shell, nao so o
            # anterior: `echo '...' | cat | bash` executa o texto do echo.
            k = n
            while k > 0 and seps[k] == "|":
                k -= 1
                for texto in segmentos[k]:
                    examinar(texto, prof + 1)

    for seg in segmentos:
        # TODO `git` do segmento, nao so o primeiro: um comentario `#` pode
        # engolir a quebra de linha e colar dois comandos num segmento so.
        for idx, t in enumerate(seg):
            if eh_git(t):
                r = analisar(seg[idx + 1:])
                if r:
                    checar_configs(r[0], r[1], r[2], prof)
                    checar(r[0], r[1])
        for interno in desembrulhar(seg):
            examinar(interno, prof + 1)


def main():
    bruto = sys.stdin.read()

    try:
        dados = json.loads(bruto)
        comando = dados.get("tool_input", {}).get("command", "")
    except Exception:
        comando = bruto

    if not isinstance(comando, str):
        sys.exit(0)

    examinar(comando)
    sys.exit(0)


if __name__ == "__main__":
    main()
