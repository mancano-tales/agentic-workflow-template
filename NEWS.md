# NEWS — Decisões de Design e Evolução Metodológica

> Entrada mais recente no topo.
> **Convenção de timestamp**: Todas as datas em cabeçalhos (## YYYY-MM-DD HH:MM) e no campo Data/Hora dos metadados DEVEM incluir hora e minuto no fuso local. Nunca use datas isoladas.

## 2026-07-31 11:13 — Por que Conventional Commits e Keep a Changelog são a mesma decisão

A pedido do autor, documentado no `PRINCIPLES.md` §4/§5 e numa nova Seção 5 do `README.md`.

**As duas convenções não são escolhas independentes — encaixam uma na outra.** O Conventional Commits exige um **tipo vindo de lista fechada** em toda mensagem; é exatamente isso que permite traduzir cada commit mecanicamente para uma categoria do Keep a Changelog. Sem tipo obrigatório não há tradução, e sem tradução o changelog volta a ser escrito à mão — com toda a divergência que o §4 descreve. A tabela de tradução (`feat`→`Added`, `fix`/`perf`→`Fixed`, os demais→`Changed`, `!`→`Breaking` sobrepondo-se ao tipo) passa a estar explícita nos dois documentos, em vez de existir apenas dentro do `render-changelog.R`.

**A distinção entre os três artefatos, que faltava.** Cada um responde a uma pergunta que os outros dois não respondem:

- **`git log`** tem o **fato** — completo, mecânico, um registro por commit, incluindo os triviais. Fonte dos hashes, e ilegível como narrativa.
- **`CHANGELOG.md`** tem o fato **organizado para o leitor** — uma projeção do `git log`, reagrupada por categoria. Não acrescenta informação; por isso pode ser gerado, e por isso editá-lo à mão cria uma segunda verdade que vai divergir.
- **`NEWS.md`** tem a **razão** — e a razão não é derivável de nada. Nenhuma ferramenta extrai de um diff qual alternativa foi cogitada e rejeitada, ou qual incidente motivou a mudança. Um commit `fix(export): sanitiza caminhos absolutos` diz o que foi feito; só o `NEWS.md` diz que aquilo nasceu de um log reprovado com 108 ocorrências pelo validador do próprio repositório.

A consequência que justifica a trava: **os dois primeiros se perdem se a ferramenta falhar; o `NEWS.md` se perde se ninguém escrever.** É o único dos três inteiramente dependente de disciplina — e é por isso que o co-commit é mecânico, não recomendação.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-31 11:13 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "docs(conventions): explica o encaixe entre commits e changelog"
- **Arquivos afetados**: `PRINCIPLES.md`, `README.md`, `NEWS.md`

## 2026-07-31 10:43 — Registro de pendência para mapear referências, inspirações e diferenciais do template

A pedido do autor. Adicionada pendência no `TODO.md` para criar uma seção/documento de referência detalhando as origens conceituais, inspirações e diferenciais do template frente a outros projetos e padrões de governança:
- **Conventional Commits 1.0.0** (`conventional-commits/conventionalcommits.org`)
- **Keep a Changelog 1.1.0** (`olivierlacan/keep-a-changelog`)
- **Governança de Agentes de IA (Manoel Galdino)** (`mgaldino`)
- **Governança de Agentes de IA (Microsoft)** (`microsoft/agent-governance-toolkit`, AutoGen, AI Agent Governance)

**Metadados de Execução**:
- **Data/Hora**: 2026-07-31 10:43 (Horário de Brasília)
- **Agente**: Antigravity / Gemini 3.6 Flash / Antigravity CLI
- **Mensagem do Commit**: "docs(todo): pendencia de mapeamento de referencias e inspiracoes"
- **Arquivos afetados**: `TODO.md`, `NEWS.md`

## 2026-07-31 09:57 — `CHANGELOG.md` derivado passa a ser versionado, e a geração vira determinística

**Decisão do autor.** A convenção adotada tem nome — **Keep a Changelog 1.1.0** — e passa a ser implementada em dois arquivos com papéis distintos: `NEWS.md` é a fonte **editorial**, escrita à mão, com decisão e raciocínio, sem hashes e nunca reescrita; `CHANGELOG.md` é **derivado** do `git log` por `render-changelog.R`, com hash e timestamp ISO-8601, regenerável e nunca editado à mão. Primeira geração: 34 entradas.

Isso resolve uma ambiguidade herdada da issue #1. Ela pedia rastreabilidade fina no formato `- **[a1b2c3d]** 2026-07-30 15:45 — Descrição`, e a rodada de 2026-07-30 22:45 recusou **apenas o hash escrito à mão**, por ser ponto fixo — mas ao parar aí deixou a impressão de que a rastreabilidade inteira tinha sido abandonada. Não tinha: só mudou de lugar. Versionando o `CHANGELOG.md`, o artefato que a issue #1 pedia passa a existir, no formato que ela pedia, visível para quem apenas navega o repositório — sem o laço impossível e sem os commits de backfill. O que se perdeu foi um campo copiado à mão que só podia divergir; o que se ganhou é a mesma informação como projeção de fonte única.

**Geração determinística — achado da revisão automática.** O cabeçalho gravava `Sys.time()`. Enquanto a saída ia para stdout isso era inofensivo; a partir do momento em que o arquivo é versionado, deixou de ser: **regenerar sem nenhuma mudança no histórico produzia um diff**, apenas porque o relógio andou. Um artefato derivado tem de ser função exclusiva da sua entrada — caso contrário `git diff` deixa de responder "algo mudou?" e passa a responder "alguém rodou o script?". O carimbo passa a ser o do commit mais recente incluído, que vem do próprio `git log`: informa a mesma coisa útil (até onde o changelog cobre) e é estável.

**Categorias documentadas passam a bater com as emitidas** — outro achado da revisão. O `PRINCIPLES.md` listava as seis do padrão; o renderer emite quatro (`Breaking`, `Added`, `Fixed`, `Changed`). `Deprecated`, `Removed` e `Security` **não são emitidas** porque nenhum tipo de Conventional Commit mapeia para elas sem adivinhação — `revert` não é remoção, e não há tipo para depreciação ou segurança. Inferi-las produziria classificação errada com aparência de precisão. Seguem disponíveis no `NEWS.md`, onde um humano as escolhe deliberadamente.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-31 09:57 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "fix(changelog): torna a geracao deterministica e alinha as categorias"
- **Arquivos afetados**: `CHANGELOG.md`, `tools/render-changelog.R`, `PRINCIPLES.md`, `README.md`, `NEWS.md`

## 2026-07-31 09:34 — `PRINCIPLES.md`: os princípios do template, reunidos e com a origem de cada um

A pedido do autor. Até aqui os princípios existiam **dispersos** — parte no `AGENTS.md`, parte implícita nas travas do validador, parte só recuperável lendo entradas antigas deste `NEWS.md`. Quem adotava o template recebia as regras sem a razão delas, e razão ausente é regra que o primeiro atrito descarta.

Oito princípios, cada um ancorado na falha que o originou: **policy-as-code** (prosa não é superfície de controle; falso bloqueio é problema de segurança), **transparência** (passo pulado e declarado é aceitável, pulado em silêncio corrompe a auditoria), **reprodutibilidade** (nenhum caminho absoluto; nada específico de projeto dentro de artefato compartilhado; cópia em vez de link), **changelog intelectual**, **Conventional Commits**, **arquivamento dos logs de LLM**, **plano antes de execução** e **uma peça, um dono**.

**Escolha de nome de arquivo, a confirmar com o autor**: `PRINCIPLES.md` e não `README.md`, porque o `README.md` deste repositório está redigido como README **do consumidor** (abre em `# [NOME DO SEU PROJETO]`, com placeholders a preencher por quem adota). O mesmo arquivo não consegue ser o README do template e o README que o template entrega. Alternativa, se o autor preferir: promover este documento a `README.md` e renomear o atual para `README.template.md`.

O documento registra também, sem maquiar, uma **questão em aberto**: a `close-task` pode ser tornada agnóstica ao repositório, mas invoca `validate-governance.R` e `export_conversa.R`, que vivem aqui — um agente pode resolver o diretório certo e entregá-lo a ferramentas que o descartam em silêncio. A fronteira entre `skills` e este template, como está desenhada, corta no meio de um problema único.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-31 09:34 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "docs(principles): reune os principios do template e sua origem"
- **Arquivos afetados**: `PRINCIPLES.md`, `README.md`, `NEWS.md`

## 2026-07-30 22:45 — Co-commit do NEWS.md, hook commit-msg e o fim do hash escrito à mão (issue #1)

Rodada motivada por uma auditoria adversária das travas do consumidor `cem-usp/edupol`, que revelou tanto lacunas deste template quanto uma regra de governança impossível de cumprir.

**T7 — co-commit e formato do NEWS.md.** Absorvido do `edupol`, que tinha a regra e este template não. Vai além do original em dois pontos. Primeiro, o original checava apenas **presença** do arquivo no index: um `NEWS.md` contendo a string `xxxxx` passava, o que reduzia a regra a ritual. Aqui as **linhas adicionadas** são validadas contra o formato Keep a Changelog. Segundo, a trava roda fora do guarda `length(staged_files) > 0`, então `git commit --allow-empty` não escapa mais.

**Contexto de hook agora é declarado, não inferido.** O `hooks/pre-commit` passa `--hook`. O consumidor `edupol` inferia o contexto por `is_git_staged_run <- length(staged_files) > 0`, e um commit vazio produzia lista vazia, fazendo o validador concluir que **não** estava rodando como hook e pular a trava do changelog inteira. Inferir contexto a partir de dados que o usuário controla é a forma errada de detectar contexto.

**O hash do commit no changelog é insatisfazível — regra em depreciação.** A issue #1 pedia entradas no formato `[hash] YYYY-MM-DD HH:MM`. Não dá: o hash é o SHA do conteúdo do commit, então gravá-lo em um arquivo que esse mesmo commit versiona altera o conteúdo e, portanto, o hash. É ponto fixo, não falha de implementação — `git commit --amend` só produz um hash novo, igualmente não registrado. No `edupol`, onde a regra foi adotada, o resultado foram seis commits `docs(news): backfill do hash` em um único dia, cada um corrigindo o anterior, nenhum registrando o próprio.

A saída é derivar em vez de armazenar: **`tools/render-changelog.R`** gera um CHANGELOG anotado a partir do `git log`, mapeando tipos de Conventional Commit para categorias do Keep a Changelog. O `NEWS.md` segue como fonte editorial, sem hashes; o Git segue como fonte dos hashes. O validador **avisa** — nunca bloqueia — ao ver hash escrito à mão numa entrada nova.

**`hooks/commit-msg`.** Valida Conventional Commits 1.0.0. Bloqueia o objetivamente verificável (forma do cabeçalho, tipo fora da lista, mais de 72 caracteres, ponto final, `BREAKING CHANGE:` sem `!`) e **apenas avisa** sobre descrição em gerúndio ou particípio, porque a heurística de sufixo não distingue verbo de substantivo: `estado`, `comando` e `pedido` seriam rejeitados indevidamente. Ignora `Merge`, `Revert`, `fixup!` e `squash!`, que o próprio Git gera.

**Trava de `llm-reviews` rebaixada a aviso.** Exigir log de conversa para plano concluído bloqueava o commit por um artefato que só existe depois da sessão. Uma trava reconhecidamente injusta é a que ensina o agente a usar `--no-verify` — o que desliga junto as travas legítimas. O princípio que orientou toda a rodada: **falso bloqueio é problema de segurança, não de conforto.**

**Válvula `GOVERNANCE_AMEND` para `git commit --amend`.** Encontrada testando a própria trava: um amend sem nada novo no stage tem index idêntico ao HEAD, então `staged_files` vem vazio e a T7 bloqueava um commit que **já continha** a entrada de changelog. Distinguir amend de commit vazio é impossível de dentro do `pre-commit` — a diferença está em qual commit será o pai do resultado, e o hook roda antes disso existir; `diff --cached HEAD^` acerta o amend e erra o `--allow-empty`, e `diff --cached HEAD` faz o inverso. Em vez de adivinhar, `GOVERNANCE_AMEND=1` declara a intenção e avalia contra `HEAD^`. É preferível a `--no-verify` porque nomeia o que está sendo dispensado, mantém todas as outras travas rodando e fica visível no histórico do shell.

**Limites que nenhuma dessas mudanças remove.** `--no-verify` desliga qualquer hook client-side; `core.hooksPath` é configuração local e não viaja no clone; e um hook versionado não se protege contra um commit que o substitua por `exit 0`. Todos os três foram comprovados por teste. Onde a garantia precisa ser real, a mesma validação tem de rodar no CI e ser exigida como status check na proteção de branch.

**Verificação.** Hook `commit-msg` testado contra 20 mensagens; trava T7 contra 5 cenários (sem `NEWS.md`, `--allow-empty`, conteúdo lixo, entrada válida, hash à mão), todos num clone descartável com os hooks ativos. Ausência de `MERGE_HEAD` foi configurada para não emitir aviso no fluxo normal.

## 2026-07-29 15:36 — Fim dos hard links: AGENTS.md vira o arquivo real e único (WP1 + WP2)

Decisão do autor, executada nesta rodada. O repositório mantinha **três cópias do mesmo texto** — `CLAUDE.md`, `AGENTS.md` e `.github/copilot-instructions.md` — amarradas por hard link e por um self-heal de ~130 linhas no validador. Agora:

- **`AGENTS.md` é o arquivo real e único.** Ganhou uma **RULE 0** no topo declarando isso e instruindo explicitamente a não recriar o self-heal.
- **`CLAUDE.md` contém uma linha**: `@AGENTS.md`, a sintaxe de import do Claude Code.
- **`.github/copilot-instructions.md` e `.cursor/rules/governance.mdc` foram deletados** (autorização expressa do autor). Copilot e Cursor leem o padrão aberto `AGENTS.md` diretamente.

**Mecanismo diferente do que o plano previa.** O WP1 dizia *symlink* `AGENTS.md → CLAUDE.md`, o que exigia o WP0 (ativar Developer Mode no Windows) e travava tudo atrás de uma ação humana. Arquivo real + ponteiro dispensa link de qualquer espécie: **o WP0 deixou de ser pré-requisito de qualquer coisa** e a solução funciona em qualquer sistema operacional sem privilégio — o que importa num template público com adotante externo.

**O passo que impede a migração de se desfazer sozinha**: `setup.ps1` e `setup.sh` **recriavam** os hard links. Sem corrigi-los, a primeira execução do setup desfaria tudo em silêncio. Agora eles garantem o ponteiro em vez de criar links, e **recusam-se a sobrescrever um `CLAUDE.md` que tenha conteúdo próprio** — avisam para migrar o conteúdo a mão em vez de destruí-lo. Registrado como armadilha no plano, porque vale para cada um dos 11 repositórios que faltam.

**Dois achados durante a execução:**

1. **O self-heal não era só obsoleto — era ativamente nocivo.** Seu ramo de guarda "timestamps muito próximos (<= 2s)" **abortava o validador inteiro** antes de qualquer checagem real rodar (medido ao vivo numa execução contra o `main`). Ou seja: a seção existia para proteger um link que ninguém deveria ter, e no caminho mascarava as travas legítimas. Com ela fora, o validador voltou a executar tudo.
2. **Um vertical tab (`0x0B`) corrompido no banner de regras críticas**, no lugar do "v" de `validate-governance.R` — por isso o texto lia "alidate-governance.R". Invisível na renderização e já propagado a todos os consumidores pelas cópias. Eliminado.

**Terceiro achado, medido:** `setup.ps1` **nunca teve BOM**, e o PowerShell 5.1 o lia como ANSI — as 11 linhas com acento do script saíam corrompidas na tela desde sempre. Confirmado com code points: sem BOM o interpretador lê `195,161,195,169` (os bytes UTF-8 de `áé` interpretados como CP1252); com BOM, lê `225,233`, correto. BOM adicionado. É a armadilha já registrada no plano para o `sync-skills.ps1`, que valia também aqui e ninguém havia notado.

Os quatro caminhos do novo bloco de setup foram testados isoladamente nas duas linguagens (ponteiro já correto / `CLAUDE.md` ausente / `CLAUDE.md` com conteúdo próprio / `AGENTS.md` ausente); o caso crítico — recusar-se a destruir um `CLAUDE.md` com conteúdo — preserva o arquivo com hash idêntico.

Também saiu o `make_backup_path()`/`PATH_BACKUP_DIR`, que ficou órfão (só o self-heal os usava). A seção 0c (junction `.agents` → `.claude`) foi **mantida**: trata do diretório de skills, assunto diferente.

**Escopo**: feito **apenas neste repositório**. Os outros 11 seguem com hard links — WP1/WP2 estão `parcial`, não concluídos.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-29 15:36 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "refactor(governance): AGENTS.md vira o arquivo real e único; fim dos hard links (WP1+WP2)"
- **Arquivos afetados**: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md` (deletado), `.cursor/rules/governance.mdc` (deletado), `tools/validate-governance.R`, `setup.ps1`, `setup.sh`, `README.md`, `9-vers/GUIDANCE_MAP.md`, `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md`, `NEWS.md`, `TODO.md`

## 2026-07-29 08:45 — Reconciliação de duas implementações paralelas do WP3 (merge de `main` na branch)

Duas sessões implementaram o **mesmo Work Package** sem saber uma da outra, a partir do mesmo ponto (`feb55a1`): a branch `agents/rename-agentic-research-to-workflow` (5 commits) e o `main` (6 commits). Este merge unifica as duas.

**A colisão real** estava na indireção do diretório de governança nos scripts R — dois mecanismos diferentes para o mesmo fim:

| | `main` (`8009fdd`) | branch (`5fa9b59`) |
|---|---|---|
| Mecanismo | `Sys.getenv("GOV_DIR", unset = "9-vers")` | detecção em disco (`0-meta` → `9-vers`) |
| Default num repo `0-meta/` | **errado** se ninguém setar a env var | correto |
| Override explícito | sim | não |

**Resolução (decisão do autor): combinar, nesta precedência** — (1) env var `GOV_DIR`; (2) detecção em disco; (3) fallback. Manter só a env var reintroduziria exatamente o modo de falha que motivou o WP4: em 2026-07-26 o `export_conversa.R` escreveu um export em `9-vers/llm-reviews/` dentro de um repositório que usa `0-meta/`, numa pasta gitignorada — o arquivo ficou fora do controle de versão e sem backup. A detecção garante default correto por omissão; a env var cobre nomes fora da lista de candidatos.

Duas resoluções menores no `validate-governance.R`: adotado o `startsWith` do `main` no filtro T6 (comparação literal, imune a `GOV_DIR` com metacaractere de regex) e a formatação da branch em `GOVERNANCE_DOCS` — conteúdo idêntico nos dois lados.

**Preservado do `main`, sem conflito** (trabalho genuinamente complementar): a convenção `{gov}` nas 4 skills de governança (`close-task`, `export-conversation`, `git-cleanup`, `request-audit`), que a branch não havia feito; a correção dos links `file:///` absolutos em `GUIDANCE.md` — que é literalmente o WP11; e as notas de configurabilidade em `9-vers/GUIDANCE_MAP.md` e `.cursor/rules/governance.mdc`.

**NEWS.md**: as 5 entradas dos dois lados foram preservadas e reordenadas cronologicamente — nenhuma reescrita.

**Pendência registrada.** As edições do `main` nas 4 skills foram feitas localmente, mas a decisão de 2026-07-28 tornou este template **consumidor** de skills (a mãe é o repo `skills`). Essas melhorias serão sobrescritas no próximo `sync-skills --apply` se não forem promovidas à mãe primeiro. Item adicionado ao `TODO.md`.

**Correção de fato**: a armadilha nº 1 da seção COMECE AQUI do plano de migração ("o relógio desta máquina está ~5h45 atrasado") foi **verificada com o autor e é falsa** — o relógio está correto. O aviso foi removido do plano para não induzir sessões futuras a erro.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-29 08:45 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "merge(governance): unifica as duas implementações paralelas do WP3 (GOV_DIR env var + detecção)"
- **Arquivos afetados**: `tools/validate-governance.R`, `tools/export_conversa.R`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`, `TODO.md`, `9-vers/plan/README.md`, `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md`

## 2026-07-28 — Parametrização config-driven do diretório de governança (execução do plano)

Execução do plano `2026-07-28_Plano_Config_Diretorio_Governanca.md` (aprovado pelo autor). As 4 tarefas foram concluídas:

1. **`CLAUDE.md` § Configuração de Skills** — adicionada a chave `diretorio_governanca` (`9-vers` como default da mãe; consumidores sobrescrevem com `GOV_DIR=<valor>`).
2. **4 skills de governança** (`close-task`, `export-conversation`, `git-cleanup`, `request-audit`) — todo literal `9-vers/` substituído por `{gov}`, com nota de convenção `{gov} = diretorio_governanca` adicionada no topo de cada skill. Decisão de design: referência pura (sem exemplo `(9-vers/)` embutido) — o valor só vive na tabela do `CLAUDE.md`, garantindo que o hash das skills seja idêntico entre repositórios mãe e consumidores.
3. **`tools/validate-governance.R`** — extraído `GOV_DIR <- Sys.getenv("GOV_DIR", unset = "9-vers")` no topo; todas as constantes de caminho (`PATH_PLAN_DIR`, `PATH_REVIEWS_INDEX`, `PATH_BACKUP_DIR`), o filtro T6 e a lista `GOVERNANCE_DOCS` derivam de `GOV_DIR`.
4. **`tools/export_conversa.R`** — idem: `GOV_DIR` extraído antes de `PASTA_SAIDA`.
5. **`9-vers/GUIDANCE_MAP.md` e `.cursor/rules/governance.mdc`** — nota de configurabilidade adicionada; `9-vers/` mantido como exemplo documentando o default da mãe.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-28 (Horário de Brasília — hora exata não recuperável no ambiente remoto)
- **Agente**: Claude Sonnet 4.6 / Claude Code (web, remote)
- **Mensagem do Commit**: "feat(governance): parametrize GOV_DIR — config-driven diretorio_governanca in skills and R tools"
- **Arquivos afetados**: CLAUDE.md, .claude/skills/close-task/SKILL.md, .claude/skills/export-conversation/SKILL.md, .claude/skills/git-cleanup/SKILL.md, .claude/skills/request-audit/SKILL.md, tools/validate-governance.R, tools/export_conversa.R, 9-vers/GUIDANCE_MAP.md, .cursor/rules/governance.mdc, 9-vers/plan/2026-07-28_Plano_Config_Diretorio_Governanca.md, NEWS.md

## 2026-07-28 01:54 — Higiene pós-reversão + plano para tornar as skills config-driven no diretório de governança

Rodada de refinamento e limpeza. Três correções de higiene, todas herança da renomeação do repositório (`mancano-project-template` → `agentic-research-template`) e da padronização de diretório que foi tentada e revertida (`78b5315` → `40bc2d6`):

1. **`GUIDANCE.md`** — os dois únicos documentos de governança ativos que ainda carregavam links `file:///` absolutos locais apontando para o **nome antigo do repositório** (`mancano-project-template`) foram convertidos para links Markdown relativos (`CLAUDE.md`, `9-vers/GUIDANCE_MAP.md`). É exatamente o tipo de vazamento que o T5 do `validate-governance.R` bloqueia — passavam batido só porque o T5 escaneia apenas linhas *adicionadas* e estas eram pré-existentes. Crítico num template feito para ser clonado.
2. **`.cursor/rules/governance.mdc`** — cabeçalho ainda dizia `(mancano-project-template)`; atualizado para `(agentic-research-template)`.
3. **Diretório órfão `0-governance/`** — a padronização revertida moveu os backups do self-heal para `0-governance/backups/`; o `git revert` restaurou o código (que volta a apontar para `9-vers/backups/`) mas não os arquivos gitignorados, deixando um `0-governance/` órfão contendo só `.bak.*`. Os 7 backups foram consolidados em `9-vers/backups/` (onde o código aponta) e o diretório órfão removido. Nenhum backup deletado; nada rastreado pelo git foi afetado (era tudo gitignorado).

Além da limpeza, foi **proposto** (não executado) o plano `2026-07-28_Plano_Config_Diretorio_Governanca.md` (status ATIVO, aguardando aprovação): promover a chave `diretorio_governanca` à § Configuração de Skills, tornando as 4 skills de governança (`close-task`, `export-conversation`, `git-cleanup`, `request-audit`) e as ferramentas R config-driven em vez de hardcodarem `9-vers/`. Motivação: o próprio `CLAUDE.md` proíbe hardcode de convenção de projeto nas skills, mas essas 4 violam isso — o que forçou o consumidor `MancanoSync` (que usa `0-meta/`) a manter um remendo textual ("leia `9-vers/` como `0-meta/`"). A refatoração não foi executada de propósito: é mudança arquitetural com efeito de propagação e a padronização física do diretório já foi revertida uma vez, então exige aprovação explícita do autor (§ Task Planning Policy).

**Metadados de Execução**:
- **Data/Hora**: 2026-07-28 01:54 (Horário Local)
- **Agente**: Claude Opus 4.8 / Claude Code / VS Code
- **Mensagem do Commit**: "chore(governance): fix stale absolute paths, drop orphaned 0-governance/, propose config-driven governance-dir plan"
- **Arquivos afetados**: `GUIDANCE.md`, `.cursor/rules/governance.mdc`, `9-vers/plan/2026-07-28_Plano_Config_Diretorio_Governanca.md`, `9-vers/plan/README.md`, `TODO.md`, `NEWS.md` (e `9-vers/backups/` consolidado, gitignorado)

## 2026-07-28 01:10 — Primeira sincronização real com a nova mãe; regressão de performance corrigida

Executado `sync-skills --apply all` contra o repositório `skills`, agora a mãe. As 11 skills deste template estão **em dia** com ela pela primeira vez desde que as duas passaram a coexistir.

**Achado durante a sincronização.** O `sync-skills/SKILL.md` que veio da mãe ainda descrevia `agentic-research-template` como repositório mãe, em três lugares — inclusive no passo que instrui o consumidor a **promover melhorias de volta**. Um consumidor seguindo aquela skill mandaria a correção para o repositório errado. Corrigido na mãe (`skills@8a0f246`) e puxado de volta para cá, o que exercitou o ciclo mãe→consumidor de ponta a ponta.

**Regressão de performance, introduzida e corrigida na mesma rodada.** A normalização de conteúdo custa processos por arquivo, e o relatório hasheava as 101 skills da mãe — 90 delas não instaladas aqui e portanto com hash que nunca seria comparado com nada. O primeiro `--apply all` estourou 120 segundos. Corrigido pulando o hash quando a skill não existe localmente: **29 segundos**, e o resultado é idêntico. A lição vale registrar: o custo estava em trabalho que o próprio desenho novo do relatório já tinha tornado desnecessário.

Criado `tools/.skills-source` apontando para `../skills` — este template nunca teve o arquivo porque era a mãe. Na mesma rodada, o `.skills-source` da raiz `MancanoSync` foi corrigido: apontava para `./agentic-research-template`, a mãe antiga.

**Nota para worktrees**: a detecção automática resolve a mãe como pasta irmã, o que não funciona de dentro de um worktree (`repo.worktrees/branch/`). Use `--source` explícito nesse caso.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-28 01:10 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "chore(skills): primeira sincronização com a nova mãe e correção de performance do relatório"
- **Arquivos afetados**: `.claude/skills/` (9 skills), `tools/.skills-source`, `tools/sync-skills.ps1`, `tools/sync-skills.sh`, `NEWS.md`

## 2026-07-28 00:40 — Template deixa de ser mãe das skills; `sync-skills` corrigido em dois defeitos

**Decisão de arquitetura (autor).** O ecossistema tinha **duas mães declaradas** para as mesmas skills: este template se declarava mãe das skills de governança, e o repositório irmão `skills` reunia as mesmas 11 mais ~90 outras. A divisão passa a ser: `skills` é dono das skills (os procedimentos, o *como*); este template é dono de hooks, policy-as-code, validador e estrutura (o que torna a regra obrigatória). Este template vira **consumidor**.

A interface entre os dois é a seção § Configuração de Skills: a skill permanece genérica e lê dali o específico do projeto. A chave **`diretorio_governanca` foi adicionada** — ela existia em dois consumidores (`MancanoSync`, `skills`) e não constava deste template, apesar de ser exatamente o contrato que permite duas mães sem acoplamento.

**Por que a decisão importa — dois casos medidos hoje**, um em cada direção:

- Uma correção nascida em `cha-affirmative-action-us-brazil` (commit `6f8e7e7`, 2026-07-21, escrita pelo próprio autor) nunca voltou para a mãe. Seis dias depois foi reimplementada do zero aqui, sem que ninguém soubesse que já existia.
- A decisão registrada neste `NEWS.md` em 2026-07-17 10:38 (`disable-model-invocation: false` em `grill-me`/`grill-with-docs`/`edit-article`, "em todos os consumidores") nunca saiu deste repositório. Onze dias depois o valor antigo persistia no repo `skills` **e nas duas cópias globais da máquina** (`~/.claude/skills/`, `~/.gemini/config/skills/`), que são as que os agentes de fato carregam. Na prática a decisão não estava em vigor em lugar nenhum. Corrigido nas três camadas.

**`sync-skills` corrigido em dois defeitos**, ambos com evidência:

1. **Comparava bytes, não conteúdo.** `Get-FileHash`/`sha256sum` cru marcava como "desatualizada" qualquer skill que só tivesse mudado de codificação. Numa auditoria das 11 skills sobrepostas, 9 apareciam divergentes e **8 tinham conteúdo idêntico** — a diferença era BOM, CRLF e linha em branco no fim, introduzidos horas antes pela padronização de frontmatter no repo `skills`. A ferramenta reportava informação verdadeira e inútil. Agora normaliza antes de hashear (`Get-ContentHash`/`content_hash`), tratando arquivos binários byte a byte.
2. **O relatório era dominado por ruído.** Com a mãe passando a ter 101 skills, a primeira execução real listou **90 linhas "NOVA (não instalada)" contra 9 úteis**. O relatório agora cobre só as skills já instaladas e resume as disponíveis numa linha. Consequência deliberada: **`--apply all` significa "atualizar o que eu já tenho"**, nunca "instalar as 101" — instalar skill nova exige nomeá-la.

Os dois scripts (`.ps1` e `.sh`) foram verificados produzindo saída idêntica contra a nova mãe. O `.ps1` recebeu **BOM UTF-8**: o Windows PowerShell 5.1 lê `.ps1` sem BOM como ANSI, e o caractere `ℹ` adicionado nesta rodada quebrava o parser — o arquivo dependia de sorte para os emoji que já continha.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-28 00:40 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "refactor(governance): template vira consumidor de skills; sync-skills compara conteúdo normalizado"
- **Arquivos afetados**: `tools/sync-skills.ps1`, `tools/sync-skills.sh`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`

## 2026-07-27 21:49 — Indireção real do diretório de governança (WP3) e plano de migração para AGENTS.md

Auditoria pedida pelo autor a partir de um prompt de terceiro que perguntava "qual o melhor nome para a pasta `9-vers/`". A resposta é que a pergunta era a errada: **o nome não era o defeito, a ausência de indireção era.** O nome estava fixado em 242 pontos, incluindo os dois scripts R e as skills que o próprio `CLAUDE.md` declara "nunca hardcoded aqui".

Evidência coletada: três pastas de governança coexistindo na raiz `MancanoSync` (`0-meta` em uso, `9-vers` e `0-governance` órfãs e fora do git); um export de conversa de 2026-07-26 gravado fora do controle de versão porque o `export_conversa.R` fixava `9-vers` num repositório que usa `0-meta`; hard links quebrados em 3 de 8 repositórios (verificado por inode, não por tamanho); e a chave `diretorio_governanca`, documentada em dois consumidores, não consumida por lugar nenhum.

**Conclusão sobre o nome**: `9-vers` e `0-meta` estão os dois corretos, cada um no seu contexto. Nos repositórios de pesquisa, `9-vers` é o slot 9 de uma taxonomia numerada viva (`2-set/`, `3-texts/`, `4-DA-Code/`, `6-images-tables/`) — renomear ali destruiria significado. Com a indireção, a diferença deixa de ser dívida e passa a ser adequação local.

Implementado nesta rodada (WP3): `tools/validate-governance.R` e `tools/export_conversa.R` passam a detectar o diretório em tempo de execução via `GOV_DIR_CANDIDATOS`/`GOV_DIR`, cobrindo também `PATH_BACKUP_DIR`, o filtro T6 e a lista `GOVERNANCE_DOCS`. Testado nos dois sentidos (`GOV_DIR = 9-vers` neste repositório, `0-meta` num repositório simulado).

Achado durante a auditoria: o repositório `cha-affirmative-action-us-brazil` **já tinha** essa mesma indireção no validador, escrita numa rodada anterior e nunca promovida ao template-mãe — a implementação de hoje convergiu de forma independente para a mesma solução. Correções nascendo nos consumidores e não voltando para a mãe é um problema estrutural, registrado no plano.

Plano de migração completo (11 work packages, 12 repositórios) em `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md`, incluindo: adoção do padrão AGENTS.md por symlink no lugar dos hard links, remoção de `.github/copilot-instructions.md` e `.cursor/rules/` (redundantes desde que Copilot e Cursor passaram a ler `AGENTS.md`), migração de proibições em prosa para travas em `PreToolUse` hook, e dois ritmos de trabalho para eliminar fadiga de conformidade. O plano incorpora benchmarking do `microsoft/agent-governance-toolkit` (4.9k★, MIT), clonado e lido, cuja tese — *"prompt-level safety is not a control surface"* — valida com citação de OWASP e literatura o desenho do WP10.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-27 21:49 (Horário de Brasília)
- **Agente**: Claude Opus 5 / claude-opus-5 / Claude Code (VS Code)
- **Mensagem do Commit**: "feat(governance): indireção real do diretório de governança (WP3) e plano de migração AGENTS.md"
- **Arquivos afetados**: `tools/validate-governance.R`, `tools/export_conversa.R`, `9-vers/plan/2026-07-27_Plano_Migracao_AGENTS-md_e_Indirecao_Governanca.md`, `9-vers/plan/README.md`, `NEWS.md`, `TODO.md`


## 2026-07-17 10:38 — `disable-model-invocation` revertida para `false` em grill-me/grill-with-docs/edit-article

Decisão do autor (2026-07-17): as três skills portadas de Matt Pocock que vinham com `disable-model-invocation: true` (ação só-por-pedido-explícito, preservado fielmente do original desde a instalação em 2026-07-14) passam a `false` — o autor quer as três invocáveis pelo agente como as demais skills do template, em todos os consumidores. Atualizado em conjunto o `agents/openai.yaml` de cada uma (`allow_implicit_invocation: true`) para não divergir entre plataformas (Claude vs. Copilot/OpenAI). `CLAUDE.md` (§ Skills Compartilhadas) atualizado para refletir a mudança. Como de praxe, a edição do `CLAUDE.md` quebrou o hard link físico de `AGENTS.md`/`.github/copilot-instructions.md` — backups dos divergentes salvos em `9-vers/backups/` antes de recriar os links.

Próximo passo (fora deste repositório): consumidores (`MancanoSync` raiz, `Mancano2026-MA-Thesis`, e demais que adotaram o template) precisam rodar `sync-skills --apply` para as três skills para receber a mudança — não é automático.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-17 10:38 (Horário Local)
- **Agente**: Claude Code / Claude Sonnet 5 / VS Code
- **Mensagem do Commit**: "feat(governance): disable-model-invocation=false em grill-me/grill-with-docs/edit-article"
- **Arquivos afetados**: `.claude/skills/grill-me/SKILL.md`, `.claude/skills/grill-me/agents/openai.yaml`, `.claude/skills/grill-with-docs/SKILL.md`, `.claude/skills/grill-with-docs/agents/openai.yaml`, `.claude/skills/edit-article/SKILL.md`, `.claude/skills/edit-article/agents/openai.yaml`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`

## 2026-07-15 12:05 — Backups do self-heal de hard link movidos da raiz para 9-vers/backups/

Achado promovido de um repositório consumidor deste template (`Nahoum-Mancano-2026-Antitrust`): a seção 0 de `tools/validate-governance.R` (self-heal do hard link `CLAUDE.md`/`AGENTS.md` quando os dois divergem) escrevia os backups `AGENTS.md.bak.<timestamp>`/`CLAUDE.md.bak.<timestamp>` direto na raiz do repositório — sem limpeza, acumulavam a cada divergência (5 arquivos reais encontrados na raiz deste próprio template). Como é tooling compartilhado, todo consumidor do template tinha o mesmo problema. Corrigido: os dois pontos de `file.copy()` agora escrevem em `9-vers/backups/` (nova pasta, já coberta pelo `*.bak.*` existente no `.gitignore`, via novo helper `make_backup_path()`); os 5 arquivos encontrados na raiz foram movidos para lá, nenhum deletado.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-15 12:05 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "fix(governance): relocate hard-link self-heal backups from repo root to 9-vers/backups/"
- **Arquivos afetados**: `tools/validate-governance.R`, `9-vers/backups/AGENTS.md.bak.*` (movidos), `NEWS.md`, `TODO.md`

## 2026-07-14 12:45 — Auditoria da adição de skills globais (superpowers) concluída: REQUER REFATORAÇÃO MENOR, corrigido na mesma rodada

Auditoria independente (prompt deixado pelo agente autor em `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md`) do commit `37c28f8`, que tinha adicionado uma tabela de skills globais do plugin `superpowers` como § 4 de `sync-skills/SKILL.md`. Verificado fisicamente antes de aceitar qualquer alegação: commit e diff conferem, as 14 skills listadas existem de verdade no plugin instalado (nomes e contagem 1:1), as 5 fragilidades autodeclaradas pelo autor original são precisas. Veredito: `[REQUER REFATORAÇÃO MENOR]` — achado principal não coberto pela autocrítica: a tabela estava no lugar errado (escopo de `sync-skills` é sincronizar skills *de projeto*, não catalogar plugins *de máquina*) e documentava informação não-portável (`~/.claude/plugins/`, local por usuário/máquina) como se fosse portável — já tinha sido propagada para 2 repositórios consumidores antes da correção. Corrigido: conteúdo movido para nova seção em `CLAUDE.md` ("Skills Globais Disponíveis Neste Ambiente"), com aviso explícito de que é inventário de máquina (não de projeto) e destaque para `using-superpowers`, a única skill do pacote com invocação mandatória por design. Resultado completo da auditoria registrado no próprio prompt.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 12:45 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "docs(governance): fix scope of superpowers skills catalog - move from sync-skills to CLAUDE.md with machine-caveat"
- **Arquivos afetados**: `.claude/skills/sync-skills/SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md`, `9-vers/plan/README.md`, `NEWS.md`

## 2026-07-14 12:26 — 5 skills de mattpocock/skills instaladas após triagem; reconciliado com instalação concorrente do plugin superpowers

Instaladas 5 skills de [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — `grill-me`, `grilling`, `grill-with-docs`, `edit-article`, `code-review` — escolhidas depois de mapear as ~32 skills do repositório original e apresentar uma triagem ao autor (a maioria é específica de TypeScript/Node, descartada). `git-guardrails-claude-code` foi descartada nesta rodada: dependia de `jq` (não instalado neste ambiente) e bloquearia `git push` incondicionalmente, o que conflitaria com o fluxo já estabelecido nesta sessão. Instaladas fielmente ao original, sem adaptar ao padrão config-driven das skills de governança (não são deste projeto). Detalhe completo, incluindo os gaps conhecidos (`grill-with-docs`→`/domain-modeling` ausente; `code-review`→workflow de issue-tracker ausente, degrada graciosamente), em `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md` § "Terceira rodada".

**Concorrência real**: esta rodada aconteceu em paralelo a outro agente (Claude Sonnet 4.6) instalando o plugin `superpowers` no mesmo repositório físico — ver entrada abaixo, escrita por ele. Auditoria do trabalho dele feita a seguir, a pedido do autor.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 12:26 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): revert disable-model-invocation, add 5 mattpocock/skills after triage"
- **Arquivos afetados**: `.claude/skills/grill-me/`, `.claude/skills/grilling/`, `.claude/skills/grill-with-docs/`, `.claude/skills/edit-article/`, `.claude/skills/code-review/`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `NEWS.md`

## 2026-07-14 11:45 — Plugin superpowers instalado; skills globais referenciadas em sync-skills

Instalado o plugin `superpowers` (14 skills globais do Claude Code) e adicionada a seção § 4 ao `sync-skills/SKILL.md` com tabela completa das skills do pacote, regra de convivência com as skills de projeto e orientação de quando usar cada uma. O objetivo é que sempre que `sync-skills` for carregada no contexto, o agente já tenha o inventário das skills globais disponíveis em memória — evitando que elas sejam ignoradas no fluxo de trabalho. O plano `2026-07-14_Plano_Skills_Compartilhadas_TODO.md` é encerrado nesta sessão com todas as tarefas concluídas.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:45 (Horário Local)
- **Agente**: Claude Sonnet 4.6 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): reference superpowers global skills in sync-skills, close active plan"
- **Arquivos afetados**: `.claude/skills/sync-skills/SKILL.md`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `9-vers/llm-reviews/README.md`, `NEWS.md`

