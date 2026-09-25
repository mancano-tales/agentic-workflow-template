# ==============================================================================
# export_conversa.R — Exporta o JSONL de uma sessão (Claude Code ou Antigravity) para Markdown
#
# Uso:
#   Rscript 4-DA-Code/utils/export_conversa.R <caminho-ou-uuid-do-jsonl> [slug]
#
# O primeiro argumento pode ser um caminho completo para o .jsonl ou um UUID
# (ou prefixo de UUID) de sessão, resolvido contra as pastas de sessões.
#
# Saída: <dir-governanca>/llm-reviews/YYYY-MM-DD_HHMM_<slug>_conversa-<fonte>.md
#        onde <dir-governanca> vem da env var GOV_DIR ou, na ausência dela, é
#        detectado em tempo de execução (ver abaixo). Corresponde à chave
#        `diretorio_governanca` em AGENTS.md § "Configuração de Skills".
# ==============================================================================

suppressPackageStartupMessages(library(jsonlite))

get_claude_project_dir_name <- function() {
  wd <- getwd()
  # Claude translates e.g. "C-slash-Users-slash-Mancano..." to "c--Users-Mancano..."
  drive <- tolower(substr(wd, 1, 1))
  rest <- substr(wd, 4, nchar(wd))
  rest <- gsub("[/\\\\]", "-", rest)
  paste0(drive, "--", rest)
}

PASTA_SESSOES <- file.path(
  Sys.getenv("USERPROFILE", unset = path.expand("~")),
  ".claude", "projects",
  get_claude_project_dir_name()
)
PASTA_ANTIGRAVITY <- file.path(
  Sys.getenv("USERPROFILE", unset = path.expand("~")),
  ".gemini", "antigravity", "brain"
)
# ── Diretório de governança (indireção) ───────────────────────────────────────
# O nome do diretório de governança varia entre os repositórios que usam este
# template: "0-meta" no repo `skills`; "repo-governance" na raiz do
# mancano-repo-hub (era "0-meta" ate 2026-09-24); "9-vers" nos repos
# de pesquisa, onde é o slot 9 de uma taxonomia numerada VIVA (2-set/, 3-texts/,
# 4-DA-Code/, 6-images-tables/, 9-vers/) e portanto está correto ali.
#
# Nenhum dos dois nomes está errado — errado era fixar o nome aqui. Em
# 2026-07-26 este script escreveu um export em "9-vers/llm-reviews/" dentro de
# um repositório que usa "0-meta/", numa pasta ignorada pelo .gitignore: o
# arquivo ficou fora do controle de versão e sem backup. Esta detecção existe
# para que isso não se repita.
#
# Precedência (resolução do merge de 2026-07-28, que unificou duas
# implementações independentes do WP3):
#   1. env var GOV_DIR — override explícito, para quem usa um nome fora da lista;
#   2. detecção em disco — o primeiro candidato que existir vence;
#   3. fallback para o primeiro candidato.
# A detecção é o que garante um default correto por omissão: sem ela, um repo
# "0-meta" que rode o script sem setar a env var volta a escrever na pasta
# errada — exatamente o modo de falha acima.
# Ver 9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md
# "repo-governance" (2026-09-25): nome da pasta na raiz do mancano-repo-hub. Vai
# no fim da lista para nao mudar o fallback dos repos que ja usam o template.
GOV_DIR_CANDIDATOS <- c("0-meta", "9-vers", "repo-governance")
GOV_DIR <- Sys.getenv("GOV_DIR", unset = "")
if (!nzchar(GOV_DIR)) {
  GOV_DIR <- Find(function(d) dir.exists(file.path(getwd(), d)), GOV_DIR_CANDIDATOS)
  if (is.null(GOV_DIR)) GOV_DIR <- GOV_DIR_CANDIDATOS[[1]]
}

PASTA_SAIDA <- file.path(getwd(), GOV_DIR, "llm-reviews")
FUSO <- "America/Sao_Paulo"

