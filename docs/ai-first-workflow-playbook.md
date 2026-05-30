# AI-First Delivery Playbook — PDLC/SDLC Workflow

**Audience:** Engineering & product team
**Agent of record:** Claude Code (terminal + IDE extension)
**Scope:** How we run product and software delivery in an AI-first way, end to end.
**Status:** Team direction — follow this on the e-commerce integration engagement; refine as we learn.

---

## 1. Operating principles (read first)

These five principles decide every judgment call below.

- **The spec is the source of truth.** We write intent down before code. The agent works from the spec, not from vibes. If it isn't in the spec, it isn't agreed.
- **The agent drives; the human holds the gate.** Claude Code does the typing. A named human approves at every gate (spec, plan, PR). Approval is an active decision, not a rubber stamp.
- **Quality gates are non-negotiable and automated.** Tests, linters, type checks, and security scans run automatically and block bad work *before* a human reviews it. ~45% of unguarded AI-generated code carries a vulnerability — the gates are how we stay below that.
- **You own what you merge.** "The agent wrote it" is never an explanation for a defect. If you can't explain a diff, you don't merge it. We do not accumulate code we don't understand.
- **Optimize for outcomes, not tokens.** More agent activity is not the goal. Shipped, correct, reviewable features are the goal. Watch cost like you watch latency.

---

## 2. The toolchain we standardize on

One agent, a thin set of supporting tools. Don't add to this without team agreement.

| Layer | Tool | Why it's here |
|---|---|---|
| **Coding agent** | **Claude Code** | Our single agent. Used via terminal and the VS Code / JetBrains extension (same engine, GUI surface). Highest-quality reasoning for multi-file work; 1M-token context; native subagents, hooks, skills, MCP. |
| **IDE** | Your existing VS Code **or** JetBrains | We are NOT mandating Cursor. The Claude Code extension runs inside your real IDE, so you keep your debugger, language servers, and config. JetBrains teams use the JetBrains plugin. |
| **Spec framework** | **GitHub Spec Kit** | Drives the Specify → Plan → Tasks → Implement loop as slash commands inside Claude Code. Portable, no lock-in. |
| **Code review** | **Claude Code GitHub App** (@claude PR review) + deterministic CI gates | Automated first-pass review on every PR. Humans do final review on top. |
| **Connectors** | **MCP servers** (Shopify Dev/Storefront MCP, GitHub, Sentry, etc.) routed through a **governed MCP gateway** | How the agent safely reads/writes external systems. Gateway gives us auth, least-privilege, and audit logs. |
| **CI/CD** | Existing pipeline + Claude Code **Agent SDK** for automation | Quality gates and async agent tasks run here. |

**Claude Code primitives we use (and when):**

- **`CLAUDE.md`** — project memory the agent reads every session. Conventions, stack, domain rules, "do/don't." Treat it like production config; iterate when the agent keeps getting something wrong.
- **Plan Mode** — agent researches and produces a plan *without writing code*. Always plan before implementing.
- **Skills** (`.claude/skills/`) — reusable, versioned workflows invoked as slash commands (e.g., `/review-pr`, `/shopify-storefront-query`). Kills copy-pasted mega-prompts.
- **Subagents** (`.claude/agents/`) — isolated-context specialists (e.g., `code-reviewer`, `test-writer`, `security-checker`) for parallel or deep work without polluting the main context.
- **Hooks** (`settings.json`) — deterministic guardrails on agent actions: auto-lint on write, block destructive commands, run tests before "done." This is how rules get *enforced*, not just requested.
- **MCP** — connect GitHub, Shopify, issue tracker, observability, so the agent works from real context instead of pasted snippets.

---

## 3. One-time repo setup (do this before any feature work)

Per project, set up the scaffolding once:

