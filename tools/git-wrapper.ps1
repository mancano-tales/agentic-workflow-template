# ==============================================================================
# git-wrapper.ps1 — Interceptador CLI e Trava Anti-Destrutiva do Git
# ==============================================================================
# Uso no PowerShell:
#   .\tools\git-wrapper.ps1 add .
#   .\tools\git-wrapper.ps1 commit -m "..."
# ==============================================================================

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
)

if (-not $GitArgs -or $GitArgs.Count -eq 0) {
    git.exe
    exit $LASTEXITCODE
}

$firstArg = $GitArgs[0].ToLower()
$secondArg = if ($GitArgs.Count -gt 1) { $GitArgs[1].ToLower() } else { "" }

# 1. Bloqueio de Staging em Massa (git add . / git add -A / git add *)
if ($firstArg -eq "add") {
    if ($GitArgs -contains "." -or $GitArgs -contains "-A" -or $GitArgs -contains "--all" -or $GitArgs -contains "*") {
        Write-Host "======================================================================" -ForegroundColor Red
        Write-Host "[ERRO FATAL T-GIT-WRAPPER] STAGING EM MASSA PROIBIDO!" -ForegroundColor Red
        Write-Host "Comandos como 'git add .', 'git add -A' ou 'git add *' sao estritamente proibidos." -ForegroundColor Yellow
        Write-Host "Use staging cirurgico especificando cada arquivo:" -ForegroundColor Yellow
        Write-Host "  git add caminho/do/arquivo.ext" -ForegroundColor Cyan
        Write-Host "======================================================================" -ForegroundColor Red
        exit 1
    }
}

# 2. Bloqueio de Descarte Destrutivo sem autorização
if ($firstArg -eq "reset" -and $GitArgs -contains "--hard") {
    Write-Host "[ERRO FATAL T-GIT-WRAPPER] 'git reset --hard' e um comando destrutivo e proibido." -ForegroundColor Red
    exit 1
}

if ($firstArg -eq "clean" -and ($GitArgs -contains "-fd" -or $GitArgs -contains "-f")) {
    Write-Host "[ERRO FATAL T-GIT-WRAPPER] 'git clean' em massa e proibido sem confirmacao explicita do autor." -ForegroundColor Red
    exit 1
}

if ($firstArg -eq "restore" -and $GitArgs -contains ".") {
    Write-Host "[ERRO FATAL T-GIT-WRAPPER] 'git restore .' e proibido. Especifique o arquivo a restaurar." -ForegroundColor Red
    exit 1
}

# Executar o git real
git.exe @GitArgs
exit $LASTEXITCODE
