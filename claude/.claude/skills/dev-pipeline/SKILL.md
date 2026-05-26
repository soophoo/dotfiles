---
name: dev-pipeline
description: "Full development pipeline: Architect designs → Developer implements → Reviewer reviews → QA tests → API Docs syncs OpenAPI/Postman → Deployer builds. Agents chain automatically — each waits for the previous to finish. Use when you want a complete implementation-to-deployment workflow for a feature or bug fix."
---

# Development Pipeline

This skill orchestrates **two agent teams** that work sequentially to deliver production-ready code.

## Teams

See `~/.claude/skills/dev-pipeline/teams/` for full team definitions.

### Backend Team (Stages 1-4)
| Role | Agent | Responsibility |
|------|-------|----------------|
| Tech Lead | Architect | Analyzes, designs, produces blueprint |
| Lead Developer | Lead Developer | Plans implementation, estimates complexity, validates feasibility |
| Senior Dev | Java Developer | Implements following the plan |
| Code Reviewer | Reviewer | Reviews code + architecture + security |
| QA Engineer | QA | Writes tests, validates quality |

### DevOps Team (Stages 5-6)
| Role | Agent | Responsibility |
|------|-------|----------------|
| API Doc Engineer | API Docs | Syncs OpenAPI + Postman collections |
| Release Engineer | Deployer | Builds, packages, verifies deployment |

## Pipeline Flow

```
                    ┌───────────────────────────── BACKEND TEAM ──────────────────────────────────┐   ┌──── DEVOPS TEAM ────┐
                    │                                                                              │   │                     │
REQUEST → [1. Architect] → [1.5 Lead Dev] → [2. Dev] → [2.5 Arch Validation] → [3. Review] → [4. QA] → [5. API Docs] → [6. Deploy] → DONE
                    │                                                                              │   │                     │
                    │  blueprint + plan flow to all stages ────────────────────────────────────────────────────────────────▶ │
                    └──────────────────────────────────────────────────────────────────────────────┘   └─────────────────────┘
```

Each stage must pass before the next begins. If any stage fails, the pipeline stops and reports what needs fixing.

### Team Coordination
- The **Architect (Tech Lead)** produces the blueprint — it flows to EVERY agent in both teams
- The **Lead Developer** translates the blueprint into a detailed plan — it flows to all stages after 1.5
- **Lead Developer ↔ Architect** can loop (max 2 retries) if blueprint has implementation issues
- **Backend Team** works sequentially: design → plan → implement → validate → review → test
- **Reviewer ↔ Developer** can loop (max 2 retries) before escalating
- **QA ↔ Developer** can loop (max 2 retries) before escalating
- **COMPLEX** complexity rating pauses the pipeline for user confirmation before Stage 2
- **DevOps Team** starts only after Backend Team completes successfully
- **API Docs** failures are warnings (non-blocking), everything else is blocking
- Only the **user** can approve actual deployment

## How Agents Are Defined

All agents are registered as **Claude Code subagents** in `~/.claude/agents/`:

| File | Agent Name | Role | Model |
|------|-----------|------|-------|
| `architect.md` | `architect` | Tech Lead — analyzes, designs, blueprints | Opus |
| `lead-developer.md` | `lead-developer` | Lead Dev — plans, estimates complexity, validates feasibility | Sonnet |
| `java-developer.md` | `java-developer` | Senior Dev — implements code | Sonnet |
| `code-reviewer.md` | `code-reviewer` | Reviewer — reviews quality + architecture | Sonnet |
| `qa-engineer.md` | `qa-engineer` | QA — writes/runs tests | Sonnet |
| `api-docs-engineer.md` | `api-docs-engineer` | API Docs — syncs OpenAPI + Postman | Sonnet |
| `deployer.md` | `deployer` | Release Engineer — builds + verifies | Sonnet |

These are proper Claude Code subagents with YAML frontmatter (name, description, tools, model).
Spawn them using the Agent tool with their name as `subagent_type`.

**Agent Teams** is enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json.

## How to Execute

When this skill is invoked, follow these steps **strictly in order**.

All stages **share a single git worktree** so changes flow from one agent to the next. The orchestrator (this session) creates the worktree in Stage 0, then every spawned subagent inherits that directory via an explicit `cd` at the start of its prompt.

