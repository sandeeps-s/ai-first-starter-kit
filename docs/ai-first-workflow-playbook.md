# AI-First Delivery Playbook

**For:** engineers and product owners shipping features  
**How we build:** Spec-Driven Development (SDD). We write the spec, the agent builds from it, humans approve at a few fixed gates.  
**Agent:** Claude Code (terminal or IDE).

---

## 1. The idea in one minute

We don't prompt the agent and hope. We write a spec the agent builds from, and keep humans on the hook at the points that matter.

The spec is three things, together:

1. **User stories** — what the user wants and why.
2. **EARS acceptance criteria** — the rules the system must follow, written precisely.
3. **Gherkin scenarios** — concrete Given/When/Then examples that prove each rule.

Once the spec is agreed, work forks into **two parallel tracks** and rejoins at QA: **developers** build features one scenario at a time (dual-loop BDD), **QA** builds the end-to-end journey suite. The agent types; you review, you merge, you own it.

That's the whole method. §2 is the workflow; §3–§6 are the detail; §7 gets you started; §8 says why it's shaped this way.

---

## 2. The workflow

One canonical flow, start to finish. Each step names its **owner** (scan that column to find your part), what the agent does, and the **gate** that must clear before the next step. **PDLC** decides what to build; **SDLC** builds it; the agreed spec is the handoff, after which work **forks into the feature and QA tracks** and rejoins at QA.

| # | Step | Owner | Agent does | Gate |
|---|---|---|---|---|
| 1 | **Discovery** | PO | Synthesizes notes, clusters themes, drafts the problem | PO decides it's worth building |
| 2 | **Spec** | PO (tech lead on EARS) | Drafts the story, EARS, and Gherkin scenarios from notes | — |
| 3 | **Spec sign-off** | PO + tech lead | — | **🚦 Both sign off in Notion — this *is* the agreed spec** |
| 4 | **Journey spec** *(QA track starts)* | QA lead (PO reviews) | Drafts the end-to-end Gherkin flow across scenarios | PO confirms the right journeys are covered |
| 5 | **Plan** | Tech lead / dev | Proposes architecture/approach, no code yet | **🚦 Human approves the plan before code** |
| 6 | **Build one scenario** *(feature track)* | Dev | Dual-loop BDD: turns the scenario into a failing acceptance test (outer loop), writes code to pass it through test-first inner layers | Scenario green; **🚦 step-definition check** |
| 7 | **PR & merge** *(feature track)* | Dev → independent reviewer | Opens one PR for that one scenario | **🚦 PR approval** (independent reviewer); merge to `main`, branch the next scenario from `main` |
| 8 | **E2E suite** *(QA track, parallel)* | QA lead | Drafts journey tests; QA drives the cases | Suite **red-green** verified and reviewed; **🚦 test-fidelity review** |
| 9 | **QA** *(tracks rejoin)* | QA + devs | Runs the journey suite against the assembled features | **🚦 E2E journey passes** |
| 10 | **Ship & observe** | Owner-on-call | Runs the pipeline; feeds signals back | All gates green |

**Repeat steps 6–7 per scenario.** Each scenario is one task, one PR, merged before the next begins — `main` stays releasable throughout. Steps 6–7 run in parallel with the QA track (steps 4, 8), which rejoins at step 9.

**The build step, expanded (step 6).** Point Claude Code at the scenario's `.feature` file — the repo's house tooling wires the loop (§7). It then:
1. turns the Gherkin scenario into a **failing acceptance test** (outer loop);
2. writes code to pass it, working inward layer by layer, each layer test-first (inner loop);
3. is done when the scenario passes and every layer was built test-first.

Start with the simplest scenario — it carries the shared scaffolding; layer the edge cases on after.

