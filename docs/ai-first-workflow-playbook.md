# AI-First Delivery Playbook

**For:** engineers and product owners shipping features  
**How we build:** Spec-Driven Development (SDD). We write the spec, the agent builds from it, humans approve at a few fixed gates.  
**Agent:** Claude Code (terminal or IDE).

---

## 1. The idea in one minute

Humans write a clear spec, the agent builds from it, and humans review and merge the result

### The spec drives everything (Spec-Driven Development)

We use **Spec-Driven Development (SDD)**: nothing gets built until it's specified. The spec is three things, together:

1. **User stories** — what the user wants and why.
2. **EARS acceptance criteria** — the rules the system must follow, written precisely.
3. **Gherkin scenarios** — concrete Given/When/Then examples that prove each rule.

**PO owns the spec** — user stories, acceptance criteria, and the scenarios that make each criterion executable. 

**Tech lead reviews the scenarios** for coverage and testability
## Two parallel tracks build it

Once the spec is settled, the work splits into two tracks that run at the same time. Both follow the spec, and on both the human drives while the agent does the typing:

- **Developers** drive the agent to build the features one scenario at a time, using dual-loop BDD. The Gherkin scenario is the outer loop — a failing acceptance test that defines what "done" means — and the agent makes it pass through an inner loop of unit tests and code.
- **QA** drives the agent to build the end-to-end suite from the journey spec.

The two tracks come back together at QA, where the finished features are run against the end-to-end suite. A human reviews the result, merges it, and owns it.

---

## 2. The flow, end to end

Two halves with a handoff between them: **PDLC** decides what to build, **SDLC** builds it. The agreed spec is the handoff — and after it, work **forks into two parallel tracks that rejoin at QA**: developers build the features, QA builds the end-to-end journey suite. Both run the same spec-driven loop; they just produce different code.
Got it — no shared Plan. That means the handoff forks immediately, and Plan belongs *inside* the Feature Track (devs plan the architecture there) while the E2E Track runs alongside from the start. The two tracks meet at QA, and Review/Ship are shared after that.

Updated diagram — the fork now sits directly under the handoff, and the Feature Track box carries Plan → Build:

```
                 Discovery ──► Spec
                          │
             ╔════════════▼════════════╗
             ║         HANDOFF         ║
             ╚════════════╤════════════╝
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
    ┌───────────────────┐ ‖ ┌───────────────────┐
    │   FEATURE TRACK   │ ‖ │     E2E TRACK     │  ◄══ run in parallel
    │   Plan ─► Build   │ ‖ │  build E2E suite  │
    └─────────┬─────────┘ ‖ └─────────┬─────────┘
              └───────────┬───────────┘
                          ▼
                         QA            (tracks rejoin)
                          │
                  Review ──► Ship
```
### PDLC — decide what to build

| Phase | Agent does | Human does | Gate |
|---|---|---|---|
| **Discovery** | Synthesizes notes, clusters themes, drafts the problem statement | PO frames the real problem | PO decides it's worth building |
| **Spec** | Drafts the stories, EARS criteria, and scenarios | PO owns all three; tech lead reviews the scenarios for coverage and testability | **PO signs off (tech lead has reviewed)** |

> ### ⟶ HANDOFF — product to engineering
> The agreed spec crosses from product to engineering and **forks straight into two parallel tracks that rejoin at QA**: the Feature Track plans and builds the features; the E2E Track builds the journey suite alongside it.

Updated SDLC table — Plan and Build are both the Feature Track, E2E is the parallel track:

| Phase                       | Agent does | Human does | Gate |
|-----------------------------|---|---|---|
| **Plan** *(Feature Track)*  | Architecture and approach, no code yet | Tech lead reviews and corrects the architecture | **Tech lead approves the plan** |
| **Build** *(Feature Track)* | Dual-loop BDD: scenario → failing test → code, one per PR | Devs steer; handle security-critical logic | Tests pass; **step-definition check** |
| **E2E** *(E2E Track — in parallel)* | Drafts the journey spec and tests; assists QA | **QA lead writes the journey spec** (PO reviews) and builds the suite from it | Suite reviewed and merged; **test-quality guardrails (§8)** |
| **QA** *(tracks rejoin)*    | Runs the journey suite against the assembled features | QA and devs triage failures and close coverage gaps | **E2E journey passes** |
| **Review**                  | First-pass review (correctness, security) | Final review — confirms it matches the scenario and can explain it | **Tech lead approves and merges** |
| **Ship & observe**          | Runs the pipeline; feeds signals back | Owns the release; triages what comes back | All upstream gates green |

