#!/usr/bin/env Rscript
# ==============================================================================
# render-changelog.R — Deriva CHANGELOG.md anotado com hashes a partir do git log
# ==============================================================================
# Uso:
#   Rscript tools/render-changelog.R [--output CHANGELOG.md] [--since YYYY-MM-DD]
# ==============================================================================

CWD <- getwd()
args <- commandArgs(trailingOnly = TRUE)

output_file <- "CHANGELOG.md"
if ("--output" %in% args) {
  idx <- match("--output", args)
  if (idx < length(args)) output_file <- args[idx + 1]
}

since_arg <- NULL
if ("--since" %in% args) {
  idx <- match("--since", args)
  if (idx < length(args)) since_arg <- args[idx + 1]
}

# Configurações do Git
GIT_ARGS <- c("-c", "core.quotepath=false", "log", "--no-merges", "--format=%h%x1f%an%x1f%ad%x1f%s", "--date=short")
if (!is.null(since_arg)) {
  GIT_ARGS <- c(GIT_ARGS, paste0("--since=", since_arg))
}

log_lines <- suppressWarnings(tryCatch(
  system2("git", GIT_ARGS, stdout = TRUE, stderr = TRUE),
  error = function(e) character(0)
))

# Filtra mensagens de erro do git se houver
if (length(log_lines) > 0 && attr(log_lines, "status") %||% 0 != 0) {
  log_lines <- character(0)
}

# Se não houver commits (ex.: repo novo sem commits)
if (length(log_lines) == 0) {
  header_lines <- c(
    "# CHANGELOG (derivado)",
    "",
    "Derivado do `git log` por `tools/render-changelog.R`.",
    "",
    "Nenhum commit encontrado para gerar o changelog no momento.",
    ""
  )
  if (!is.null(output_file)) {
    writeLines(header_lines, output_file, useBytes = TRUE)
    cat(sprintf("CHANGELOG inicial gerado sem commits em '%s'.\n", output_file))
  } else {
    cat(paste(header_lines, collapse = "\n"), "\n")
  }
  quit(status = 0)
}

# Ignora commits automatizados de publicação de site se houver
log_lines <- log_lines[!grepl("\x1fbuild\\(site\\):", log_lines)]

if (length(log_lines) == 0) {
  header_lines <- c(
    "# CHANGELOG (derivado)",
    "",
    "Derivado do `git log` por `tools/render-changelog.R`.",
    "",
    "Todos os commits encontrados foram filtrados (commits automatizados de build/site).",
    ""
  )
  if (!is.null(output_file)) {
    writeLines(header_lines, output_file, useBytes = TRUE)
    cat(sprintf("CHANGELOG filtrado gerado em '%s'.\n", output_file))
  } else {
    cat(paste(header_lines, collapse = "\n"), "\n")
  }
  quit(status = 0)
}

# Parsing dos commits
SEP <- "\x1f"
parsed_rows <- lapply(log_lines, function(line) {
  parts <- strsplit(line, SEP, fixed = TRUE)[[1]]
  if (length(parts) < 4) {
    return(NULL)
  }
  hash <- parts[1]
  author <- parts[2]
  date <- parts[3]
  subject <- paste(parts[4:length(parts)], collapse = SEP)

  # Sanitizar caminhos absolutos / locais do assunto.
  # As duas linhas abaixo precisam conter o padrao literalmente para poder
  # reconhece-lo, entao carregam o marcador de dispensa do T1. O resto do
  # arquivo continua sendo escaneado normalmente.
  subject <- gsub("C:/Users/[A-Za-z0-9_-]+/[^ ]+", "[caminho-local]", subject) # nolint: abs-path
  subject <- gsub("MancanoSync/[^ ]+", "[caminho-local]", subject) # nolint: abs-path

  # Determinar categoria Conventional Commits
  type_match <- regmatches(subject, regexpr("^(?i)([a-z]+)", subject))
  type <- if (length(type_match) > 0) tolower(type_match[1]) else "other"

  # Taxonomia canonica: a tabela de PRINCIPLES.md e README.md, que concordam
  # entre si. O codigo divergia dela em tres pontos — emitia "Documentation" e
  # "Build", categorias que a especificacao nao tem, e mandava `perf` para
  # "Changed" em vez de "Fixed" — tornando o contrato documentado inalcancavel
  # (achado do CodeRabbit no PR #12). Ao alterar aqui, alinhe os dois
  # documentos e regenere o CHANGELOG.md.
  category <- switch(type,
    "feat" = "Added",
    "fix" = "Fixed",
    "perf" = "Fixed",
    "refactor" = "Changed",
    "style" = "Changed",
    "docs" = "Changed",
    "build" = "Changed",
    "ci" = "Changed",
    "chore" = "Changed",
    "test" = "Changed",
    "revert" = "Changed",
    "Changed" # fallback conservador para tipo nao reconhecido
  )

  if (grepl("^(?i)[a-z]+(\\([^)]*\\))?!:", subject)) {
    category <- "Breaking"
  }

  list(hash = hash, author = author, date = date, subject = subject, category = category)
})

parsed_rows <- Filter(Negate(is.null), parsed_rows)

if (length(parsed_rows) == 0) {
  cat("Nenhum commit elegível para o CHANGELOG.\n")
  quit(status = 0)
}

hashes <- sapply(parsed_rows, `[[`, "hash")
dates <- sapply(parsed_rows, `[[`, "date")
subjects <- sapply(parsed_rows, `[[`, "subject")
categories <- sapply(parsed_rows, `[[`, "category")

df <- data.frame(
  hash = hashes,
  date = dates,
  subject = subjects,
  category = categories,
  stringsAsFactors = FALSE
)

# Renderizar CHANGELOG.md determinístico
most_recent_date <- max(df$date)
out_lines <- c(
  "# CHANGELOG (derivado)",
  "",
  paste0("Derivado do `git log` por `tools/render-changelog.R`. Commit mais recente incluído: ", most_recent_date, "."),
  "",
  "Arquivo DERIVADO do `git log`. Não edite à mão — a fonte editorial é o `NEWS.md` e o histórico do Git.",
  ""
)

# Quatro categorias, como especificado em PRINCIPLES.md e README.md.
# "Deprecated", "Removed" e "Security" nao sao emitidas (ver PRINCIPLES.md §4).
cat_order <- c("Breaking", "Added", "Fixed", "Changed")
for (cat_name in cat_order) {
  sub_df <- df[df$category == cat_name, , drop = FALSE]
  if (nrow(sub_df) == 0) next
  out_lines <- c(out_lines, paste0("## ", cat_name), "")
  for (i in seq_len(nrow(sub_df))) {
    out_lines <- c(out_lines, sprintf("- **`[%s]` %s** — %s", sub_df$hash[i], sub_df$date[i], sub_df$subject[i]))
  }
  out_lines <- c(out_lines, "")
}

if (!is.null(output_file)) {
  tmp_file <- paste0(output_file, ".tmp")
  writeLines(out_lines, tmp_file, useBytes = TRUE)
  file.rename(tmp_file, output_file)
  cat(sprintf("[OK] %d entradas escritas em '%s'.\n", nrow(df), output_file))
} else {
  cat(paste(out_lines, collapse = "\n"), "\n")
}