1. **Write `CLAUDE.md`** at the repo root: tech stack, coding conventions, architecture notes, security rules, domain glossary, and explicit "prohibited zones" (auth, payments/PCI, secrets handling).
2. **Install Spec Kit** and create the `specs/` directory; commit it to the repo so specs are versioned with code.
3. **Configure MCP servers** through the gateway: GitHub + the client's systems (Shopify Dev/Storefront MCP for the e-commerce work). Never wire raw credentials into an agent on a laptop.
4. **Add hooks** for the baseline gates: lint-on-write, block `rm -rf` and force-push, run the test suite before a task is marked complete.
5. **Create the core subagents:** `code-reviewer`, `test-writer`, `security-checker`. Give each least-privilege tool access.
6. **Install the Claude Code GitHub App** for automated PR review and `@claude` responses.

After this, every feature follows the same loop below.

---

## 4. The end-to-end workflow

The lifecycle runs in two halves: **PDLC** (decide what to build) feeds **SDLC** (build it). The PRD/spec is the handoff artifact between them.

```
  PDLC                          handoff            SDLC
  ────────────────────────     ─────────     ─────────────────────────────────────────
  Discovery → PRD → Prioritize  →  Spec  →  Plan → Tasks → Implement → Test → Review → Ship → Observe
     (PM-led, AI-assisted)              (agent-driven, human-gated, quality-gated)
                                                                                    │
                                                              feedback ◄────────────┘
```

### PDLC — deciding what to build (PM-led, AI-assisted)

| Phase | Agent/AI does | Human does | Gate |
|---|---|---|---|
| **Discovery** | Synthesize feedback/tickets/research, cluster themes, surface patterns | Frame the problem; interpret real customer need | PM decides the problem is worth solving |
| **PRD / Requirements** | Draft the PRD, user stories, acceptance criteria | Set goals, constraints, success metrics; edit the draft | PM + tech lead sign off on the PRD |
| **Prioritization** | Score options (RICE/ICE), forecast impact, draft stakeholder updates | Make the trade-off call | PM commits the scope |

**Output:** an agreed PRD with acceptance criteria. This is the input to the spec.

### Handoff — PRD becomes a spec

- The tech lead (with Claude Code) converts the PRD into a structured spec using Spec Kit's `/speckit.specify`. The spec captures *what* and *why* — acceptance criteria, edge cases, data contracts, non-functional requirements. **No tech stack decisions yet.**
- **Gate:** tech lead reviews the spec for completeness before planning. A weak spec guarantees weak output.

### SDLC — building it (agent-driven, human-gated)

| Phase | Claude Code does | Human does | Gate / tooling |
|---|---|---|---|
| **Plan** | `/speckit.plan` (or Plan Mode) produces an architectural plan grounded in `CLAUDE.md`. **No code written yet.** | Review the plan; correct architecture before any code | **Human approves the plan.** |
| **Tasks** | `/speckit.tasks` decomposes into small tasks, each with its acceptance criteria / test intent defined up front (TDD-shaped) | Sanity-check the breakdown | Lead confirms tasks are isolated & reviewable |
| **Implement** | Per task, runs **double-loop TDD**: writes the failing **integration/acceptance test** (outer loop) to frame the behavior, then drives it green through fast **unit** red-green-refactor cycles (inner loop). Uses subagents for parallel/specialized work | Steer; handle security-critical logic yourself | Hooks auto-lint and run tests during the loop |
| **Test / QA** | `test-writer` subagent adds what sits outside the double loop: **end-to-end/system tests** and additional edge/failure scenarios across the whole feature | Review coverage; add adversarial cases | All tests pass (hook-enforced) before "done" |
| **Code review** | GitHub App + `code-reviewer` subagent do automated first-pass review | **Final review — architecture, business logic, security, "does it match the spec?"** | **Human approves the PR.** Review is now the real bottleneck — budget time for it. |
| **Security** | `security-checker` subagent + SAST/secret scan in CI | Review findings on AI-touched paths | Security gate must pass — mandatory, not optional |
| **Ship (CI/CD)** | Pipeline runs; agent can open/raise the PR via GitHub App | Own the release decision | All gates green; human merges |
| **Observe & feed back** | Deterministic gates feed failures back for auto-correction; telemetry loops to PDLC discovery | Triage incidents; decide what changes | Production signals → next spec |