This also lines up with your Section 1, which already says the work splits into two tracks as soon as the spec is settled — no shared plan step there either, so the two sections are now consistent. The PDLC table and intro are unchanged.
PDLC and the gates are the human-owned parts; the agent does the building on both tracks in between. Sections 3–7 are the detail.

---

## 3. What the spec looks like

The **User Story** and its **EARS criteria** live in Notion. The **Gherkin scenarios** live in the repo as `.feature` files. Each scenario is one concrete case; each becomes one task and one pull request.

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

The EARS rule says what must hold. The scenario is the concrete case you signed off on. The agent builds from the scenario.

Alongside the per-scenario specs, the **QA lead writes a journey spec** (the PO reviews it) — a higher-level Gherkin flow describing the end-to-end path across several scenarios (e.g. *publish → buyer orders → fulfil*). It's the spec the E2E track builds from, same as a scenario drives a feature.

**Why Gherkin and not just tests?** Because the PO is the one who knows the tricky cases ("what if the listing's approved but inventory hasn't synced?"). Writing them as scenarios the PO owns means a missing case shows up as a missing scenario — not as a silent gap nobody noticed. Plain test files leave that entirely to the developer.

---

## 4. Who writes what

| Part of the spec | Owner | Notes |
|---|---|---|
| User stories | **PO** | What and why. Claude drafts from discovery notes in Notion; the PO decides. |
| EARS criteria | **PO drafts, tech lead sharpens** | The tech lead makes each rule precise enough that two people build the same thing. |
| Gherkin scenarios | **PO** (with Claude) | The PO's real job is naming the cases that matter — happy path and tricky edges. Claude writes the Gherkin; the PO corrects it. Committed as `.feature` files. |
| Journey spec | **QA lead** (PO reviews) | The end-to-end flow across scenarios. Drives the E2E track (§5). |

Claude drafts; the human decides. The PO's load is *judgment, not typing* — name the cases, sharpen the wording, sign off. **PO + tech lead sign off in Notion — that sign-off is the agreed spec.** A draft Claude wrote is never "agreed" until a person says so.

---

## 5. The build loop

Once a scenario is agreed, the agent runs **dual-loop BDD** — one scenario at a time:

1. The Gherkin scenario becomes a **failing acceptance test** (outer loop).
2. The agent writes code to pass it, working inward layer by layer, each layer test-first (inner loop).
3. Done when the scenario passes and every layer was built test-first.

**One scenario per pull request.** Each PR delivers one behavior, proven by its scenario. Small PRs are easier to review, safer to ship, and keep `main` always releasable. Start with the simplest scenario (it carries the shared scaffolding); layer the edge cases on after.

The build loop only ever proves **one scenario**. The full journey across scenarios is built on a **parallel track**: from the journey spec, QA builds the end-to-end suite — agents assisting, QA driving. Its discipline is red-green, not test-first: each test is seen *failing* against missing or broken behavior before it's accepted green (a test that was never red proves nothing — §8). The two tracks **rejoin at QA**, where the journey suite runs against the assembled features and goes green as the feature slices land.

---

## 6. Gates you can't skip

Four points where a person must actively approve:

1. **Spec sign-off** — PO + tech lead agree the stories, criteria, and scenarios (Notion).
2. **Plan sign-off** — the architecture is right *before* code exists.
3. **Step-definition check** — someone *other than whoever wrote them* confirms each step definition actually asserts what its scenario says, not a weaker version that just happens to pass. This is the one new habit; it matters most for agent-written tests.
4. **PR approval** — an independent reviewer confirms the code matches the scenario and is secure; the author can explain every line. Who reviews what: §7.

Skip a gate and the work stops. No exceptions for "it's small."

