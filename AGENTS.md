# AGENTS.md — [NOME DO SEU PROJETO]

> **REGRAS CRÍTICAS DE GOVERNANÇA (COVENANT)**
> 0. **Regra 0 (Arquivo Único):** `AGENTS.md` é o único arquivo de instruções deste repositório, e é o arquivo real. `CLAUDE.md` contém apenas `@AGENTS.md` — nunca escreva conteúdo nele. Não existem hard links, cópias espelhadas, `.github/copilot-instructions.md` nem `.cursor/rules/`: Claude Code, Copilot e Cursor leem o padrão aberto `AGENTS.md` diretamente.
> 1. **Regra 1 (Auditoria):** Toda alteração é auditada. Execute `Rscript tools/validate-governance.R` antes de cada commit.
> 2. **Regra 2 (Notícia do NEWS):** Qualquer modificação em código-fonte ou textos exige atualização co-commit no `NEWS.md` com bloco de Metadados de Execução.
> 3. **Regra 3 (Exportação de Sessão):** Ao concluir uma tarefa, exporte o log da sessão via `Rscript tools/export_conversa.R <id> [slug]`.
> 4. **Regra 4 (Proibição de Staging em Massa):** NUNCA execute `git add .` ou `git add -A`. Use staging cirúrgico especificando arquivos (`git add <file>`). Use `tools/git-wrapper.ps1` ou `tools/git-wrapper.sh` como proxy CLI.
> 5. **Regra 5 (Convenção de Commits):** Commits devem seguir Conventional Commits (`<tipo>(<escopo>): <descrição>`).
> 6. **Regra 6 (Sem Emojis):** Uso estritamente proibido de emojis em documentos de governança, NEWS.md, commit messages e código.

---

## Estado Atual do Projeto

> **Esta seção é a única fonte da verdade sobre a concepção ATUAL do repositório.**

- **Descrição Geral**: [Descreva em 1 ou 2 parágrafos o objetivo e escopo do projeto.]
- **Arquitetura / Componentes**:
  - `tools/`: Scripts de QA (`validate-governance.R`), renderizadores (`render-changelog.R`) e wrappers CLI (`git-wrapper.ps1`, `git-wrapper.sh`).
  - `hooks/`: Git hooks de pre-commit e commit-msg.
  - `0-meta/` ou `9-vers/`: Diretório de governança (planos, llm-reviews, backups).
- **Proibições Estritas**:
  - Nunca execute staging em massa (`git add .`, `git add -A`).
  - Nunca descarte alterações não comitadas com `git reset --hard` ou `git restore .`.
- **Planos ativos**: consulte o índice de status em `0-meta/plan/README.md` (ou `9-vers/plan/README.md`).

---

## Protocolo de Leitura e Mapa de Documentos

| Documento | Público | Função |
|---|---|---|
| `AGENTS.md` | Agentes | Regras ativas do Covenant, comandos e mapa do repositório |
| `CLAUDE.md` | Agentes | Arquivo de ponteiro contendo apenas `@AGENTS.md` |
| `NEWS.md` | Ambos | Diário intelectual e changelog de decisões |
| `CHANGELOG.md` | Ambos | Índice de commits derivado automaticamente via `tools/render-changelog.R` |
| `TODO.md` | Ambos | Log de tarefas pendentes, prospectivas e concluídas |

---

## Comandos Canônicos (Cheat Sheet)

| Ação | Comando | Notas |
|---|---|---|
| **Validar Governança** | `Rscript tools/validate-governance.R [--sync]` | Valida integridade (0 = PASS) |
| **Gerar Changelog** | `Rscript tools/render-changelog.R` | Deriva `CHANGELOG.md` do git log |
| **Exportar Conversa** | `Rscript tools/export_conversa.R <id> [slug]` | Salva sessão no diretório de governança |
| **Sincronizar Skills** | `.\tools\sync-skills.ps1 [-Apply <skill|all>]` | Relatório ou aplicação de skills do template |

---

## Configuração de Skills (Skill Configuration)

> As skills de governança são **idênticas em todo repositório que as usa** e nunca hardcodeiam caminho ou convenção de projeto: elas leem os valores desta tabela. **As chaves são definidas pelas skills; o valor de cada linha é deste projeto.** Remover esta seção quebra as skills, que referenciam `{gov}` sem outra definição. Preencha ao adotar o template.

| Chave | Usada por | Valor neste repositório |
|---|---|---|
| `diretorio_governanca` | `close-task`, `export-conversation`, `git-cleanup`, `request-audit`, `tools/*.R` | `9-vers/`. Consumidores que usam outro nome (`0-meta/`) declaram o seu aqui. Nas skills, lido **desta tabela** pela convenção `{gov}`. Nos scripts R a resolução é automática: **(1)** env var `GOV_DIR`; **(2)** detecção em disco (`0-meta` → `9-vers`); **(3)** fallback |
| `script_exportar_conversa` | `close-task`, `export-conversation` | `tools/export_conversa.R` |
| `diretorio_autoria_primaria` | `close-task`, `git-cleanup` | [PLACEHOLDER — pasta de prosa/notebooks de autoria humana que agentes não devem comitar sem autorização] |
| `arquivo_gerenciado_externamente` | `git-cleanup` | [PLACEHOLDER — arquivo escrito por ferramenta externa (biblioteca de citação, lockfile, schema gerado); nunca editar manualmente] |
| `diretorios_trabalho_continuo` | `git-cleanup` | [PLACEHOLDER — pastas onde commits em série são normais, para agrupar em vez de tratar arquivo isolado] |