### Keep the loop small — one acceptance scenario per PR

Chunk work into multiple small PRs rather than one giant agent-generated diff. Small batches are easier to review, safer to ship, and the single biggest lever on quality. The right unit for a chunk is **one outer-loop (integration/acceptance) scenario per PR** — one complete, demonstrable behavior, proven by its integration test and backed by whatever inner unit cycles it took to get there.

Why this boundary beats "a few hundred lines": each PR has a natural boundary (the scenario), a natural definition of done (outer loop green), and a natural review entry point (read the test first, then check the diff delivers it). The PR becomes self-justifying.

**Worked example — "apply a discount code to the cart."** Instead of one PR titled *"implement discount codes"* carrying a 1,500-line diff, direct Claude Code to deliver a sequence, each PR one scenario:

- **PR 1** — *Valid code applies a percentage discount to the cart.* (carries the shared scaffolding too — data model, endpoint skeleton)
- **PR 2** — *Expired code is rejected.*
- **PR 3** — *Code already used by this customer is rejected.*
- **PR 4** — *Discount cannot exceed cart value.*
- **PR 5** — *Two conflicting codes resolve per the business rule.*

Each is independently reviewable and shippable, and each leaves `main` releasable. The feature emerges as a stack of small green slices rather than one big bang.

**What makes this actually work (not just sound nice):**

- **Sequence tasks to match PRs.** This is applied back at task decomposition, not at PR time. When `/speckit.tasks` breaks down the spec, require **one acceptance scenario per task** so each task maps 1:1 onto a PR. If the breakdown is *scenario-shaped*, the PR chunking falls out for free. If it's *layer-shaped* ("build the model," "build the API," "build the UI"), you get PRs that can't ship independently and the whole benefit collapses.
- **Happy path first, edge cases layered on top.** The first PR for a feature legitimately carries some shared scaffolding alongside its scenario — expected. Later PRs should be mostly behavior, little plumbing, so review effort drops PR over PR. Tell the agent to start with the simplest passing scenario.
- **One outer loop per PR is the rule; use judgment.** A few trivially related assertions can ride together. What you're preventing is the PR that bundles several distinct behaviors so the reviewer can't tell which diff serves which claim. The test: *can a reviewer name what this PR does in one sentence, and does one integration test prove it?* If yes, the chunk is right-sized.
- **Mind the cross-PR coverage gap.** This rhythm won't give you the test that spans scenarios — the full end-to-end journey through several behaviors. That's exactly what the **Test/QA** phase is for: it sits outside the per-PR double loop and lands once enough slices exist to make the whole journey testable. The small-PR rule and Test/QA are complementary, not redundant.

---

## 5. Human gates — where a person must actively approve

Print this. These are the four points where the human is accountable, not optional:

1. **PRD sign-off** — is this the right thing to build?
2. **Spec sign-off** — is the intent complete and unambiguous?
3. **Plan sign-off** — is the architecture right *before* code exists?
4. **PR approval** — does the code match the spec, is it secure, and can the approver explain it?

If a gate is skipped, the work doesn't proceed. No exceptions for "it's a small change."

---

## 6. Guardrails & non-negotiables