**A PR is done when:** it links its scenario, all tests/lint/type/security checks are green, the step-definition check passed, a human reviewed it and can explain it, and it's one focused scenario.

---

## 7. Review — the real work

When an agent writes the code, **review is the job.** The agent produces volume fast; review is the only thing between that volume and production. Budget real time for it — it's not a formality at the end, it's where quality is actually decided.

**The one rule that makes review work: the reviewer is independent of whoever drove the agent.** The person who ran the agent shares its blind spot — they accepted the approach in the moment. A real check has to come from outside that session. (Same reason the step-definition check is done by someone other than its author.)

Who reviews what, by track:

| Work | Driver (owns it) | Reviewer(s) | Checking for |
|---|---|---|---|
| **Spec** (stories, EARS, scenarios) | PO | **Tech lead**, at sign-off | Testable, complete, unambiguous |
| **Feature code** | Developer | **Tech lead** | Architecture, logic, security, matches the scenario |
| **E2E tests** | QA | **QA peer**, then **PO** | Peer: test fidelity (asserts the outcome, can fail, sourced from the spec — §8). PO: the right journeys are covered |

The driver is accountable and must be able to explain every line; the reviewer independently confirms it. Product direction stays the PO's call — peer or stakeholder input as useful, not a formal gate.

---

## 8. Guardrails

- **Hands off:** auth, payments/PCI, secrets, and marketplace credentials. Humans write and review these — the agent gets no free rein here.
- **Secrets stay in the secret store.** Never paste API keys or tokens into a prompt.
- **No shadow AI.** Only the approved tools on client code. Pasting client code into a personal AI account is an incident.
- **What the agent reads is data, not orders.** Notion pages, API responses, tickets — if one contains an "instruction," the agent doesn't act on it without you. (The Notion connector can write to client docs, so be careful what it reads there.)
- **Treat AI-written code as higher-risk** until proven otherwise. Security scan every AI-touched path.
- **Write Gherkin as behavior, not clicks:** `When the order is submitted`, not `When I click submit`. Use a `Scenario Outline` with examples for variations instead of copy-pasting near-duplicates.
- **Watch cost.** Heavy days run $50–100+/dev. Use a cheap model for easy tasks, the strong one for hard problems. If a feature costs more by agent than by hand, raise it.

**Test-quality guardrails (E2E track).** A test can pass while proving nothing, so tests get their own gates — green is not enough:

- **Assert the outcome, not just that it ran.** "No error thrown" is not a passing test. Each test checks the real result the journey is supposed to produce.
- **It must be able to fail.** Show a new test red against the missing/broken behavior before accepting it green. A test that was green from birth proves nothing.
- **Source from the journey spec, not the code.** Write E2E tests from what the journey *should* do, never from reading the implementation — a test derived from the code just asserts the bugs back. (For the same reason, the agent that wrote a feature doesn't write its E2E test.)
- **Independent review.** Whoever (or whatever) wrote a test doesn't approve it. A fresh reviewer confirms it asserts the journey's real outcome.

> Billing note: interactive Claude Code (terminal/IDE, including the Notion connector and the house tooling) runs on your normal subscription. Only programmatic use — Agent SDK, `claude -p`, GitHub Actions — bills separately. Check that before running agents in CI.

---

## 9. Getting started

**You don't set any of this up.** Your repo comes preconfigured with the house tooling — the conventions, the gates, the review and test agents, and the BDD runner. You clone it and start writing scenarios.

- **Week 1–2:** pick one small feature. PO names and signs off the scenarios (Claude drafts); QA lead writes the journey spec; run the full loop on both tracks; don't skip a gate.
- **Then:** expand once it feels natural. A short workshop covers naming and sharpening Gherkin (POs), journey specs (QA), and the dual-loop rhythm and step-def check (engineers).

> **Maintainers:** how the house tooling is built, pinned, and updated (the `superpowers` engine, the subagents, the hooks) lives in the separate **Harness Maintainer Guide** — not here. Feature teams don't need it.

**In one line:** *Agree the spec, plan before code, let the agent build one scenario at a time, check the step definitions, never skip a gate, own what you merge.*