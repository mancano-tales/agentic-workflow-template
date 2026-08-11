#!/usr/bin/env Rscript
# ==============================================================================
# render-changelog.R — Deriva um CHANGELOG anotado com hashes a partir do git log
# ==============================================================================
#
# MOTIVAÇÃO
#
# O padrão de rastreabilidade fina pedia que cada entrada do NEWS.md carregasse o
# hash do commit que a introduziu:
#
#     - **`[a1b2c3d]` 2026-07-30 15:45** — Descrição da mudança.
#
# Isso é insatisfazível em um único commit. O hash é o SHA-1 do conteúdo do commit;
# escrever o hash dentro de um arquivo que esse mesmo commit versiona altera o
# conteúdo e, portanto, o hash. É um problema de ponto fixo, não uma falha de
# implementação: `git commit --amend` apenas produz um hash novo, igualmente não
# registrado. Nenhum hook pode fechar esse laço.
#
# Na prática a regra rendia um commit de correção após cada commit real
# (`docs(news): backfill do hash`), dobrando o histórico — e o hash do próprio
# commit de backfill nunca era registrado. A regra só se sustentava porque era
# descumprida no último passo.
#
# A causa raiz é de modelagem: o hash JÁ ESTÁ no Git. Copiá-lo à mão para um arquivo
# rastreado é desnormalização, e como todo dado desnormalizado só pode divergir.
#
# Este script inverte a dependência. O NEWS.md permanece a fonte editorial, escrita
# à mão e sem hashes; os hashes são DERIVADOS do `git log` no momento em que alguém
# precisa deles. Fonte única de verdade: o Git.
#
# USO
#
#   Rscript tools/render-changelog.R                    # tudo, para stdout
#   Rscript tools/render-changelog.R --since v1.0.0     # desde uma tag
#   Rscript tools/render-changelog.R --output CHANGELOG.md
#
# O arquivo gerado é derivado e descartável: não o edite à mão e não o versione
# como se fosse fonte.
# ==============================================================================

invisible(Sys.setlocale("LC_ALL", "C"))

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  idx <- match(flag, args)
  if (is.na(idx) || idx == length(args)) {
    return(default)
  }
  args[idx + 1]
}

since <- get_arg("--since")
output <- get_arg("--output")

git_capture <- function(gitargs) {
  result <- suppressWarnings(tryCatch(
    system2("git", gitargs, stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)
  ))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    return(character(0))
  }
  result
}

if (length(git_capture(c("rev-parse", "--git-dir"))) == 0) {
  cat("[ERRO] Este diretório não é um repositório Git.\n")
  quit(status = 1)
}

# Separador improvável de aparecer numa mensagem de commit.
SEP <- "\x1f"
range_arg <- if (!is.null(since)) paste0(since, "..HEAD") else NULL

# O formato de data usa 'T' em vez de espaço de propósito. No Windows, system2()
# não protege argumentos que contenham espaço: '--date=format:%Y-%m-%d %H:%M' chega
# ao git partido em dois e o comando morre com status 128 (verificado). Sem espaço,
# não há o que quotar — o 'T' vira espaço na renderização, mais abaixo.
log_args <- c(
  "log", "--no-merges", paste0("--format=%h", SEP, "%ad", SEP, "%s"),
  "--date=format:%Y-%m-%dT%H:%M"
)
if (!is.null(range_arg)) log_args <- c(log_args, range_arg)

entries <- git_capture(log_args)
entries <- entries[nzchar(entries)]

if (length(entries) == 0) {
  cat("[AVISO] Nenhum commit encontrado no intervalo solicitado.\n")
  quit(status = 0)
}

parsed <- do.call(rbind, lapply(entries, function(line) {
  parts <- strsplit(line, SEP, fixed = TRUE)[[1]]
  if (length(parts) < 3) {
    return(NULL)
  }
  data.frame(
    hash = parts[1],
    date = sub("T", " ", parts[2], fixed = TRUE),
    subject = parts[3],
    stringsAsFactors = FALSE
  )
}))

# Mapeia o tipo do Conventional Commit para a categoria do Keep a Changelog 1.1.0.
type_of <- function(subject) {
  m <- regmatches(subject, regexpr("^[a-z]+", subject))
  if (length(m) == 0) "outros" else m
}

CATEGORY <- c(
  feat = "Added", fix = "Fixed", perf = "Fixed", revert = "Changed",
  refactor = "Changed", style = "Changed", docs = "Changed",
  build = "Changed", ci = "Changed", chore = "Changed", test = "Changed"
)

parsed$type <- vapply(parsed$subject, type_of, character(1))
parsed$category <- ifelse(
  parsed$type %in% names(CATEGORY), CATEGORY[parsed$type], "Changed"
)
# `!` no cabeçalho marca breaking change — vira seção própria.
parsed$category[grepl("^[a-z]+(\\([^)]*\\))?!:", parsed$subject)] <- "Breaking"

# DETERMINISMO: o cabeçalho NÃO carrega a hora da geração.
#
# Enquanto a saída ia para stdout, `Sys.time()` era inofensivo. Desde que o
# CHANGELOG.md passou a ser versionado (2026-07-31), deixou de ser: regenerar
# sem nenhuma mudança no histórico produzia um diff, apenas porque o relógio
# andou. Um artefato derivado tem de ser função exclusiva da sua entrada — caso
# contrário `git diff` deixa de responder "algo mudou?" e passa a responder
# "alguém rodou o script?".
#
# O carimbo é o do commit mais recente incluído, que vem do próprio `git log`:
# informa a mesma coisa de útil (até onde o changelog cobre) e é estável.
lines <- c(
  "# CHANGELOG (derivado)",
  "",
  paste0(
    "Derivado do `git log` por `tools/render-changelog.R`. ",
    "Commit mais recente incluído: ", max(parsed$date), "."
  ),
  "",
  "Arquivo DERIVADO do `git log`. Não edite à mão — a fonte editorial é o `NEWS.md`,",
  "e a fonte dos hashes é o Git. Ver o cabeçalho do script para o porquê.",
  ""
)

for (cat_name in c("Breaking", "Added", "Fixed", "Changed")) {
  rows <- parsed[parsed$category == cat_name, , drop = FALSE]
  if (nrow(rows) == 0) next
  lines <- c(lines, paste0("## ", cat_name), "")
  for (i in seq_len(nrow(rows))) {
    lines <- c(lines, sprintf(
      "- **`[%s]` %s** — %s",
      rows$hash[i], rows$date[i], rows$subject[i]
    ))
  }
  lines <- c(lines, "")
}

if (!is.null(output)) {
  writeLines(lines, output, useBytes = TRUE)
  cat(sprintf("[OK] %d entradas escritas em '%s'.\n", nrow(parsed), output))
} else {
  cat(paste(lines, collapse = "\n"), "\n")
}
