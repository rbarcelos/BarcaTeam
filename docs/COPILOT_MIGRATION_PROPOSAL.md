# BarcaTeam → GitHub Copilot Migration Proposal

**Goal:** Convert BarcaTeam from a Claude Code–native orchestration hub into a **GitHub Copilot CLI–native** one, removing all Claude/Anthropic dependencies and coupling, and optimizing the whole setup for Copilot's actual capabilities.

**Status:** Proposal for review + agent evaluation. No code changed yet.

---

## 1. Executive summary

BarcaTeam is a multi-agent software-delivery harness. Today it is deeply coupled to **Claude Code**:

- Instructions live in `CLAUDE.md` and describe a Claude-only orchestration model (tmux/psmux split-panes, `TeamCreate`, `Agent` teams, a psmux path-stripping bug workaround, pane-health loops).
- Agents live in `.claude/agents/*.md`; skills in `.claude/skills/*/SKILL.md`; config in `.claude/settings.json` + `.mcp.json`.
- Scripts install the **Claude CLI** (`@anthropic-ai/claude-code`) and **Claude plugins** (`@claude-plugins-official`).
- A bundled `claude-ping/` WhatsApp MCP server spawns the `claude` CLI internally.

**Key insight that reshapes this migration:** the current docs assume Copilot CLI *cannot* do teams, skills, or memory. That is **outdated**. Copilot CLI natively supports:

| Capability | Copilot CLI native mechanism |
|---|---|
| Custom agents | `.agent.md` files + `/agent`, invoked as subagents |
| Parallel agents / "teams" | `/fleet` (fleet mode) + `/subagents` + `/tasks` |
| Skills | `SKILL.md` files + `/skills` |
| MCP servers | `/mcp` + `~/.copilot/mcp-config.json` |
| Plugins | `/plugin` + plugin marketplaces |
| Memory | native `/memory` + Copilot Memory |
| Code review / security / rubber-duck | built-in `/review`, `/security-review`, `/rubber-duck` |
| LSP | `/lsp` |
| Cloud PR delegation | `/delegate` |
| Instructions | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/instructions/**` |

So the migration is **not** "downgrade to a weaker platform." It is: **replace the fragile tmux/psmux pane machinery with Copilot's native subagent/fleet model**, relocate agents/skills to Copilot's discovery paths, remap plugins to Copilot equivalents/built-ins, and de-Claude the WhatsApp bridge and scripts.

---

## 1.5 Capability verification (evidence, not assertion)

Every load-bearing claim below was verified against official GitHub Copilot CLI docs and/or this live Copilot CLI session (v1.0.69-2). Citations included so this is not hand-waved.

| Claim | Verified? | Evidence |
|---|---|---|
| Commands `/fleet`, `/subagents`, `/tasks`, `/skills`, `/mcp`, `/plugin`, `/memory`, `/review`, `/security-review`, `/rubber-duck`, `/lsp`, `/delegate` exist | ✅ | `copilot` help output (this CLI version) lists all of them verbatim. |
| Model can delegate to subagents (custom agents) | ✅ | Docs: "the model … can choose to delegate a task to a subsidiary subagent process, that operates using a custom agent." `copilot --agent=X --prompt`. This session is running with subagent delegation. |
| **Repo-level agents auto-discovered from `.github/agents/`** | ✅ | Docs table: user=`~/.copilot/agents`, **repo=`.github/agents`**, org=`.github-private/agents`. Precedence: system > repo > org. **No sync step required.** |
| **Project skills auto-discovered** | ✅ | Docs: project skills live in `.github/skills`, **`.claude/skills`**, or `.agents/skills`. (The current `.claude/skills` already loads in this session.) SKILL.md frontmatter = `name`, `description`, `license?`, `allowed-tools?` — portable as-is. |
| MCP config location | ✅ | Docs: `mcp-config.json` in `~/.copilot` (override via `COPILOT_HOME`). File is created via `/mcp add`. GitHub MCP server ships pre-configured. |
| Hooks (passive, event-driven) | ✅ | Docs: "Using hooks with GitHub Copilot CLI" — replicates `security-guidance`-style passive warnings. |
| Non-interactive spawn for claude-ping | ✅ | `copilot -p "<msg>"` (+ `--allow-all`/`--yolo` for unattended). Real print-mode invocation. |
| Native memory | ✅ | `/memory` command + Copilot Memory + `store_memory`/`vote_memory` tools (in use this session). |
| Custom instructions files | ✅ | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `AGENTS.md` (also reads `CLAUDE.md`/`GEMINI.md` for back-compat). |

**Conclusion:** the platform premise holds. The migration's *delete* list (panes/psmux/pre-spawn/pane-health) is replaced by *verified* native mechanisms. The one honest caveat is **capability-shape differences** (below), not capability absence.

---

## 2. Current Claude-coupled surface (inventory)

| # | Surface | Files | Claude coupling | Disposition |
|---|---|---|---|---|
| 1 | Root instructions | `CLAUDE.md` | tmux/psmux/TeamCreate/Agent, plugin list, `.claude/` paths, psmux bug | **Rewrite** → `.github/copilot-instructions.md` + `AGENTS.md` |
| 2 | Copilot instructions | `.github/copilot-instructions.md` | Minimal stub (17 lines) | **Expand** to the canonical instruction set |
| 3 | Agents | `.claude/agents/*.md` (32 files) | frontmatter (`model: opus`, `Agent(...)`, `memory:`, `skills:`, `disallowedTools:`), bodies reference tmux/psmux/skills/CLAUDE.md | **Relocate + convert** → `.github/agents/*.agent.md` |
| 4 | Skills | `.claude/skills/*/SKILL.md` (25 skills) | reference CLAUDE.md, tmux, psmux, `.claude/` paths, Claude plugins | **Relocate + edit** → `.github/skills/*/SKILL.md` (SKILL.md format is already Copilot-native) |
| 5 | Settings | `.claude/settings.json`, `settings.local.json` | Claude permissions model, `enabledPlugins`, `CLAUDE_CODE_*` env, `teammateMode: tmux` | **Replace** with Copilot `settings.json` / `/settings` |
| 6 | MCP config | `.mcp.json` | Claude MCP format | **Port** → `~/.copilot/mcp-config.json` (or repo `.copilot`) |
| 7 | WhatsApp bridge | `claude-ping/` (TS project) | spawns `claude -p`; README/pkg say "for Claude Code" | **De-Claude**: rename + repoint process spawn to `copilot -p` (or drop the chat-spawn feature, keep WhatsApp MCP only) |
| 8 | Install scripts | `scripts/install.ps1`, `install.sh` | install `@anthropic-ai/claude-code`, `claude plugin install ...@claude-plugins-official`, build claude-ping | **Rewrite** to install `@github/copilot` + Copilot plugins/MCP |
| 9 | Doctor scripts | `scripts/doctor.ps1`, `doctor.sh` | check `claude` CLI, plugins | **Rewrite** to check `copilot` CLI, agents, skills, MCP |
| 10 | Launchers | `start.ps1`, `start.sh`, `launch.sh`, `dev-env.sh`, `upgrade-psmux.ps1` | psmux/tmux + `claude --add-dir` | **Replace** with `copilot --add-dir` launcher; drop psmux/tmux |
| 11 | Export tool | `scripts/export-conversation.js` | Claude session format | **Rewrite or drop** (Copilot has `/share`, `/chronicle`) |
| 12 | README | `README.md` | Claude-first; references non-existent `start-claude.cmd`/`start-copilot.cmd`/`sync-agents.cmd`; outdated capability table | **Rewrite** Copilot-first |
| 13 | Loose docs | `tmux-cheatsheet.md`, `team_plan.md`, `engineer_task.md`, `CAP_REVIEW.md`, `.claude/session-checkpoint.md`, `.claude/proposals/CLAUDE-md-improvement-plan.md`, `docs/capabilities/**` | mention CLAUDE.md/tmux/skills | **Edit** references; delete tmux cheatsheet |
| 14 | gitignore/attributes | `.gitignore` | ignores `.claude/settings.local.json`, `.claude/scheduled_tasks.lock`, `.claude/worktrees/` | **Update** paths |
| 15 | Local settings | `.claude/settings.local.json` | user-local Claude config | **Remove / replace** with Copilot equivalent |
| 16 | Session state | `.claude/session-checkpoint.md` | worktree/pane session state | **Delete** (Copilot has `/resume`, `--continue`, `/session`) |
| 17 | Schemas | `.claude/schemas/finding.yaml` | finding schema referenced by skills | **Relocate** with skills (e.g. `.github/skills/finding-schema/`) |
| 18 | Proposals dir | `.claude/proposals/**` | Claude-specific planning docs | **Move** to `docs/` or delete |
| 19 | Pane/psmux-only skills | `.claude/skills/{pane-health-check,pre-spawn-check,session-checkpoint,improvement-loop}/SKILL.md` | hard-coded tmux/psmux/TeamCreate/`.claude/` paths | **Delete or fully rewrite** (pane machinery has no Copilot analog) |

> Counts verified by audit agent: **32 agents**, **25 skills**, **10 distinct** `@claude-plugins-official` refs (`claude-code-setup`, `claude-md-management`, `context7`, `frontend-design`, `playwright`, `pr-review-toolkit`, `pyright-lsp`, `rust-analyzer-lsp`, `security-guidance`, `typescript-lsp`).

---

## 3. Concept mapping (Claude Code → Copilot CLI)

| Claude Code concept | Copilot CLI replacement | Notes |
|---|---|---|
| `CLAUDE.md` | `.github/copilot-instructions.md` + `AGENTS.md` | Copilot still *reads* `CLAUDE.md` for back-compat, but we make Copilot files canonical and delete `CLAUDE.md`. |
| tmux/psmux split-panes, `TeamCreate`, manual pane launch, psmux bug workaround, `/pre-spawn-check`, `/pane-health-check`, `session-checkpoint` | `/fleet` + `/subagents` + `/tasks` (Task tool) | **Entire pane-management layer is deleted.** Copilot runs subagents in-process; no panes to crash, no path-stripping bug, no health loop. |
| `Agent(pm)` tool grants in frontmatter | Copilot subagent invocation via Task tool | Agent-to-agent delegation is handled by Copilot's subagent model, not explicit tool grants. |
| `model: opus` / `model: sonnet` | Copilot model IDs (`/model`, `/subagents`) | Map to Copilot-available models; default `auto`. |
| `memory: user` + memory MCP server | Copilot `/memory` + `store_memory` | Native Copilot Memory replaces the frontmatter field and the `@modelcontextprotocol/server-memory`. |
| `.claude/skills/*/SKILL.md` | `.github/skills/*/SKILL.md` | Same `SKILL.md` format; only the location + internal references change. |
| Claude plugins (`@claude-plugins-official`) | Copilot `/plugin` + built-ins | See mapping table below. |
| `.mcp.json` | `~/.copilot/mcp-config.json` | MCP transport is portable; only the config file/format differs. |
| `start.ps1` (`claude --add-dir`) | `copilot --add-dir` launcher | Much simpler — no psmux, no tmux, no send-keys. |

### Plugin remapping

| Claude plugin | Copilot equivalent |
|---|---|
| `pr-review-toolkit` | built-in `/review` (+ `pr-merger` agent) |
| `security-guidance` | built-in `/security-review` (+ `security-reviewer` agent) |
| `context7` | Copilot MCP (context7 MCP server) or `docs-resolver` agent via web/`/research` |
| `playwright` | Copilot Playwright MCP / plugin (verify availability) |
| `typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp` | built-in `/lsp` |
| `frontend-design` | fold guidance into `ux-engineer` / `design-system-architect` agents |
| `claude-md-management`, `claude-code-setup` | **drop** (Claude-specific tooling) |
| `gitnexus` (CLI + MCP) | **KEEP — mandatory.** Standalone CLI + MCP, not a Claude plugin. Wire as a Copilot MCP server and preserve the "`gitnexus impact` before any cross-file edit" gate. |

### Agent frontmatter conversion (Claude → Copilot `.agent.md`)

Distinct fields found across all 32 agents: `name, description, model, tools, disallowedTools, skills, memory, agent`.

| Field | Copilot handling | Action |
|---|---|---|
| `name` | ✅ honored | keep |
| `description` | ✅ honored | keep |
| `tools` | ✅ honored (tool allow-list) | keep; translate Claude tool names to Copilot tool names |
| `model` | honored (`/model`, `/subagents`) | map `opus`/`sonnet` → real Copilot model IDs; default `auto` |
| `Agent(pm)` grants (inside `tools:`) | ❌ not needed | **drop** — Copilot's model decides delegation; no explicit grant list |
| `disallowedTools` | partial | express as omission from `tools:` allow-list |
| `skills` | ❌ silently ignored | **drop** — Copilot auto-loads skills by `description` relevance; move the "read your skills" bootstrap out of frontmatter |
| `memory: user` | ❌ silently ignored | **drop** — use native `/memory` |

> **Bootstrap note:** every agent body currently says "read every skill in your `skills:` list from `.claude/skills/{name}.md`." Since Copilot auto-surfaces skills by description, these bootstrap paragraphs must be rewritten (or removed) — a real, per-agent edit, not a find/replace.

### What changes vs Claude Agent Teams (honest trade-offs)

Copilot has the *capabilities*, but a few behaviors differ in shape. These are called out so nothing is silently lost:

| Claude behavior | Copilot reality | Decision |
|---|---|---|
| **Visible tmux panes** the user watches live (`Shift+Down`, `Enter`, `Escape`) | Subagents run in-process; progress shown via `/tasks`, reasoning display (`Ctrl+T`), background tasks (`Ctrl+X B`) — not separate watchable panes | **Accept.** Re-home the "user visibility" need onto `/tasks` + status updates. Remove pane-snapshot rules. |
| **Inter-agent `SendMessage`** (engineer↔QA↔architect loops) | Subagents are one-shot request/response; the lead serializes hops | **Accept + adapt.** Lead orchestrates loops explicitly (re-invoke with feedback). Rewrite `team-handoff` skill accordingly. |
| **Worktree-per-agent** isolated parallel edits | Subagents share cwd by default; Copilot Task agents run in separate context but not separate worktrees automatically | **Design task.** Keep git-workflow's cap-branch model; have the lead sequence file-conflicting edits, or instruct agents to use explicit worktree paths. Validate in Phase 8. |
| **Pane crash → checkpoint/respawn** | No panes to crash; lead session recoverable via `/resume`, `--continue`, `/session` | **Accept.** Delete pre-spawn/pane-health/session-checkpoint skills. |


---

## 4. Target architecture (Copilot-native)

```
barcaTeam/
├── .github/
│   ├── copilot-instructions.md      # canonical entry: "delegate to @lead" + Copilot controls
│   ├── agents/*.agent.md            # all agents (converted frontmatter)
│   └── skills/*/SKILL.md            # all skills (de-Claude'd)
├── AGENTS.md                        # cross-tool agent index (optional, Copilot-read)
├── mcp-config.json / .copilot/      # MCP servers (whatsapp bridge, memory→native)
├── whatsapp-bridge/ (was claude-ping/)   # de-Claude'd WhatsApp MCP
├── scripts/
│   ├── install.ps1 / install.sh     # install @github/copilot + MCP + plugins
│   └── doctor.ps1 / doctor.sh       # verify copilot CLI, agents, skills, MCP
├── start.ps1 / start.sh             # copilot --add-dir <repos>
├── README.md                        # Copilot-first
└── docs/…                           # de-Claude'd references
```

**Orchestration model:** The `lead` agent remains the single entry point. Instead of spawning tmux panes, it uses Copilot **fleet mode** (`/fleet`) and the **Task/subagent** system to run PM / architect / engineer / QA / persona agents in parallel or sequence. All the pane-health / pre-spawn / psmux-workaround / session-checkpoint machinery is **removed** — it existed only to work around tmux fragility that no longer applies.

---

## 5. Migration phases

**Phase 0 — Safety.** Commit current state; create `cap/copilot-migration` branch.

**Phase 1 — Instructions.** Author canonical `.github/copilot-instructions.md` + `AGENTS.md`. Strip tmux/psmux/TeamCreate/pane-health/pre-spawn/session-checkpoint rules. Rewrite routing to Copilot fleet/subagent model. Delete `CLAUDE.md`.

**Phase 2 — Agents.** Move `.claude/agents/*.md` → `.github/agents/*.agent.md`. Convert frontmatter (drop `Agent(...)` grants, `memory:`; map `model:`; keep `name`/`description`/`tools`). Purge tmux/psmux/CLAUDE.md references from bodies; repoint skill references.

**Phase 3 — Skills.** Move `.claude/skills/*` → `.github/skills/*`. Rewrite `git-workflow`, `engineer-workflow`, `pre-spawn-check`, `pane-health-check`, `session-checkpoint`, `context-discovery` to Copilot reality (delete the pane/psmux-only skills or repurpose).

**Phase 4 — Plugins & MCP.** Port `.mcp.json` → `~/.copilot/mcp-config.json` (via `/mcp add` or generated by install). **Memory continuity:** keep the `@modelcontextprotocol/server-memory` MCP as-is (platform-neutral) to preserve the existing knowledge graph, and *additionally* rely on native `/memory`; only drop the `memory:` frontmatter field. Remap plugins per §3. Convert `.claude/settings.json` → Copilot `settings.json` / `/settings` (drop `CLAUDE_CODE_*` env, `teammateMode`, `enabledPlugins`).

**Phase 5 — WhatsApp bridge.** ~~Rename `claude-ping/` → `whatsapp-bridge/`~~ **DECISION (user, this session): remove WhatsApp entirely.** Deleted the `claude-ping/`/`whatsapp-bridge/` directory (embedded git repo/gitlink) and the `.wwebjs_cache/` session artifacts; removed the WhatsApp MCP server from `.mcp.json`; stripped all WhatsApp guidance from `copilot-instructions.md` and the improvement-loop/solution-review skills. No WhatsApp dependency remains.

**Phase 6 — Scripts & launchers.** Rewrite `install.*`, `doctor.*`, `start.*`; delete `launch.sh`/`dev-env.sh`/`upgrade-psmux.ps1`/`tmux-cheatsheet.md`. Rewrite/drop `export-conversation.js`.

**Phase 7 — Docs & cleanup.** Rewrite `README.md` Copilot-first. Fix `docs/capabilities/**`, `.gitignore`, stray root docs. Remove `.claude/` once nothing references it. Update stored memories that encode tmux/psmux conventions.

**Phase 8 — Verify.** `doctor` passes; `copilot` launches against a repo; `@lead` runs an end-to-end dry run using fleet/subagents; WhatsApp MCP send/receive works.

---

## 6. Open decisions (for user)

1. **claude-ping / WhatsApp:** ~~repoint to `copilot -p`, or keep only the WhatsApp MCP?~~ **RESOLVED (user): remove WhatsApp entirely.** Directory, session caches, MCP entry, and all references deleted.
2. **CLAUDE.md:** delete outright (recommended, cleanest) vs. keep a thin back-compat shim? User asked to remove Claude references → **delete**.
3. **`.claude/` directory:** delete entirely after moving agents/skills, or leave an empty compat symlink? (Recommend: delete.)
4. **History/branch:** single `cap/copilot-migration` PR vs. phased PRs.
5. **gitnexus / context7:** keep as Copilot MCPs or drop during migration?

---

## 7. Risks (post-verification status)

Most original risks were **resolved** by the §1.5 verification pass:

- ✅ **Agent discovery** — repo `.github/agents/` is auto-discovered (docs-confirmed). No sync step needed; the 7-of-32 copies in `~/.copilot/agents/` are stale legacy and will be deleted.
- ✅ **Skill discovery** — `.github/skills` (and `.claude/skills`) are native Copilot project-skill locations; SKILL.md format is portable.
- ✅ **MCP** — `~/.copilot/mcp-config.json` is the target; WhatsApp + memory + gitnexus + context7 are all plain stdio MCP servers.
- ✅ **Memory** — preserved by keeping the memory MCP; no data-loss migration required.

**Remaining (design-level, tracked in §3 "What changes"):**
- ⚠️ **Worktree-per-agent parallelism** — needs a validated pattern under Copilot's shared-cwd subagent model (Phase 8 gate).
- ⚠️ **Inter-agent loops** (QA↔engineer↔architect) — lead must orchestrate explicitly; `team-handoff` skill rewrite required.
- ⚠️ **User live-visibility** — panes replaced by `/tasks` + status updates; confirm this is acceptable UX.
- ⚠️ **claude-ping spawn parity** — `copilot -p` output may interleave status/telemetry vs Claude's clean stdout; small spike needed before trusting `resolve(stdout.trim())`. (Recommended path: keep WhatsApp send/receive MCP, drop the chat-spawn feature entirely.)
- ⚠️ **Plugin behavior gaps** — `security-guidance` (passive hooks) → replicate via Copilot **hooks**, not a one-shot `/security-review`, to preserve inline warning behavior.
- ⚠️ **Stale memories** — tmux/psmux/TeamCheck conventions in stored memory must be downvoted so agents stop following dead workflows.