# ── Saneamento de caminhos absolutos ──────────────────────────────────────────
# T1 do `validate-governance.R` bloqueia o commit de qualquer arquivo que
# introduza caminho absoluto local (ABS_PATH_REGEX: "C:/Users/", "/home/",
# "/Users/") ou a substring "MancanoSync/". Uma transcricao de sessao esta cheia
# dos dois: o cabecalho traz o caminho do .jsonl de origem, e as chamadas de
# ferramenta citam caminhos do repositorio a cada comando executado.
#
# Sem este saneamento, TODO export cai no proprio validador do ecossistema e a
# cerimonia `close-task` trava no ultimo passo — duas ferramentas do mesmo
# template em conflito direto. Observado em 2026-07-30 no repo `edupol`: 108
# ocorrencias num unico log, exigindo saneamento manual antes do commit.
RAIZ_REPO <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
DIR_USUARIO <- normalizePath(
  Sys.getenv("USERPROFILE", unset = path.expand("~")),
  winslash = "/", mustWork = FALSE
)

# Aceita as tres grafias que aparecem na pratica: "C:/x", "C:\x" e "/c/x" (Git
# Bash), com a letra da unidade em qualquer caixa.
#
# Cada segmento do caminho entra na regex ESCAPADO: um caminho e texto literal,
# e pastas comuns no Windows tem metacaracteres ("OneDrive - USP (Pessoal)",
# "proj+v2", "dados[2026]"). Sem o escape, esses caminhos nao casavam e vazavam
# em silencio no export; um "(" sem par abortava o PCRE (achado do Copilot no
# PR #14, reproduzido em 2026-09-25). O separador `[/\\]+` pega tambem a barra
# dupla escapada que aparece no JSON das chamadas de ferramenta.
escapar_regex <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)

padrao_de_caminho <- function(caminho) {
  unidade <- regmatches(caminho, regexpr("^[A-Za-z](?=:)", caminho, perl = TRUE))
  resto <- sub("^[A-Za-z]:", "", caminho)
  segmentos <- strsplit(resto, "/", fixed = TRUE)[[1]]
  corpo <- paste(escapar_regex(segmentos), collapse = "[/\\\\]+")
  if (length(unidade)) paste0("(?:", unidade, ":|/", unidade, ")", corpo) else corpo
}

sanitizar_caminhos <- function(x) {
  if (!length(x)) return(x)
  x <- gsub(padrao_de_caminho(RAIZ_REPO), "<repo>", x, perl = TRUE, ignore.case = TRUE)
  x <- gsub(padrao_de_caminho(DIR_USUARIO), "<HOME>", x, perl = TRUE, ignore.case = TRUE)
  x
}

# ── Argumentos ────────────────────────────────────────────────────────────────
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript export_conversa.R <caminho-ou-uuid-do-jsonl> [slug]")
}
alvo <- args[[1]]
slug_arg <- if (length(args) >= 2) args[[2]] else NA_character_

arquivo_jsonl <- NULL
uuid_sessao <- NULL