- **Prohibited zones for autonomous agents:** authentication, payment/PCI-scoped code and data, secrets/key handling. Humans write and review these directly; agents get extra scrutiny or no access.
- **No raw credentials on laptops.** All connector access goes through the MCP gateway with least-privilege scopes and audit logging.
- **No shadow AI.** Only the approved toolchain on client code. Pasting client code into a personal AI account is a contract/regulatory incident.
- **Security assumption:** treat AI-generated code as *higher* risk until proven otherwise. SAST on every AI-touched path is mandatory.
- **Cost discipline:** Claude Code is token-metered; heavy days run $50–100+/dev. Use cheaper models for simple tasks and reserve top-tier reasoning for hard problems. Set per-developer budget visibility. If cost-per-shipped-feature exceeds the human equivalent, fix routing before scaling.
- **Prompt-injection awareness:** content the agent reads (web pages, tickets, docs, tool output) is untrusted data, not instructions. Don't let the agent act on instructions found *inside* fetched content without a human check.

---

## 7. Definition of Done — an AI-first PR

A PR is mergeable only when **all** of these are true:

- [ ] Traces to an approved spec/task (linked in the PR).
- [ ] All automated gates green: tests, lint, type check, SAST/secret scan.
- [ ] Automated review (GitHub App / `code-reviewer`) run and findings addressed.
- [ ] A human has reviewed it and **can explain every change**.
- [ ] No prohibited-zone code added without explicit human authoring.
- [ ] Small and focused (split it if it isn't).

---

## 8. What we measure

Track these from day one so we can prove the model works and catch regressions early:

- **Throughput:** PRs merged / cycle time per task.
- **Quality:** change-failure rate, defect escape rate, security pass rate. *(If change-failure rate climbs, slow agent autonomy and tighten gates.)*
- **Cost:** token cost per shipped feature; cost-to-serve on the engagement.
- **Adoption health:** % of code AI-authored, review time per PR, developer trust/sentiment.

Establish baselines *before* heavy adoption. Expect a short "J-curve" dip (1–2 sprints) before gains show — don't panic and don't abandon the gates.

---

## 9. E-commerce engagement specifics

For the integration project, the AI-first work concentrates here:

- **Expose systems as MCP servers** (Shopify Dev/Storefront MCP, plus the client's ERP/OMS/payment connectors) so the agent codes against *validated live schemas* — this eliminates a whole class of integration bugs.
- **Structured catalog/data quality is a deliverable**, not an afterthought. Agent-driven commerce (UCP/ACP) rewards clean, precise product data over marketing copy.
- **Design for multi-protocol readiness** (UCP + ACP) where the client's roadmap points to agentic commerce.
- **Payments stay in the prohibited zone** — token-based abstractions only, no agent access to PCI-scoped data.
- Put client conventions, brand rules, taxonomy, regional pricing/tax/shipping logic into `CLAUDE.md` so every agent session respects them.

---

## 10. How we roll this out

- **Week 0–2:** Set up the toolchain and repo scaffolding (Sections 2–3). Name a pilot lead.
- **Week 2–6:** Pilot the full loop on one contained integration feature. Enforce all four gates. Instrument metrics.
- **Week 6–12:** Run a hands-on workshop ("ship a feature spec-first" with a coach). Build the shared skills library. Expand only if quality metrics hold.
- **Quarter 2+:** Standardize across the engagement; add async/background agent tasks for low-risk work (dependency updates, test backfill, docs).

**The one-line summary for the team:** *Write the spec, plan before you code, let Claude Code do the typing, never skip a gate, and own what you merge.*

---

## 11. Starter templates — the from-scratch path (copy into the repo)

> **Two paths, pick one (see Section 12 for the decision).** Section 11 is the **author-it-yourself** path: small, fully owned files you write and maintain. Section 12 is the **reuse-first** path: adopt proven community skills, pin them, and layer your house rules on top. Both produce the same workflow; they differ in how much you build vs. borrow. Start with Section 11 to learn the mechanics on the pilot, then graduate to Section 12 as you scale.

These are provided as ready-to-use files in the accompanying **starter kit** (same folder structure as a real repo). Copy them in and replace the `<PLACEHOLDERS>`. The highest-leverage file is `CLAUDE.md` — get it right first. The four examples below are the core; the kit also includes a `test-writer` subagent, a `/review-pr` skill, and a README.

### 11.1 `CLAUDE.md` (repo root) — project memory

Excerpt of the key sections (full file in the kit):

```markdown
## Conventions — DO
- Write the integration/acceptance test FIRST (outer loop), then drive it green with
  unit cycles (inner loop).
- One acceptance scenario per task and per PR. Keep diffs small and reviewable.
- Use the repo's existing error-handling and logging patterns.
- Validate and sanitize all external input (storefront, webhooks, third-party APIs).

## Conventions — DON'T
- Don't add a dependency without flagging it for human approval first.
- Don't edit generated files (anything under */generated/).
- Don't disable lint/type rules to make a check pass — fix the cause.
- Don't write code in Plan Mode. Plan first, implement after approval.

## PROHIBITED ZONES (humans write & review these directly — agent gets no autonomous access)
- Authentication / authorization logic
- Payment handling and any PCI-scoped code or data
- Secrets, API keys, credential handling
- If a task touches these, STOP and ask the human to take it.
```

### 11.2 `.claude/settings.json` — hooks that enforce the gates

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "pnpm lint --fix" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [{ "type": "command",
          "command": "grep -Eq 'rm -rf|git push --force|DROP TABLE' <<< \"$CLAUDE_TOOL_INPUT\" && { echo 'Blocked: destructive command.' >&2; exit 2; } || exit 0" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "pnpm typecheck && pnpm test" }] }
    ]
  }
}
```

Lint runs on every write; destructive commands are blocked before they execute; the task can't be marked done until type check and tests pass.

### 11.3 `.claude/agents/code-reviewer.md` — a subagent definition

```markdown
---
name: code-reviewer
description: Reviews a diff/PR for correctness, clarity, and spec-alignment in an isolated context.
tools: Read, Grep, Glob, Bash
---

