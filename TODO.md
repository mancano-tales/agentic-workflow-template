# TODO — Registro de Pendências (Governança Append-Only)

> **Regra de Governança:** este arquivo **nunca** tem itens apagados. Itens concluídos são **movidos** (não editados retroativamente) para o topo de "Concluído" — log cronológico, mais recente primeiro, igual ao `NEWS.md`. Todo item registra data+hora de criação (`YYYY-MM-DD HH:MM`, horário local) e quem criou (agente e humano); ao concluir, soma-se data+hora e quem concluiu. Itens complexos (múltiplas etapas, decisão arquitetural) linkam o plano correspondente em `9-vers/plan/YYYY-MM-DD_Plano_*.md` — o TODO é o índice curto, o plano é o detalhe. Agentes de IA devem consultar este arquivo ao iniciar rodadas complexas de planejamento, para alinhamento com a agenda pendente **e** prospectiva.
>
> **Três seções**: "Pendente" = pronto para ser trabalhado agora. "Prospectivo" = identificado mas não pronto ainda (falta decisão, depende de outra tarefa, ou é backlog de menor prioridade) — quando ficar pronto, é **movido** para o topo de "Pendente" preservando a data de criação original (não reescreve, só relocaliza e anota a promoção). "Concluído" = feito.

## Pendente

- [ ] Documentar referências, inspirações e diferenciais do template frente a projetos similares e padrões de governança
  - Criado: 2026-07-31 10:43 por Antigravity (Gemini 3.6 Flash) (a pedido de Tales Mançano)
  - Criar documento/seção de referência no repositório detalhando origens, dependências conceituais e diferenciais em relação a outros projetos:
    - **Conventional Commits 1.0.0**: especificação e repositório oficial (`conventional-commits/conventionalcommits.org`)
    - **Keep a Changelog 1.1.0**: especificação por Olivier Lacan (`olivierlacan/keep-a-changelog`)
    - **Governança de Agentes de IA (mgaldino)**: repositórios e iniciativas de workflow agêntico de Manoel Galdino (`mgaldino`)
    - **Governança de Agentes de IA (Microsoft)**: `microsoft/agent-governance-toolkit`, diretrizes de governança de agentes de IA e ecossistema da Microsoft

- [ ] Propagar WP1/WP2 (fim dos hard links) aos outros 11 repositórios
  - Criado: 2026-07-29 15:36 por Claude Opus 5 (a pedido de Tales Mançano)
  - Feito **só neste repositório** em 2026-07-29: `AGENTS.md` virou o arquivo real e único, `CLAUDE.md` virou `@AGENTS.md`, `.github/copilot-instructions.md` e `.cursor/rules/` deletados, self-heal removido do validador
  - **Obrigatório em cada repo**: corrigir também `setup.ps1`/`setup.sh`. Eles recriam os hard links — se ficarem para trás, a primeira execução do setup desfaz a migração em silêncio
  - Não depende mais do WP0/Developer Mode: a solução adotada não usa link de espécie alguma
  - Plano: `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md` § WP1, WP2

- [ ] Exportar o log da sessão web que executou `2026-07-28_Plano_Config_Diretorio_Governanca.md`
  - Criado: 2026-07-29 15:36 por Claude Opus 5 (a pedido de Tales Mançano)
  - O plano está `CONCLUÍDO` sem log de conversa correspondente — o `validate-governance.R` acusa isso a cada execução, e é o único achado aberto dele hoje
  - **O transcript não está nesta máquina**: a sessão rodou no Claude Code web (Sonnet 4.6, commits `8009fdd`/`d0ae954`) e não deixou `.jsonl` em `~/.claude/projects/`. O autor mantinha a sessão aberta e vai pedir a ela que rode o exportador do próprio ambiente
  - Ao chegar o arquivo: registrar a linha correspondente em `9-vers/llm-reviews/README.md` § Inventário, no mesmo commit

- [ ] Promover à mãe (`skills`) a convenção `{gov}` das 4 skills de governança
  - Criado: 2026-07-29 08:45 por Claude Opus 5 (a pedido de Tales Mançano)
  - Motivo: o merge de 2026-07-29 trouxe do `main` a substituição de `9-vers/` por `{gov}` em `close-task`, `export-conversation`, `git-cleanup` e `request-audit`. São boas mudanças, mas foram feitas **localmente** — e desde 2026-07-28 este template é *consumidor* de skills, não a mãe. Sem promoção, o próximo `sync-skills --apply` sobrescreve as quatro e a melhoria se perde
  - Efeito colateral enquanto aberto: as 4 skills divergem da mãe, então o relatório do `sync-skills` vai acusá-las como desatualizadas — não é erro, é esta pendência