## 2026-07-14 11:45 — Reversão: disable-model-invocation removido de close-task/git-cleanup/sync-skills, a pedido do autor

O autor decidiu que quer essas 3 skills de volta ao alcance autônomo do agente (model-invoked, o padrão) — flag `disable-model-invocation: true` removida das 3. Nenhuma outra mudança de conteúdo.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:45 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "revert(governance): remove disable-model-invocation from close-task/git-cleanup/sync-skills per author decision"
- **Arquivos afetados**: `.claude/skills/close-task/SKILL.md`, `.claude/skills/git-cleanup/SKILL.md`, `.claude/skills/sync-skills/SKILL.md`, `NEWS.md`

## 2026-07-14 11:22 — Refinamentos vindos de referências externas: disable-model-invocation e formato de achados alinhado ao /code-review nativo

O autor pediu para checar se recursos já circulando no mercado (a skill de referência `writing-great-skills` de mattpocock/skills no GitHub, e a funcionalidade nativa de code review do próprio Claude Code) melhoravam o trabalho antes de propagar. Duas mudanças concretas:

1. **`disable-model-invocation: true`** adicionado a `close-task`, `git-cleanup` e `sync-skills` — são ações consequentes (encerram sessão, commits em lote, sobrescrevem skills locais) que só devem rodar por invocação explícita do usuário pelo nome; a flag remove a `description` do alcance do agente, então nada dispara essas skills sozinho por inferência. `request-audit`/`export-conversation`/`pdf-text-extractor` ficam sem a flag (baixo risco, faz sentido o agente alcançar por conta própria). Documentado em `CLAUDE.md` § "Skills Compartilhadas Entre Projetos".
2. **`request-audit` § D (Formato de Resposta)** reescrita para exigir, por achado: cenário de falha concreto (input/estado → output errado, não uma alegação vaga) e um veredito `CONFIRMED`/`PLAUSIBLE` — mesma convenção da ferramenta nativa `ReportFindings` do Claude Code, incluindo `outcome` (`fixed`/`skipped`/`no_change_needed`) para re-reportar achados numa segunda rodada em vez de reescrever a lista do zero.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:22 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "refactor(governance): add disable-model-invocation to consequential skills, align request-audit findings format with native /code-review"
- **Arquivos afetados**: `.claude/skills/close-task/SKILL.md`, `.claude/skills/git-cleanup/SKILL.md`, `.claude/skills/sync-skills/SKILL.md`, `.claude/skills/request-audit/SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`

