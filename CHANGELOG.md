# CHANGELOG (derivado)

Derivado do `git log` por `tools/render-changelog.R`. Commit mais recente incluído: 2026-07-31 09:58.

Arquivo DERIVADO do `git log`. Não edite à mão — a fonte editorial é o `NEWS.md`,
e a fonte dos hashes é o Git. Ver o cabeçalho do script para o porquê.

## Added

- **`[97a37d8]` 2026-07-31 09:58** — feat(changelog): gera e versiona CHANGELOG.md derivado do git log
- **`[c1e2106]` 2026-07-30 21:50** — feat(governance): valida conteudo do NEWS.md e adiciona commit-msg
- **`[8009fdd]` 2026-07-28 14:33** — feat(governance): parametrize GOV_DIR — config-driven diretorio_governanca in skills and R tools
- **`[5fa9b59]` 2026-07-27 23:30** — feat(governance): indireção real do diretório de governança (WP3) e plano de migração AGENTS.md
- **`[91e95be]` 2026-07-17 10:32** — feat(governance): disable-model-invocation=false em grill-me/grill-with-docs/edit-article
- **`[3d90dc6]` 2026-07-14 12:28** — feat(governance): revert disable-model-invocation, add 5 mattpocock/skills after triage
- **`[37c28f8]` 2026-07-14 12:18** — feat(governance): reference superpowers global skills in sync-skills, close active plan
- **`[6ca8b9a]` 2026-07-14 09:58** — feat(governance): establish shared-skills mother repo, definitive TODO.md convention, fix stale .agents junction
- **`[4a4bb87]` 2026-07-13 23:35** — feat: introduce TODO.md governance strategy
- **`[68b3cf8]` 2026-07-12 23:55** — feat(governance): add T1-T4 reproducibility gates, ACMR filter, and numeric comments parser safety in template

## Fixed

- **`[a0120ea]` 2026-07-30 22:10** — fix(export): sanitiza caminhos absolutos, que o proprio T1 bloqueia
- **`[684d82b]` 2026-07-29 15:46** — fix(setup): adiciona BOM ao setup.ps1 — PowerShell 5.1 lia o arquivo como ANSI
- **`[5e6e5c2]` 2026-07-15 12:07** — fix(governance): relocate hard-link self-heal backups from repo root to 9-vers/backups/
- **`[91e23a7]` 2026-07-12 13:10** — fix(hooks): clear locale vars in pre-commit before running Rscript

## Changed

- **`[1efa82d]` 2026-07-31 09:35** — docs(principles): reune os principios do template e sua origem
- **`[c76f800]` 2026-07-30 22:12** — docs(review): ajusta comentario do commit-msg e formatacao do NEWS.md
- **`[8a50fbb]` 2026-07-29 15:40** — refactor(governance): AGENTS.md vira o arquivo real e único; fim dos hard links (WP1+WP2)
- **`[d0ae954]` 2026-07-28 14:44** — chore(todo): promote diretorio_governanca task from Prospectivo to Concluído
- **`[30a9236]` 2026-07-28 08:21** — docs(plan): registra decisão adiada sobre dividir a pasta e reenquadra WP11 para prevenção
- **`[9bff442]` 2026-07-28 08:02** — docs(plan): seção COMECE AQUI com estado real, decisões e armadilhas
- **`[9fc1abc]` 2026-07-28 07:56** — docs(plan): adiciona WP11 (caminhos absolutos) e nota sobre relógio divergente
- **`[f241ea4]` 2026-07-28 01:58** — chore(governance): fix stale absolute paths, drop orphaned 0-governance/, propose config-driven governance-dir plan
- **`[b524dff]` 2026-07-28 00:25** — chore(skills): primeira sincronização com a nova mãe e correção de performance do relatório
- **`[1cb784b]` 2026-07-28 00:17** — refactor(governance): template vira consumidor de skills; sync-skills compara conteúdo normalizado
- **`[40bc2d6]` 2026-07-27 20:28** — Revert "refactor(governance): standardize governance directory from 9-vers to 0-governance"
- **`[78b5315]` 2026-07-27 20:25** — refactor(governance): standardize governance directory from 9-vers to 0-governance
- **`[feb55a1]` 2026-07-27 15:48** — docs(governance): add English hard link non-interference rule for AI agents
- **`[1496758]` 2026-07-27 15:41** — docs(governance): estabelece regra estrita proibindo agentes de perder tempo recriando hard links manualmente
- **`[a328e64]` 2026-07-14 12:43** — docs(governance): fix scope of superpowers skills catalog - move from sync-skills to CLAUDE.md with machine-caveat
- **`[164c0de]` 2026-07-14 11:30** — revert(governance): remove disable-model-invocation from close-task/git-cleanup/sync-skills per author decision
- **`[17bfb17]` 2026-07-14 11:09** — refactor(governance): add disable-model-invocation to consequential skills, align request-audit findings format with native /code-review
- **`[942f6de]` 2026-07-14 10:56** — refactor(governance): rename skills to English, make them config-driven via CLAUDE.md, add pdf-text-extractor to shared mechanism
- **`[5938ec7]` 2026-07-13 22:45** — chore: finalização da tarefa sincronizacao-governanca
- **`[5a92666]` 2026-07-12 20:09** — chore(governance): add prominent critical rules warning at top of CLAUDE.md
- **`[450ffe2]` 2026-07-12 13:06** — Initial commit: governance boilerplate for human-AI repositories