if (file.exists(alvo)) {
  arquivo_jsonl <- alvo
  # Tentar inferir UUID se estiver dentro da subpasta de logs do Antigravity
  partes_caminho <- strsplit(normalizePath(arquivo_jsonl, winslash = "/"), "/")[[1]]
  idx <- which(grepl("^[0-9a-f]{8}-[0-9a-f]{4}", partes_caminho))
  if (length(idx) > 0) {
    uuid_sessao <- partes_caminho[idx[length(idx)]]
  } else {
    uuid_sessao <- sub("\\.jsonl$", "", basename(arquivo_jsonl))
  }
} else {
  # 1. Procurar no Antigravity primeiro
  hit_antigravity <- NULL
  if (dir.exists(PASTA_ANTIGRAVITY)) {
    dirs <- list.dirs(PASTA_ANTIGRAVITY, recursive = FALSE, full.names = TRUE)
    match_dirs <- dirs[startsWith(basename(dirs), alvo)]
    if (length(match_dirs) == 1) {
      log_full <- file.path(match_dirs, ".system_generated", "logs", "transcript_full.jsonl")
      log_norm <- file.path(match_dirs, ".system_generated", "logs", "transcript.jsonl")
      if (file.exists(log_full)) {
        hit_antigravity <- log_full
      } else if (file.exists(log_norm)) {
        hit_antigravity <- log_norm
      }
    } else if (length(match_dirs) > 1) {
      stop("UUID ambíguo no Antigravity (", length(match_dirs), " sessões): ", alvo)
    }
  }

  # 2. Procurar no Claude Code
  candidatos_claude <- list.files(PASTA_SESSOES, pattern = "\\.jsonl$", full.names = TRUE)
  hit_claude <- candidatos_claude[startsWith(basename(candidatos_claude), alvo)]

  if (!is.null(hit_antigravity)) {
    arquivo_jsonl <- hit_antigravity
    uuid_sessao <- basename(dirname(dirname(dirname(arquivo_jsonl))))
  } else if (length(hit_claude) == 1) {
    arquivo_jsonl <- hit_claude
    uuid_sessao <- sub("\\.jsonl$", "", basename(arquivo_jsonl))
  } else if (length(hit_claude) > 1) {
    stop("UUID ambíguo no Claude Code (", length(hit_claude), " sessões): ", alvo)
  } else {
    stop("Sessão não encontrada para o UUID/prefixo: ", alvo)
  }
}

# ── Leitura ───────────────────────────────────────────────────────────────────
linhas <- readLines(arquivo_jsonl, encoding = "UTF-8", warn = FALSE)
registros <- vector("list", length(linhas))
n_mal_formadas <- 0L
for (i in seq_along(linhas)) {
  registros[[i]] <- tryCatch(
    fromJSON(linhas[[i]], simplifyVector = FALSE),
    error = function(e) {
      n_mal_formadas <<- n_mal_formadas + 1L
      NULL
    }
  )
}
registros <- Filter(Negate(is.null), registros)
if (n_mal_formadas > 0) {
  message("Aviso: ", n_mal_formadas, " linha(s) mal-formada(s) pulada(s).")
}

if (length(registros) == 0) {
  stop("Nenhum registro encontrado no arquivo JSONL.")
}

# ── Detectar Formato ──────────────────────────────────────────────────────────
is_antigravity <- any(vapply(registros, function(r) !is.null(r$step_index), logical(1)))