## 2026-07-14 11:15 — Skills renomeadas para inglês e reescritas config-driven; pdf-text-extractor entra no mecanismo compartilhado

O autor apontou um problema real na primeira rodada: as skills compartilhadas tinham texto específico de cada projeto hardcoded (caminhos da tese), fazendo o relatório do `sync-skills` marcá-las como "desatualizada" permanentemente nos consumidores — sinal sem significado. Detalhe completo em `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md` § "Segunda rodada".

Skills renomeadas: `finalizar-tarefa`→`close-task`, `exportar-conversa`→`export-conversation`, `limpar-pendencias-git`→`git-cleanup`, `sincronizar-skills`→`sync-skills` (`request-audit`/`pdf-text-extractor` já em inglês, mantidos). `close-task`/`export-conversation`/`git-cleanup` reescritas para consumir chaves nomeadas em vez de hardcode — `git-cleanup` foi a reescrita mais pesada (variantes de autoria protegida, agrupamento por pasta de trabalho contínuo, e o caso do arquivo gerenciado externamente, todos generalizados). Nova seção `## Configuração de Skills (Skill Configuration)` em `CLAUDE.md`, com tabela `Chave | Usada por | Valor` e 4 chaves (`diretorio_autoria_primaria`, `arquivo_gerenciado_externamente`, `script_exportar_conversa`, `diretorios_trabalho_continuo`) — skills agora apontam para lá explicitamente, nunca hardcodeiam. `pdf-text-extractor` (com `scripts/extract_pdf.R`) portado da tese para a mãe, sem hardcode encontrado. `tools/sync-skills.ps1`/`.sh` reescritos para comparar/copiar a **pasta inteira** de cada skill (hash recursivo), não só `SKILL.md` — necessário para skills com arquivos auxiliares.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:15 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "refactor(governance): rename skills to English, make them config-driven via CLAUDE.md, add pdf-text-extractor to shared mechanism"
- **Arquivos afetados**: `.claude/skills/close-task/`, `.claude/skills/export-conversation/`, `.claude/skills/git-cleanup/`, `.claude/skills/sync-skills/`, `.claude/skills/pdf-text-extractor/`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `README.md`, `tools/sync-skills.ps1`, `tools/sync-skills.sh`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `NEWS.md`