### Stage 0: Worktree Setup

1. Derive a kebab-case **slug** from the feature request (≤40 chars). If ambiguous, ask the user once.
2. Set branch = `feature/<slug>` (or `fix/<slug>` for bug fixes).
3. Run:
   ```bash
   WORKTREE_PATH="$(git rev-parse --show-toplevel)/.claude/worktrees/${slug}"
   BRANCH="feature/${slug}"
   git worktree add "${WORKTREE_PATH}" -b "${BRANCH}"
   cd "${WORKTREE_PATH}"
   ```
4. If `.claude/worktrees/` is not in `.gitignore`, add it (in the main tree, commit separately — not in this pipeline).
5. Record `${WORKTREE_PATH}` and `${BRANCH}`; they flow to every subsequent stage.

**Gate:** `git worktree list` shows the new worktree, `pwd` is inside it → proceed.

### Stage 1: Architect Agent
Spawn the `architect` subagent:

```
Agent({
  description: "Architect: analyze and design <feature>",
  subagent_type: "architect",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nFEATURE REQUEST: <user's request>\n\nProject: Spring Boot 4.x, Java 25, hexagonal architecture, PostgreSQL.\nRead CLAUDE.md for project conventions.\nExplore the codebase structure before designing.\nProduce a detailed implementation blueprint."
})
```

**Wait for completion.** Save the blueprint — it flows to ALL subsequent stages.

**Gate:**
- Blueprint complete → proceed to Stage 1.5
- HIGH risk → pause and present to user for approval

### Stage 1.5: Lead Developer Agent
Spawn the `lead-developer` subagent:

```
Agent({
  description: "Lead Dev: plan implementation of <feature>",
  subagent_type: "lead-developer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nFEATURE REQUEST: <user's request>\n\nExplore the codebase to understand existing patterns and constraints.\nValidate the blueprint is implementable as designed.\nProduce a detailed step-by-step implementation plan with complexity estimate.\nEnd with: PLAN READY — [SIMPLE/MEDIUM/COMPLEX] or BLUEPRINT ISSUE."
})
```

**Wait for completion.** Save the implementation plan — it flows to all subsequent stages alongside the blueprint.

**Gate:**
- **PLAN READY — SIMPLE or MEDIUM** → proceed to Stage 2
- **PLAN READY — COMPLEX** → pause. Present complexity summary to user. Ask: *"Complexity is COMPLEX. Proceed with Stage 2? (y/N)"* On yes → Stage 2. On no → stop.
- **BLUEPRINT ISSUE** → re-spawn `architect` with the lead developer's objections. Architect revises blueprint → re-run Stage 1.5. Max 2 retries → if unresolved, escalate to user.

### Stage 2: Java Developer Agent
Spawn the `java-developer` subagent:

```
Agent({
  description: "Senior Dev: implement <feature>",
  subagent_type: "java-developer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nIMPLEMENTATION PLAN:\n<plan from Stage 1.5>\n\nFEATURE REQUEST: <user's request>\n\nRead CLAUDE.md. Follow the implementation plan strictly — it defines the order and exact structure.\nDo not deviate from the plan without a strong technical reason.\nWrite the code — create/modify all files in the plan.\nCommit your changes: `git add -A && git commit -m \"<conventional commit message>\"`."
})
```

**Wait for completion.** Note files created/modified.

**Gate:** Files match blueprint → proceed to Stage 2.5.

### Stage 2.5: Architect Blueprint Validation
Re-spawn the `architect` subagent to validate that the implementation matches the original vision:

```
Agent({
  description: "Architect: validate blueprint compliance",
  subagent_type: "architect",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nYOUR ORIGINAL BLUEPRINT:\n<blueprint from Stage 1>\n\nFILES CHANGED:\n<list from Stage 2>\n\nRun `git diff ${BRANCH_BASE:-main}...HEAD` to see what was implemented.\nYour job: verify that the implementation fully matches YOUR blueprint.\nCheck: every planned file exists, every port/adapter designed is implemented, no planned feature was skipped, no unplanned scope was added.\nDo NOT review code quality — that is the reviewer's job.\nFocus solely on: does reality match the design?\nEnd with: BLUEPRINT COMPLIANT or BLUEPRINT DEVIATION with a gap list."
})
```

**Wait for completion.**

**Gate:**
- **BLUEPRINT COMPLIANT** → proceed to Stage 3
- **BLUEPRINT DEVIATION** → re-spawn `java-developer` with the gap list. Fix → re-validate. Max 2 retries.

### Stage 3: Code Reviewer Agent
Spawn the `code-reviewer` subagent:

```
Agent({
  description: "Reviewer: review <feature>",
  subagent_type: "code-reviewer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nFILES CHANGED:\n<list from Stage 2>\n\nRun `git diff ${BRANCH_BASE:-main}...HEAD` to see changes on this branch.\nReview against checklist AND verify implementation matches blueprint.\nEnd with: APPROVE or REQUEST CHANGES."
})
```

**Wait for completion.**

**Gate:**
- **APPROVE** → proceed to Stage 4
- **REQUEST CHANGES** → re-spawn `java-developer` with feedback + blueprint. Re-run `code-reviewer`. Max 2 retries.

### Stage 4: QA Agent
Spawn the `qa-engineer` subagent:

```
Agent({
  description: "QA: test <feature>",
  subagent_type: "qa-engineer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nFILES CHANGED:\n<list from Stage 2>\n\nCheck existing tests. Write missing tests. Run `./mvnw test`.\nTest scenarios from the blueprint.\nIf you write new tests, commit them: `git add -A && git commit -m \"test: …\"`.\nEnd with: QA PASSED or QA FAILED."
})
```

**Wait for completion.**

**Gate:**
- **QA PASSED** → proceed to Stage 5
- **QA FAILED** → re-spawn `java-developer` with failures. Fix → re-review → re-test. Max 2 retries.

### Stage 5: API Documentation Agent
Spawn the `api-docs-engineer` subagent:

```
Agent({
  description: "API Docs: sync OpenAPI + Postman",
  subagent_type: "api-docs-engineer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nCONTROLLER FILES CHANGED:\n<controllers from Stage 2>\n\nDetect OpenAPI changes. If changes: update spec, sync Postman collection via MCP.\nIf the spec changed, commit it: `git add -A && git commit -m \"docs(api): sync OpenAPI + Postman\"`.\nEnd with: DOCS SYNCED or NO CHANGES or SYNC FAILED."
})
```

**Wait for completion.**

**Gate:**
- **DOCS SYNCED** or **NO CHANGES** → proceed to Stage 6
- **SYNC FAILED** → warn only (non-blocking). Proceed to Stage 6.

### Stage 6: Deployer Agent
Spawn the `deployer` subagent:

```
Agent({
  description: "Deployer: build and verify",
  subagent_type: "deployer",
  prompt: "WORKTREE: ${WORKTREE_PATH}\nBRANCH: ${BRANCH}\nStart with: cd ${WORKTREE_PATH}\n\nARCHITECT'S BLUEPRINT:\n<blueprint from Stage 1>\n\nAPI DOCS STATUS: <result from Stage 5>\n\nBuild: `./mvnw clean package`. Check Docker, migrations, config.\nVerify all planned changes were delivered.\nDO NOT push or open a pull request — the orchestrator handles that in Stage 7 only after user approval.\nEnd with: READY TO DEPLOY or NOT READY."
})
```

**Wait for completion.**

**Gate:**
- **READY TO DEPLOY** → proceed to Stage 7
- **NOT READY** → report blocking issues to user (skip Stage 7)

### Stage 7: Pull Request (orchestrator, user-gated)

The orchestrator — **not a subagent** — handles the push and PR, because opening a PR is an outward-visible action that requires explicit user confirmation per each run.

1. Show the user a summary: files changed, tests added, `./mvnw` result, branch name.
2. Ask: *"All stages green. Push `${BRANCH}` to origin and open a PR against `main`? (y/N)"*
3. On **yes**:
   ```bash
   cd ${WORKTREE_PATH}
   git push -u origin ${BRANCH}
   gh pr create --base main --head ${BRANCH} \
     --title "<conventional title from feature request>" \
     --body "$(cat <<'EOF'
   ## Summary
   <1–3 bullets from the architect blueprint>

   ## Pipeline Report
   - Architecture: ✅ <bounded context, risk>
   - Implementation: ✅ <files changed>
   - Review: ✅ <issues fixed during review loop>
   - QA: ✅ <tests added, ./mvnw test PASSED>
   - API Docs: <SYNCED / NO CHANGES>
   - Build: ✅ ./mvnw clean package

   🤖 Generated via /dev-pipeline
   EOF
   )"
   ```
4. Return the PR URL to the user.
5. On **no**: stop. Leave the worktree + branch for manual follow-up.

**Gate:** PR URL returned → pipeline complete.

### Cleanup (after PR is merged — user runs manually)

```bash
git worktree remove ${WORKTREE_PATH}
git branch -D ${BRANCH}            # optional; main repo will already have the merged commits
```

The pipeline itself never deletes the worktree — the user owns that step so WIP never disappears unexpectedly.

## Pipeline Report

After all stages complete (or if the pipeline stops), present a summary:

```
## Pipeline Report

