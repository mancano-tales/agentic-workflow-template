# [NOME DO SEU PROJETO]

> Breve descrição de uma linha sobre o objetivo do seu projeto.

Este repositório adota um **modelo profissional de desenvolvimento cooperativo Humano-IA de nível industrial**. Ele foi projetado para permitir que agentes de IA autônomos (como Claude Code, Cursor, Antigravity, Aider) trabalhem de forma segura e sincronizada com desenvolvedores humanos, eliminando regressões de código, duplicidade de logs e perda de contexto.

> 📐 **O que você está adotando**: [PRINCIPLES.md](PRINCIPLES.md) reúne os oito princípios deste template — policy-as-code, transparência, reprodutibilidade, Keep a Changelog 1.1.0 com rastreabilidade derivada, Conventional Commits, arquivamento dos logs de LLM, plano antes de execução, e "uma peça, um dono" — com a falha medida que originou cada um. Este README explica *como instalar*; aquele documento explica *o quê* e *por quê*.
>
> 📋 **Convenções adotadas**: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/) nas mensagens de commit e [Keep a Changelog 1.1.0](https://keepachangelog.com/) no changelog — encaixadas uma na outra, ver Seção 5.

---

## 1. Setup Rápido (Configuração de Links de IA)

Para iniciar o projeto e preparar as pontes de contexto das IAs:

*   **No Windows (PowerShell):**
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\setup.ps1
    ```
*   **No Linux/macOS (Bash):**
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

Isso criará o link de junção para a pasta `.agents/` (Gemini/Antigravity), integrando os ecossistemas sob a mesma base física de habilidades em `.claude/skills/`, e garantirá que `CLAUDE.md` seja apenas o ponteiro `@AGENTS.md`.

> **`AGENTS.md` é o único arquivo de instruções**, e é o arquivo real. Claude Code, GitHub Copilot e Cursor leem o padrão aberto `AGENTS.md` diretamente, então não há mais hard links nem cópias espelhadas para manter em sincronia: `CLAUDE.md` contém uma linha (`@AGENTS.md`), e `.github/copilot-instructions.md` e `.cursor/rules/` deixaram de existir em 2026-07-29. Editar qualquer coisa que não seja `AGENTS.md` é erro.

---

## 2. Organograma do Repositório

```
[seu-repositório]/
├── .claude/                         # Pasta unificada de customizações e skills compartilhadas de IAs
│   └── skills/                      # Scripts e instruções estendidas para agentes (ex: export-conversation)
├── .agents/                         # Atalho local (junction NTFS) apontando para .claude/ (gitignorado)
├── hooks/                           # Modelos de Git Hooks para automação e validação de commits
│   ├── pre-commit                   # Hook pre-commit (valida status e cobra NEWS.md)
│   └── post-merge                   # Hook post-merge (recria junctions e links físicos)
├── tools/                           # Scripts de utilidade geral e QA do repositório
│   ├── validate-governance.R        # Validador de integridade de metadados de planos (R)
│   └── export_conversa.R            # Extrator de logs de sessões de IA para Markdown (R)
├── 9-vers/                          # Pasta viva de planejamento e arquivo de histórico
│   ├── GUIDANCE_MAP.md              # Sitemap completo explicando a função de cada pasta
│   ├── plan/
│   │   ├── README.md                # Tabela de status e progresso de tarefas (Work Packages)
│   │   └── YYYY-MM-DD_Plano_TEMPLATE.md  # Template para novos planos de trabalho
│   └── llm-reviews/
│       └── README.md                # Registro de conversas e auditoria de IAs
│
├── AGENTS.md                        # ARQUIVO REAL E ÚNICO: contexto do projeto, regras, tech stack
├── CLAUDE.md                        # Ponteiro de uma linha (@AGENTS.md) — não edite
├── GUIDANCE.md                      # Atalho para o sitemap completo de diretrizes
├── PRINCIPLES.md                    # Os 8 princípios do template e a falha que originou cada um
├── NEWS.md                          # Changelog EDITORIAL: decisões e raciocínio, escrito à mão, sem hashes
├── CHANGELOG.md                     # Changelog DERIVADO do git log (hash + timestamp) — não edite à mão
└── README.md                        # Este documento (Visão geral de instalação e execução)
```

---

## 3. Como Começar a Desenvolver

1.  **Edite as Definições:** Atualize as configurações e descrições do seu projeto em `CLAUDE.md` e `README.md`.
2.  **Crie um Plano:** Para qualquer tarefa de arquitetura ou fluxo complexo, crie um plano em `9-vers/plan/` a partir do `2026-07-11_Plano_TEMPLATE.md` e adicione-o como `ATIVO` na tabela do `9-vers/plan/README.md`.
3.  **Audite a Governança:** Rode `Rscript tools/validate-governance.R` a qualquer momento para garantir que nenhuma IA quebrou os padrões de status do repositório.
4.  **Log de Conversa:** Ao finalizar uma sessão com um agente, rode `Rscript tools/export_conversa.R <session_uuid> [slug]` para gerar o log em `llm-reviews/` e indexá-lo.

---

## 4. Instalando Git Hooks de Governança

Para automatizar a verificação local e evitar erros em commits, os hooks agora são versionados diretamente na pasta `hooks/`.

Eles já são ativados automaticamente ao rodar o Setup Rápido (Seção 1). Se precisar ativá-los manualmente:

*   **No Linux/macOS ou Windows:**
    ```bash
    git config core.hooksPath hooks
    ```

---

## 5. Convenções de Commit e Changelog

Duas convenções abertas, adotadas porque **encaixam uma na outra**: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/) e [Keep a Changelog 1.1.0](https://keepachangelog.com/). O Conventional Commits exige um **tipo vindo de lista fechada** em cada mensagem, e é isso que permite traduzir cada commit mecanicamente para uma categoria do Keep a Changelog. Sem tipo obrigatório, não há tradução — e o changelog volta a ser escrito à mão.

### Três artefatos, três perguntas

| Artefato | Responde | Curadoria | Editar à mão? |
|---|---|---|---|
| `git log` | *O que exatamente mudou, quando, por quem?* | nenhuma — registra tudo | n/a |
| [CHANGELOG.md](CHANGELOG.md) | *O que mudou que me afeta, por tipo?* | automática | **não** — é derivado |
| [NEWS.md](NEWS.md) | *Por que mudou? O que se descartou?* | humana, editorial | **sim** — só assim existe |

O `git log` tem o **fato**; o `CHANGELOG.md` tem o fato **organizado para o leitor**; o `NEWS.md` tem a **razão** — e a razão não é derivável de nada. Nenhuma ferramenta extrai de um diff qual alternativa foi rejeitada ou qual incidente motivou a mudança.

### Tradução tipo → categoria

| Tipo do commit | Categoria |
|---|---|
| `feat` | `Added` |
| `fix`, `perf` | `Fixed` |
| `refactor`, `style`, `docs`, `build`, `ci`, `chore`, `test`, `revert` | `Changed` |
| `!` no cabeçalho (ex.: `feat(api)!:`) | `Breaking` — sobrepõe-se ao tipo |

Para regenerar o changelog derivado:

```bash
Rscript tools/render-changelog.R --output CHANGELOG.md
```

A geração é **determinística**: rodar duas vezes sem mudança no histórico produz arquivos idênticos. O raciocínio completo — por que o hash não é escrito à mão, por que `Deprecated`/`Removed`/`Security` não são emitidas — está em [PRINCIPLES.md](PRINCIPLES.md) §4 e §5.