## 2026-07-14 09:58 — Repositório mãe de skills compartilhadas, convenção definitiva de TODO.md, junction .agents corrigida

Formalizado este repositório como repositório mãe de skills de governança reutilizáveis entre projetos correlatos (ver `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`). `TODO.md` reescrito com 3 seções (Pendente/Prospectivo/Concluído), cada item com data+hora de criação/conclusão e quem criou/concluiu (agente e humano), e link para plano em `9-vers/plan/` quando complexo — corrige a convenção anterior (item novo no fim, sem metadados) antes que ela se espalhasse para mais projetos. Skill `request-audit` portada e generalizada da tese; `finalizar-tarefa` conferida por diff contra a fonte — já estava corretamente generalizada, sem mudanças necessárias. Criados `tools/sync-skills.ps1`/`.sh` (relatório dry-run por padrão, `--apply` para puxar skills específicas, nunca commita sozinho) e a skill `sincronizar-skills` que envolve o script com a cerimônia de revisão/staging explícito. Achado e corrigido: a junction `.agents` apontava para o caminho antigo `mancano-project-template/.claude`, órfão desde a renomeação deste repositório — recriada apontando para `.claude` deste mesmo repositório.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 09:58 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): establish shared-skills mother repo, definitive TODO.md convention, fix stale .agents junction"
- **Arquivos afetados**: TODO.md, CLAUDE.md, AGENTS.md, .claude/skills/request-audit/SKILL.md, .claude/skills/sincronizar-skills/SKILL.md, tools/sync-skills.ps1, tools/sync-skills.sh, 9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md, 9-vers/plan/README.md, .agents