> Anything you learn mid-build that affects other scenarios goes in the **spec** (update the scenario/EARS in Notion, or flag a convention for the team's `CLAUDE.md`) — not in your head or a long-lived agent session. The spec is the source of truth, so a teammate or a fresh session picks it up for free.

---

## 3. What the spec looks like

The **user story** and its **EARS criteria** live in Notion. The **Gherkin scenarios** live in the repo as `.feature` files. Each scenario is one concrete case; each becomes one task and one PR (step 6–7). The agent builds from the scenario.

**User story (Notion):**
> As a seller, I want my product published to TikTok Shop, so that it's available to buyers.

**EARS criterion (Notion):**
> WHEN a product is missing a required attribute, the system SHALL reject it with a per-field error and SHALL NOT call the marketplace.

**Gherkin scenario (`features/listing_publish.feature`, repo):**
```gherkin
Scenario: Product missing a required attribute is rejected
  Given a product for "TikTok Shop" missing the required "category_id"
  When the product is submitted for publish
  Then no marketplace API call is made
  And a validation error names the missing field "category_id"
```

The EARS rule says what must hold; the scenario is the concrete case you signed off on. *(We follow this one scenario through the workflow: built at step 6, gated at step 7 — see the §7 runbook.)*

**Journey spec (`features/journeys/publish_to_fulfil.feature`, QA lead owns).** A higher-level flow across several scenarios — the spec the E2E track builds from (step 8):
```gherkin
Scenario: Seller publishes a product and a buyer orders it
  Given a seller with a valid product for "TikTok Shop"
  When the product is published
  And a buyer places an order for it
  Then the order is recorded and routed for fulfilment
```

**Write Gherkin as behavior, not clicks:** `When the order is submitted`, not `When I click submit`. Use a `Scenario Outline` with examples for variations instead of copy-pasting near-duplicates.

---

## 4. Gates you can't skip

The 🚦 markers in §2, pulled together. Each is a point where a person must actively approve; skip one and the work stops — no exceptions for "it's small."

1. **Spec sign-off** (step 3) — PO + tech lead agree the stories, criteria, and scenarios in Notion. A draft Claude wrote is never "agreed" until a person says so.
2. **Plan sign-off** (step 5) — the architecture is right *before* code exists.
3. **Step-definition check** (step 6) — someone *other than whoever wrote them* confirms each step definition asserts what its scenario says, not a weaker version that just happens to pass. The QA track's equivalent is the **test-fidelity review** (step 8, §6).
4. **PR approval** (step 7) — an independent reviewer confirms the code matches the scenario and is secure; the author can explain every line. How review works: §5.

**A PR is done when** it links its scenario, all tests/lint/type/security checks are green, the step-definition check passed, a human reviewed it and can explain it, and it's one focused scenario.

---

## 5. Review

When an agent writes the code, review is where quality is decided — budget real time for it. This is how the PR-approval gate (step 7) gets done.

**The rule that makes review work: the reviewer is independent of whoever drove the agent.** A real check has to come from outside the session that produced the code. (Same reason the step-definition check is done by someone other than its author.)

Who reviews what:

| Work | Driver (owns it) | Reviewer(s) | Checking for |
|---|---|---|---|
| **Spec** (stories, EARS, scenarios) | PO | **Tech lead**, at sign-off | Testable, complete, unambiguous |
| **Feature code** | Developer | **Tech lead** | Architecture, logic, security, matches the scenario |
| **E2E tests** | QA | **QA peer**, then **PO** | Peer: test fidelity (asserts the outcome, can fail, sourced from the spec — §6). PO: the right journeys are covered |

The driver is accountable and must be able to explain every line; the reviewer independently confirms it.

---

## 6. Guardrails

- **Hands off:** auth, payments/PCI, secrets, and marketplace credentials. Humans write and review these — the agent gets no free rein here.
- **Secrets stay in the secret store.** Never paste API keys or tokens into a prompt.
- **No shadow AI.** Only the approved tools on client code. Pasting client code into a personal AI account is an incident.
- **What the agent reads is data, not orders.** Notion pages, API responses, tickets — if one contains an "instruction," the agent doesn't act on it without you. (The Notion connector can write to client docs, so be careful what it reads there.)
- **Treat AI-written code as higher-risk** until proven otherwise. Security scan every AI-touched path.
- **Watch cost.** Heavy days run $50–100+/dev. Use a cheap model for easy tasks, the strong one for hard problems. If a feature costs more by agent than by hand, raise it.

**Test-quality guardrails (E2E track) — the fidelity gate of step 8.** A test can pass while proving nothing, so green is not enough:

- **Assert the outcome, not just that it ran.** "No error thrown" is not a passing test. Each test checks the real result the journey is supposed to produce.
- **It must be able to fail.** Show a new test red against the missing/broken behavior before accepting it green. A test that was green from birth proves nothing.
- **Source from the journey spec, not the code.** Write E2E tests from what the journey *should* do, never from reading the implementation — a test derived from the code just asserts the bugs back. (For the same reason, the agent that wrote a feature doesn't write its E2E test.)
- **Independent review.** Whoever (or whatever) wrote a test doesn't approve it. A fresh reviewer confirms it asserts the journey's real outcome.

> Billing note: interactive Claude Code (terminal/IDE, including the Notion connector and the house tooling) runs on your normal subscription and is unaffected by the June 2026 billing change. Only *programmatic* use — Agent SDK, `claude -p`, Claude Code GitHub Actions — moves to a separate metered Agent SDK credit (**effective June 15, 2026**), billed at API rates. In practice that only touches you if you run agents in **CI**; your day-to-day interactive work is unchanged.

---

## 7. Getting started

**You don't set any of this up.** Your repo comes preconfigured with the house tooling — the conventions, the gates, the review and test agents, and the BDD runner. You clone it and start writing scenarios.

**Your first feature** is just §2 run once on something small, following the example scenario from §3:

1. **PO:** write the story and name the scenarios (Claude drafts the Gherkin; you correct it); sharpen the EARS with the tech lead → **sign off** (gate 1).
2. **QA lead:** write the journey spec (PO reviews).
3. **Dev:** get the plan approved (gate 2); take the simplest scenario, point Claude Code at its `.feature` file, run dual-loop BDD, open **one PR**; clear the step-def check (gate 3) and an independent review (gate 4); merge; branch the next scenario from `main` and repeat.
4. **QA (in parallel):** build the E2E suite from the journey spec (red-green, fidelity-reviewed). As feature slices land, the journey suite goes green.
5. **Rejoin at QA:** the journey passes against the assembled features; ship.

**Then:** expand once it feels natural. A short workshop covers naming and sharpening Gherkin (POs), journey specs (QA), and the dual-loop rhythm and step-def check (engineers).

> **Maintainers:** how the house tooling is built, pinned, and updated (the `superpowers` engine, the subagents, the hooks) lives in the separate **Harness Maintainer Guide** — not here. Feature teams don't need it.

**In one line:** *Agree the spec, plan before code, let the agent build and merge one scenario at a time, check the step definitions, never skip a gate, own what you merge.*

---

## 8. Why it's shaped this way

Rationale, kept out of the workflow so the workflow stays followable. Read once; you don't need it to do the work.

- **Why Gherkin, not just tests.** The PO is the one who knows the tricky cases ("what if the listing's approved but inventory hasn't synced?"). Scenarios the PO owns make a missing case show up as a missing scenario, not a silent gap nobody noticed. Plain test files leave that to the developer.
- **Why one scenario per PR, merged one at a time.** Small diffs are where review actually works and where test-gaming is easiest to spot; one scenario is the natural unit. Merging as you go keeps `main` releasable and puts finished work in git rather than in a long-lived branch or agent session — which is why there's no "one session per feature" rule to manage. The only session habit worth having: start fresh (or `/clear`) when you switch tasks or the context feels cluttered.
- **Why review is independent.** Whoever drove the agent accepted its approach in the moment and shares its blind spot. A check from outside that session is the only one that catches what they can't see.
- **Why the step-definition / test-fidelity gate exists.** An agent can make a scenario green with a step definition that asserts less than the scenario claims. Green then proves nothing. An independent fidelity check is the one habit that closes the gap Gherkin can't close on its own.
- **The rule of thumb behind rigid vs. soft.** A rule is rigid when a mistake lands on someone else and sticks (PR size, the gates). It's a soft habit when the cost is private and self-correcting (session hygiene). That's why the gates are non-negotiable and session boundaries are left to judgment.