# ── Helpers ───────────────────────────────────────────────────────────────────
parse_ts <- function(ts) {
  as.POSIXct(sub("Z$", "", ts), format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
}
fmt_local <- function(t, formato = "%Y-%m-%d %H:%M") format(t, formato, tz = FUSO)

cerca <- function(txt) {
  runs <- regmatches(txt, gregexpr("`{3,}", txt))[[1]]
  n <- if (length(runs) == 0) 3L else max(nchar(runs)) + 1L
  strrep("`", n)
}

bloco_details <- function(rotulo, corpo, linguagem = "") {
  f <- cerca(corpo)
  c(
    "<details>",
    paste0("<summary>", rotulo, "</summary>"),
    "",
    paste0(f, linguagem),
    corpo,
    f,
    "",
    "</details>",
    ""
  )
}

texto_de_tool_result <- function(conteudo) {
  if (is.character(conteudo)) {
    return(paste(conteudo, collapse = "\n"))
  }
  if (is.list(conteudo)) {
    partes <- vapply(conteudo, function(b) {
      if (is.list(b) && identical(b$type, "text") && !is.null(b$text)) {
        b$text
      } else if (is.character(b)) {
        paste(b, collapse = "\n")
      } else {
        paste0("[bloco ", if (is.list(b)) b$type %||% "?" else "?", "]")
      }
    }, character(1))
    return(paste(partes, collapse = "\n"))
  }
  as.character(conteudo)
}
`%||%` <- function(a, b) if (is.null(a)) b else a

slug_kebab <- function(x) {
  x <- tolower(x)
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("^-+|-+$", "", x)
}

# ── Varredura de metadados ────────────────────────────────────────────────────
ai_title <- NA_character_
modelo <- NA_character_
versao <- NA_character_
branch <- NA_character_
ts_ini <- NULL
ts_fim <- NULL
n_user <- 0L
n_asst <- 0L
n_tools <- 0L

if (is_antigravity) {
  for (r in registros) {
    if (identical(r$type, "USER_INPUT") && !is.null(r$content) && is.na(ai_title)) {
      clean_txt <- gsub("<[^>]+>", "", r$content)
      clean_txt <- trimws(clean_txt)
      first_line <- strsplit(clean_txt, "\n")[[1]][1]
      if (!is.na(first_line) && nzchar(first_line)) {
        ai_title <- substr(first_line, 1, 40)
      }
    }
  }
  modelo <- "Gemini 3.5 Flash"
  for (r in registros) {
    if (!is.null(r$content) && grepl("Model Selection", r$content)) {
      m <- regmatches(r$content, regexec("Model Selection` from [^ ]+ to ([^\\n\\r\\.]+)", r$content))[[1]]
      if (length(m) >= 2) modelo <- trimws(m[2])
    }
  }
  versao <- "2.0 (Antigravity)"
  branch <- tryCatch(
    {
      system("git rev-parse --abbrev-ref HEAD", intern = TRUE)
    },
    error = function(e) "main"
  )

  for (r in registros) {
    if (!is.null(r$created_at)) {
      t <- parse_ts(r$created_at)
      if (is.null(ts_ini) || t < ts_ini) ts_ini <- t
      if (is.null(ts_fim) || t > ts_fim) ts_fim <- t
    }
    if (identical(r$type, "USER_INPUT")) {
      n_user <- n_user + 1L
    } else if (identical(r$type, "PLANNER_RESPONSE")) {
      n_asst <- n_asst + 1L
      if (!is.null(r$tool_calls)) {
        n_tools <- n_tools + length(r$tool_calls)
      }
    }
  }
} else {
  for (r in registros) {
    if (identical(r$type, "ai-title") && !is.null(r$aiTitle)) ai_title <- r$aiTitle
    if (!identical(r$type, "user") && !identical(r$type, "assistant")) next
    if (is.null(r$message)) next
    if (!is.null(r$timestamp)) {
      t <- parse_ts(r$timestamp)
      if (is.null(ts_ini) || t < ts_ini) ts_ini <- t
      if (is.null(ts_fim) || t > ts_fim) ts_fim <- t
    }
    if (identical(r$type, "assistant")) {
      if (is.na(modelo) && !is.null(r$message$model)) modelo <- r$message$model
      if (is.na(versao) && !is.null(r$version)) versao <- r$version
      if (is.na(branch) && !is.null(r$gitBranch)) branch <- r$gitBranch
      cont <- r$message$content
      if (is.list(cont)) {
        tipos <- vapply(cont, function(b) b$type %||% "", character(1))
        n_tools <- n_tools + sum(tipos == "tool_use")
        if (any(tipos == "text")) n_asst <- n_asst + 1L
      }
    } else {
      cont <- r$message$content
      eh_tool_result <- is.list(cont) &&
        all(vapply(cont, function(b) identical(b$type %||% "", "tool_result"), logical(1)))
      if (!eh_tool_result) n_user <- n_user + 1L
    }
  }
}

if (is.null(ts_ini)) stop("Nenhuma mensagem com timestamp/created_at encontrada no arquivo.")

slug <- if (!is.na(slug_arg)) {
  slug_kebab(slug_arg)
} else if (!is.na(ai_title)) {
  slug_kebab(ai_title)
} else {
  paste0("sessao-", substr(uuid_sessao, 1, 8))
}
if (slug == "") slug <- paste0("sessao-", substr(uuid_sessao, 1, 8))

# ── Corpo ─────────────────────────────────────────────────────────────────────
buf <- new.env()
buf$linhas <- vector("list", 0L)
push <- function(...) {
  novas <- unlist(list(...), use.names = FALSE)
  buf$linhas[[length(buf$linhas) + 1L]] <- novas
}

dur <- difftime(ts_fim, ts_ini, units = "hours")

if (is_antigravity) {
  push(
    paste0("# Conversa com Antigravity — ", if (!is.na(ai_title)) ai_title else slug),
    "",
    paste0("> **Sessão**: `", uuid_sessao, "`  "),
    paste0("> **Fonte**: `", sanitizar_caminhos(normalizePath(arquivo_jsonl, winslash = "/")), "`  "),
    paste0(
      "> **Início**: ", fmt_local(ts_ini), " — **Fim**: ", fmt_local(ts_fim),
      " (", FUSO, "; duração ", round(as.numeric(dur), 1), " h)  "
    ),
    paste0(
      "> **Modelo**: ", modelo, " — Antigravity ", versao,
      " — branch `", branch, "`  "
    ),
    paste0(
      "> **Volume**: ", n_user, " mensagens do usuário, ", n_asst,
      " respostas do assistente, ", n_tools, " chamadas de ferramenta.  "
    ),
    paste0("> Exportado em ", fmt_local(Sys.time()), " por `export_conversa.R`."),
    ""
  )

  papel_atual <- ""
  for (r in registros) {
    ts_txt <- if (!is.null(r$created_at)) fmt_local(parse_ts(r$created_at)) else "sem hora"

    if (identical(r$type, "USER_INPUT")) {
      if (nzchar(papel_atual)) push("---", "")
      push(paste0("### [", ts_txt, "] Usuário"), "", r$content, "")
      papel_atual <- "Usuário"
    } else if (identical(r$type, "CHECKPOINT")) {
      if (nzchar(papel_atual)) push("---", "")
      push(paste0("## 📦 [", ts_txt, "] Resumo de compactação de contexto"), "", r$content, "")
      papel_atual <- "Usuário"
    } else if (identical(r$type, "PLANNER_RESPONSE")) {
      if (nzchar(papel_atual)) push("---", "")
      if (!is.null(r$content) && nzchar(trimws(r$content))) {
        push(paste0("### [", ts_txt, "] Antigravity"), "", r$content, "")
      } else {
        push(paste0("### [", ts_txt, "] Antigravity (Chamadas de ferramenta)"), "")
      }
      papel_atual <- "Antigravity"

      if (!is.null(r$tool_calls) && length(r$tool_calls) > 0) {
        for (tc in r$tool_calls) {
          nome <- tc$name %||% "?"
          params <- tryCatch(
            toJSON(tc$args, pretty = TRUE, auto_unbox = TRUE),
            error = function(e) "«parâmetros não serializáveis»"
          )
          push(paste0("> 🔧 **", nome, "**"), "")
          push(bloco_details("parâmetros", as.character(params), "json"))
        }
      }
    } else if (r$type %in% c("VIEW_FILE", "RUN_COMMAND", "ASK_QUESTION", "GREP_SEARCH", "LIST_DIR", "SEARCH_WEB", "READ_URL_CONTENT", "WRITE_TO_FILE", "REPLACE_FILE_CONTENT", "ASK_PERMISSION", "BROWSER_SUBAGENT")) {
      rotulo <- paste0("resultado (", tolower(r$type), ")")
      corpo <- r$content %||% ""
      push(bloco_details(rotulo, corpo))
    }
  }
} else {
  push(
    paste0("# Conversa com Claude — ", if (!is.na(ai_title)) ai_title else slug),
    "",
    paste0("> **Sessão**: `", uuid_sessao, "`  "),
    paste0("> **Fonte**: `", sanitizar_caminhos(normalizePath(arquivo_jsonl, winslash = "/")), "`  "),
    paste0(
      "> **Início**: ", fmt_local(ts_ini), " — **Fim**: ", fmt_local(ts_fim),
      " (", FUSO, "; duração ", round(as.numeric(dur), 1), " h)  "
    ),
    paste0(
      "> **Modelo**: ", modelo, " — Claude Code ", versao,
      " — branch `", branch, "`  "
    ),
    paste0(
      "> **Volume**: ", n_user, " mensagens do usuário, ", n_asst,
      " respostas do assistente, ", n_tools, " chamadas de ferramenta.  "
    ),
    paste0("> Exportado em ", fmt_local(Sys.time()), " por `export_conversa.R`."),
    ""
  )

  papel_atual <- ""
  for (r in registros) {
    if (!identical(r$type, "user") && !identical(r$type, "assistant")) next
    if (is.null(r$message)) next
    cont <- r$message$content
    ts_txt <- if (!is.null(r$timestamp)) fmt_local(parse_ts(r$timestamp)) else "sem hora"

    eh_compact <- isTRUE(r$isCompactSummary)
    so_tool_result <- is.list(cont) && length(cont) > 0 &&
      all(vapply(cont, function(b) identical(b$type %||% "", "tool_result"), logical(1)))
    papel <- if (identical(r$type, "assistant")) {
      "Claude"
    } else if (so_tool_result) {
      papel_atual
    } else {
      "Usuário"
    }
    if (isTRUE(r$isSidechain)) papel <- paste0(papel, " (subagente)")

    if (eh_compact) {
      if (nzchar(papel_atual)) push("---", "")
      push(paste0("## 📦 [", ts_txt, "] Resumo de compactação de contexto"), "")
      papel_atual <- "Usuário"
    } else if (!identical(papel, papel_atual)) {
      if (nzchar(papel_atual)) push("---", "")
      push(paste0("### [", ts_txt, "] ", papel), "")
      papel_atual <- papel
    }

    if (is.character(cont)) {
      txt <- paste(cont, collapse = "\n")
      if (grepl("<command-name>|<local-command", txt)) {
        push(paste0("> ", gsub("\n", "\n> ", txt)), "")
      } else {
        push(txt, "")
      }
      next
    }
    if (!is.list(cont)) next

    for (b in cont) {
      tipo <- b$type %||% ""
      if (tipo == "text") {
        txt <- b$text %||% ""
        if (nzchar(trimws(txt))) push(txt, "")
      } else if (tipo == "thinking") {
        corpo <- b$thinking %||% ""
        if (nzchar(trimws(corpo))) {
          push(
            "<details>",
            "<summary>🧠 Raciocínio interno</summary>",
            "", corpo, "", "</details>", ""
          )
        }
      } else if (tipo == "tool_use") {
        nome <- b$name %||% "?"
        params <- tryCatch(
          toJSON(b$input, pretty = TRUE, auto_unbox = TRUE),
          error = function(e) "«parâmetros não serializáveis»"
        )
        push(paste0("> 🔧 **", nome, "**"), "")
        push(bloco_details("parâmetros", as.character(params), "json"))
      } else if (tipo == "tool_result") {
        corpo <- texto_de_tool_result(b$content)
        rotulo <- if (isTRUE(b$is_error)) "resultado (ERRO)" else "resultado"
        push(bloco_details(rotulo, corpo))
      } else if (tipo == "document") {
        push("*[documento anexado]*", "")
      }
    }
  }
}

# ── Escrita (UTF-8 sem BOM) ───────────────────────────────────────────────────
sufixo_fonte <- if (is_antigravity) "_conversa-antigravity" else "_conversa-claude"
nome_base <- paste0(fmt_local(ts_ini, "%Y-%m-%d_%H%M"), "_", slug, sufixo_fonte)
arquivo_saida <- file.path(PASTA_SAIDA, paste0(nome_base, ".md"))
v <- 2L
while (file.exists(arquivo_saida)) {
  arquivo_saida <- file.path(PASTA_SAIDA, paste0(nome_base, "_v", v, ".md"))
  v <- v + 1L
}

con <- file(arquivo_saida, open = "w", encoding = "UTF-8")
writeLines(sanitizar_caminhos(unlist(buf$linhas, use.names = FALSE)), con)
close(con)

cat("✅ Conversa exportada:", normalizePath(arquivo_saida, winslash = "/"), "\n")
cat("   Período coberto:", fmt_local(ts_ini), "→", fmt_local(ts_fim), "\n")
cat("   ", n_user, "msgs usuário |", n_asst, "respostas |", n_tools, "chamadas de ferramenta\n")