## 2026-07-13 22:37 — Sincronização de Governança com a Tese

Atualização massiva do template para incorporar as últimas travas de segurança desenvolvidas no repositório da tese. As mudanças incluem o self-heal de links (com UNC guard e system2), parser YAML mais tolerante, checks T5/T6 e genericização das ferramentas para uso em novos projetos.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-13 22:37 (Horário Local)
- **Agente**: Antigravity / Gemini 1.5 Pro / Antigravity IDE
- **Mensagem do Commit**: "chore: finalização da tarefa sincronizacao-governanca"
- **Arquivos afetados**: tools/validate-governance.R, CLAUDE.md, NEWS.md, setup.ps1, setup.sh, hooks/, .claude/skills/, 9-vers/plan/

## YYYY-MM-DD HH:MM — [Título Curto da Entrega/Decisão]

[Descreva aqui em prosa contínua as principais decisões de design, mudanças de arquitetura e evolução do projeto implementadas nesta sessão.]

**Metadados de Execução**:
- **Data/Hora**: YYYY-MM-DD HH:MM (Horário Local)
- **Agente**: [Nome do Agente] / [Modelo] / [Plataforma] (ex: Antigravity / Gemini 1.5 Pro / Antigravity CLI)
- **Mensagem do Commit**: "sua mensagem de commit aqui"
- **Arquivos afetados**: caminho/do/arquivo1, caminho/do/arquivo2