### Stage 1: Architecture — [COMPLETE/HIGH RISK - USER APPROVED]
- Bounded context: [name]
- Impact: [summary]
- Risk: [LOW/MEDIUM/HIGH]
- Files planned: [count new + count modified]
- Design: [recommended approach summary]

### Stage 1.5: Planning — [PLAN READY / BLUEPRINT ISSUE / COMPLEX - USER APPROVED]
- Complexity: [SIMPLE / MEDIUM / COMPLEX]
- Steps planned: [count]
- Blueprint issues found: [none / list]
- Retries: [count if architect had to revise]

### Stage 2: Development — [DONE/FAILED]
- Files: [list of files created/modified]

### Stage 2.5: Blueprint Validation — [COMPLIANT/DEVIATION]
- Planned files delivered: [yes/no — missing list if any]
- Scope drift: [none/details]
- Retries: [count if any]

### Stage 3: Review — [APPROVED/CHANGES REQUESTED]
- Score: X PASS, Y WARN, Z FAIL
- Issues fixed: [if any retries happened]

### Stage 4: QA — [PASSED/FAILED]
- Tests written: [count]
- Tests passed: [count]
- Coverage: [areas covered]

### Stage 5: API Docs — [SYNCED/NO CHANGES/FAILED]
- Controllers changed: [list]
- OpenAPI spec: [updated/no changes]
- Postman collection: [synced/no changes/failed]

### Stage 6: Deployment — [READY/NOT READY]
- Build: [SUCCESS/FAILED]
- Docker: [SUCCESS/FAILED/SKIPPED]
- Migrations: [VALID/INVALID]

### Overall: [PIPELINE COMPLETE / PIPELINE STOPPED AT STAGE N]
```

## Options

The user can customize the pipeline:

- `/dev-pipeline` — full pipeline (all 6 stages)
- `/dev-pipeline --no-deploy` — skip deployment stage
- `/dev-pipeline --no-docs` — skip API docs sync
- `/dev-pipeline --dev-only` — only architect + developer (stages 1-2)
- `/dev-pipeline --from-dev` — skip architect, start from developer (code design already done)
- `/dev-pipeline --from-review` — start from review (code already written)
- `/dev-pipeline --from-qa` — start from QA (code already reviewed)
- `/dev-pipeline --from-docs` — start from API docs (code already tested)
- `/dev-pipeline --docs-only` — only run API docs sync + Postman push
- `/dev-pipeline --arch-only` — only run the architect (analysis + blueprint, no implementation)
- `/dev-pipeline --no-worktree` — run everything in the current working directory (skip Stage 0, skip Stage 7)

**Worktree handling with `--from-*` options:** When resuming mid-pipeline the code already lives somewhere. If the current `pwd` is already a worktree (detected via `git rev-parse --git-common-dir` differing from `git rev-parse --git-dir`), reuse it — skip Stage 0. Otherwise treat the current branch as the target and set `${WORKTREE_PATH}=$(pwd)`, `${BRANCH}=$(git symbolic-ref --short HEAD)`. Only `--arch-only` always runs in the main tree (architect never writes).