You are a senior code reviewer running in a fresh context. Review the diff against:
1. Spec alignment — does it do exactly what the task asked, no more, no less?
2. Correctness — logic errors, unhandled cases, especially the spec's edge scenarios.
3. Tests — integration test for the behavior + meaningful unit coverage?
4. Security — unvalidated input, injection, secrets. If it touches a PROHIBITED ZONE, STOP.
5. Clarity & conventions — matches CLAUDE.md and the existing codebase?

Output: one-line verdict; blocking issues (file:line + fix); non-blocking suggestions.
Be terse. No praise padding.
```

(The kit also ships `security-checker.md` and `test-writer.md` in the same format.)

### 11.4 `specs/<feature>/spec.md` — the spec template, filled in

The discount-codes example shows the pattern: a short Why/Scope, non-functional requirements, then **numbered acceptance scenarios — each becomes one task and one PR**, happy path first:

```markdown
### Scenario 1 — Valid code applies a percentage discount  (carries shared scaffolding)
- Given a cart subtotal of $100 and a valid active code "SAVE10" worth 10%
- When the code is applied
- Then the cart shows a $10 discount and a $90 total.

### Scenario 2 — Expired code is rejected
- Given a cart and a code whose validity window has passed
- When the code is applied
- Then no discount is applied and the cart shows an "expired code" reason; total unchanged.

