# ==============================================================================
# git-wrapper.ps1 — Interceptador CLI e Trava Anti-Destrutiva do Git
# ==============================================================================
# Uso no PowerShell:
#   .\tools\git-wrapper.ps1 add .
#   .\tools\git-wrapper.ps1 commit -m "..."
#
# Escopo: uso INTERATIVO por humanos que escolhem chamar o wrapper.
# Para agentes, a trava que de fato interpoe e o hook PreToolUse em
# .claude/settings.json, que chama tools/guard-git-command.sh antes do Bash
# executar — um agente chama 'git' direto e nunca passaria por aqui.
# Os dois cobrem o mesmo conjunto; mantenha-os em sincronia.
# ==============================================================================

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
)

if (-not $GitArgs -or $GitArgs.Count -eq 0) {
    git.exe
    exit $LASTEXITCODE
}

function Deny-Command {
    param([string]$Titulo, [string]$Alternativa)
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "[ERRO FATAL T-GIT-WRAPPER] $Titulo" -ForegroundColor Red
    Write-Host ""
    Write-Host $Alternativa -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Red
    exit 1
}

$firstArg = $GitArgs[0].ToLower()
$rest = @($GitArgs | Select-Object -Skip 1)

# Casa aglomerados de flags curtas (-fdx, -xdf) e nao apenas a forma exata:
# a revisao do PR #12 mostrou que comparar contra '-fd'/'-f' deixava passar
# 'git clean -fdx', a forma mais destrutiva do comando.
# NAO nomear o parametro como $Args: colide com a variavel automatica do
# PowerShell e a funcao passa a receber vazio, fazendo a trava nunca disparar
# (bug real, encontrado ao testar 'git clean -fdx' nesta rodada).
function Test-ShortFlag {
    param([string[]]$Flags, [string]$Letter)
    foreach ($a in $Flags) {
        if ($a -match "^-[A-Za-z]*$Letter[A-Za-z]*$") { return $true }
        if ($a -eq "--force") { return $true }
    }
    return $false
}

switch ($firstArg) {
    "add" {
        # '-u' faz stage de todos os rastreados: e staging em massa ainda que
        # nao pareca. Estava fora da versao original desta trava.
        $massa = $rest | Where-Object {
            $_ -eq "." -or $_ -eq "*" -or $_ -eq ":/" -or $_ -eq "--all" -or
            $_ -match "^-[A-Za-z]*[Au][A-Za-z]*$"
        }
        if ($massa) {
            Deny-Command "Staging em massa proibido." `
                "Use staging cirurgico, um arquivo por vez: git add caminho/do/arquivo.ext"
        }
    }
    "reset" {
        if ($rest -contains "--hard") {
            Deny-Command "'git reset --hard' descarta trabalho nao comitado." `
                "Prefira 'git stash' ou reverta arquivos especificos."
        }
    }
    "clean" {
        if (Test-ShortFlag -Flags $rest -Letter "f") {
            Deny-Command "'git clean' com -f apaga arquivos nao rastreados." `
                "Rode 'git clean -n' primeiro para ver o que seria apagado."
        }
    }
    { $_ -in @("restore", "checkout") } {
        if ($rest -contains "." -or $rest -contains ":/") {
            Deny-Command "Descarte em massa de alteracoes no working tree." `
                "Restaure arquivos especificos: git restore caminho/do/arquivo.ext"
        }
    }
    "push" {
        # Nao estava coberto pela versao original (lacuna da revisao do PR #12).
        if (Test-ShortFlag -Flags $rest -Letter "f") {
            Deny-Command "Force-push reescreve historico ja publicado." `
                "Se for mesmo necessario, o autor humano deve autorizar e executar manualmente."
        }
    }
}

# Executar o git real
git.exe @GitArgs
exit $LASTEXITCODE