- [ ] Executar os WPs restantes do plano de migração AGENTS.md / indireção de governança (WP5, WP7–WP11) nos 12 repositórios
  - Criado: 2026-07-27 21:49 por Claude Opus 5 (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md`
  - ~~Bloqueio imediato: WP0 é ação humana (Developer Mode)~~ **Desbloqueado em 2026-07-29**: WP0 virou SUPERADO e WP1/WP2 foram feitos neste repo sem symlink. A propagação aos demais repos tem item próprio no topo desta seção
  - Prioridade dentro do WP3: `cha-affirmative-action-us-brazil` e `MancanoSync` raiz primeiro (bug real de export fora do git), depois os repositórios `9-vers` (prevenção)

- [ ] Decidir: manter `tools/export_conversa.R` ou adotar SpecStory para a trilha de conversas
  - Criado: 2026-07-27 21:49 por Claude Opus 5 (a pedido de Tales Mançano)
  - Motivo de estar aberto: autor instalou a extensão do SpecStory em 2026-07-27 e está testando
  - Ressalva levantada na análise: as integrações do SpecStory são Cursor e VS Code+Copilot; **não cobre Antigravity**, que hoje gera 2 dos 3 exports deste repositório. Dado observado: uma única sessão gerou 402KB em `.specstory/history/`, contra 309KB somados das duas sessões já arquivadas em `9-vers/llm-reviews/`
  - Plano: `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md` § WP9

- [ ] Tarefa inicial do seu projeto...
  - Criado: YYYY-MM-DD HH:MM por [Nome do Agente] (a pedido de [Nome do Autor Humano])
  - Plano: `9-vers/plan/...` (se houver)

## Prospectivo

- [ ] Tarefa identificada mas ainda não pronta para execução imediata...
  - Criado: YYYY-MM-DD HH:MM por [Nome do Agente] (a pedido de [Nome do Autor Humano])
  - Motivo de não estar em Pendente: [depende de X / decisão pendente / baixa prioridade]
  - Plano: `9-vers/plan/...` (se houver)

## Concluído

- [x] Promover a chave de configuração `diretorio_governanca` — tornar as 4 skills de governança e as ferramentas R config-driven, eliminando o hardcode de `9-vers/`
  - Criado: 2026-07-28 01:54 por Claude Opus 4.8 (a pedido de Tales Mançano)
  - Concluído: 2026-07-28 por Claude Sonnet 4.6 (Claude Code, web) (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-28_Plano_Config_Diretorio_Governanca.md`

- [x] Higiene pós-reversão/renomeação: corrigir caminhos absolutos obsoletos que apontavam para o nome antigo do repositório (`mancano-project-template`) em `GUIDANCE.md` e `.cursor/rules/governance.mdc`, e remover o diretório órfão `0-governance/` (só continha backups gitignorados) deixado pela padronização revertida
  - Criado: 2026-07-28 01:54 por Claude Opus 4.8 (a pedido de Tales Mançano)
  - Concluído: 2026-07-28 01:54 por Claude Opus 4.8 (a pedido de Tales Mançano)

- [x] Mover os backups do self-heal de hard link (`AGENTS.md.bak.*`/`CLAUDE.md.bak.*`) da raiz do repositório para `9-vers/backups/`, e apontar `tools/validate-governance.R` para escrever ali dali em diante — achado promovido de um repositório consumidor (`Nahoum-Mancano-2026-Antitrust`)
  - Criado: 2026-07-15 12:05 por Claude Sonnet 5 (a pedido de Tales Mançano)
  - Concluído: 2026-07-15 12:05 por Claude Sonnet 5 (a pedido de Tales Mançano)

- [x] Corrigir formato do TODO.md (ordem invertida, sem metadados) para o padrão Pendente/Concluído com data+hora, agente/humano e link de plano
  - Criado: 2026-07-13 23:50 por Antigravity (a pedido de Tales Mançano)
  - Concluído: 2026-07-14 09:10 por Claude Sonnet 5 (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`
- [x] Sincronizar governança do template com o estado da tese (T5/T6, parser YAML, migração de hooks, skills)
  - Criado: 2026-07-13 22:17 por Claude Sonnet 5 (a pedido de Tales Mançano)
  - Concluído: 2026-07-13 22:45 por Antigravity (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-13_Plano_Sincronizar_Governanca_Com_Tese.md`