### Scenario 3 — Code already used by this customer is rejected
### Scenario 4 — Discount cannot exceed cart value
### Scenario 5 — Two conflicting codes resolve per business rule
```

This is the connective tissue of the whole method: the five scenarios drive five tasks (Section 4), five small PRs (Section 4.1), each built with double-loop TDD, and the cross-scenario journey lands in Test/QA.

---

## 12. Reuse-first path — adopt the community, encode our house style on top

Section 11 has us authoring every file. That's the right way to *learn* the mechanics, but at scale it means maintaining a workflow the community already maintains better. Section 12 is the alternative: **borrow the proven engine, pin it, and keep only our house rules as bespoke.** Same four gates, same double-loop TDD, same small-PR discipline — less to build and maintain.

### 12.1 Section 11 vs. Section 12 — what's different

| | **Section 11 — from scratch** | **Section 12 — reuse-first** |
|---|---|---|
| Workflow engine (spec→plan→TDD→review) | We hand-author it | Adopt a community skill library (e.g. `superpowers`) |
| Subagents (reviewer, tester, security) | We write each one | Adapt proven ones; wrap official security action |
| Who maintains the engine | Us | Upstream community + Anthropic |
| What we own | Everything | Only our house layer (gates, prohibited zones, client conventions) |
| Best for | Learning the method; the pilot | Scaling across engagements |
| Main risk | Reinventing + maintenance burden | Upstream drift; framework-tier policy limits |

**The rule of thumb:** we own the *decisions* (what to enforce, where the gates are, what's off-limits, client specifics); we borrow the *mechanics* (the lifecycle skeleton, the TDD loop, generic subagents). Author energy goes to the parts that are genuinely ours.

### 12.2 What to reuse (verify currency before adopting — this ecosystem moves monthly)

> **Our SDD engine is superpowers-native.** Spec-Driven Development is run through
> **superpowers' own skills** (brainstorming → spec → planning → tasks), NOT a separate SDD
> tool. We are deliberately **not** running GitHub Spec Kit in this kit. The earlier
> `/speckit.*` references (Sections 4 and 11) describe the generic SDD pattern; in the
> reuse-first kit, superpowers owns that loop. The `specs/` folder simply holds the spec
> artifacts the loop produces.
>
> *If you ever add Spec Kit later,* draw a hard line to avoid the overlap on planning:
> **Spec Kit owns spec/plan/tasks; superpowers owns implement/test/review.** Don't run both
> planning engines at once.

- **Workflow engine — `obra/superpowers`.** A battle-tested spec→plan→TDD→review skill library, accepted into Anthropic's skills marketplace. Overlaps heavily with our method; adopt as the engine, layer our gates on top. This is also our SDD engine (see note above).
- **Official Anthropic repos.** `anthropics/skills` (Agent Skills reference), `claude-plugins-official` (vetted plugin directory), and **`claude-code-security-review`** (an AI-powered security-review GitHub Action) — the last is a better-maintained replacement for part of our hand-rolled `security-checker`.
- **Subagents — `wshobson/agents`.** Production-ready subagents; pull individual ones (reviewer, tester) and adapt rather than reinventing.
- **MCP servers.** For the e-commerce work, pull connectors from the curated MCP lists (Shopify, Stripe, the client's ERP) instead of writing them.
- **Discovery indexes (bookmark, don't depend on):** `skills.sh`, `awesome-skills.com`, `travisvn/awesome-claude-skills`. Filter by recent commits and practitioner curation — a list updated this week is current; one updated a year ago is archeology.

> **Policy check before adopting frameworks:** Anthropic's April 2026 change restricts third-party *agent frameworks* on some subscription tiers. Skills, subagents, and hooks are first-class and unaffected; heavyweight orchestration frameworks (e.g. full BMAD agent-teams, Claude-Flow) may not be. Confirm against our plan and current docs first.

### 12.3 How to reuse it safely — three rules

1. **Vendor, then pin.** Bring community skills in as a **git submodule or version-pinned dependency**, never loose copied files. Pin to a known-good commit/tag so an upstream change can't silently alter our agents mid-engagement. Upgrade deliberately, not automatically.
2. **Wrap, don't fork.** Leave upstream files untouched; put *our* house rules (prohibited zones, client conventions, the four gates) in a thin local layer on top (`CLAUDE.md` + a few local skills/subagents that call the community ones). When upstream updates, we `git pull`; our overrides are unaffected. Forking means inheriting the maintenance burden we were avoiding.
3. **Right primitive for the right job.** Use **skills** for portable expertise (a TDD workflow, a framework's idioms); use **subagents** for self-contained, permission-scoped work; subagents can call skills. Reuse community *skills* for know-how; keep *subagents* as our own thin, scoped wrappers.

### 12.4 How to encode it for the team — one internal "house" plugin

Turn the starter kit into a **distributable internal plugin/repo**, not a folder people copy by hand:

- **One distribution unit.** It contains our `CLAUDE.md` template, our house skills, our subagent wrappers, and our `settings.json` hooks. Community pieces enter as **pinned submodules**. The team installs one thing; we update one thing.
- **Gates live in hooks/CI, not prose.** A rule a human must remember gets skipped under deadline. Keep the Section 11 hooks, and add the official security-review action as a required CI check.
- **One owner, fixed cadence.** Designate a maintainer to review upstream updates (e.g. biweekly), test against our repo, and bump the pins. Everyone else consumes the known-good vendored version.
- **Provenance note per reused component.** Record where it came from, which commit, and why we picked it. In six months that note is the difference between a five-minute fix and an afternoon of archeology.

### 12.5 Customizing the reused engine for our double-loop TDD

Our method uses **double-loop (outside-in) TDD**; `superpowers`' stock TDD skill enforces a strict single inner loop (Red → watch it fail → Green → Refactor). These don't conflict — **our double loop *contains* the stock inner loop.** The reused skill enforces exactly the inner cycle we want at each layer; we just supply the outer loop it doesn't know about.

**How the two fit together, on a hexagonal example:**

1. Write a failing **integration/acceptance test** at the outermost boundary (e.g. the REST controller). ← *outer loop, our framing*
2. Build the controller via Red-Green-Refactor. ← *inner loop, the stock skill*
3. Build the service the controller calls via Red-Green-Refactor. ← *inner loop*
4. Continue inward layer by layer (service → domain → ports → adapters), each with its own inner cycle. ← *inner loop, repeated*
5. The feature is done only when every layer was built via its own inner cycle **and** the outer integration test passes.

**What this means for reuse:**

- **Don't fork or fight the stock skill.** Its rigidity is about *not cutting corners* (no code before a test, no skipped refactor), not about scope. Outside-in asks for *more* discipline, not less, so there's nothing for it to resist.
- **Supply the outer loop from our house layer.** Put the double-loop framing in `CLAUDE.md` (our instructions take precedence over a skill where they differ). Something like: *"Use outside-in (double-loop) TDD. First write a failing integration/acceptance test at the outermost boundary. Then, working inward layer by layer, use red-green-refactor for each layer. Done only when every layer was built via its own inner cycle and the outer integration test passes."* This sits **above** the stock skill and tells the agent when to invoke it (once per layer) and what frame surrounds it.
- **Pilot check (sequencing, not resistance):** agents are eager and may write the outer controller test, then implement *all* layers in one rush to make it green — skipping the per-layer inner cycles (step 4). This is the classic outside-in slip, human or agent. Verify on the pilot that each layer gets its own failing inner test before that layer's code. If you see the shortcut, tighten the instruction to require an inner failing test per layer.

Only escalate to authoring a custom `double-loop-tdd` skill (shadowing the stock one) if the `CLAUDE.md` framing proves too weak in practice — that reintroduces maintenance burden, so treat it as the fallback, not the default.

### 12.6 Borrowing from BMAD without adopting the framework

BMAD (Breakthrough Method for Agile AI-Driven Development) is a full methodology-as-code framework — 19+ role-agents, 50+ workflows, its own document formats. It's excellent but heavy, and likely too much machinery for a team transitioning from casual use; it also sits near the framework-tier policy line. **Don't adopt it as our spine.** Do **mine its PDLC artifacts**: its product-brief and PRD workflow *shapes* are the strongest part for us and close the gap in our front half (Section 4, PDLC). Borrow the document patterns into our own templates; revisit the full framework only once agentic work is second nature and we're standardizing across many engagements.

**Section 12 in one line:** *Own the decisions, borrow the mechanics — adopt a proven engine, pin it, wrap it in our house rules, ship it as one internal plugin with a named maintainer.*
