# ADOPTION — How we run the reuse-first model

This kit is the **house layer**. The workflow *engine* is **superpowers** (vendored, pinned).
We own the decisions; we borrow the mechanics. Three rules govern how we reuse.

## 1. Vendor, then pin
- Bring superpowers (and any community skill) in as a **pinned git submodule**, not loose
  copied files. See `install/install-superpowers.sh`.
- Pin to an exact tag/commit so an upstream change can't silently alter agent behavior
  mid-engagement. Upgrade deliberately, never automatically.
- The quick marketplace install (`/plugin install superpowers@claude-plugins-official`) is
  fine for spikes, but governed client work uses the pinned submodule.

## 2. Wrap, don't fork
- Leave superpowers' files untouched. Our house rules live ONLY in this kit:
  `CLAUDE.md`, the house skills/subagent, and the hooks.
- Our `CLAUDE.md` overrides skill behavior where they differ (superpowers defers to the
  user). That's how we add the double-loop OUTER loop without editing their TDD skill.
- If upstream updates, we bump the pin and re-test; our overrides are unaffected.

## 3. One owner, one cadence, full provenance
- A named maintainer reviews upstream updates on a fixed cadence (e.g. biweekly), tests
  against our repo, and bumps the pin. Everyone else consumes the known-good version.
- Every reused component gets a line in `PROVENANCE.md` (source, commit, why).

## What we own vs. what superpowers provides

| Concern | Source |
|---|---|
| **Spec-Driven Development (spec/plan/tasks loop)** | **superpowers (native) — NOT a separate SDD tool; no Spec Kit** |
| Brainstorm → spec, planning | superpowers |
| Inner TDD (red-green-refactor) | superpowers `test-driven-development` |
| Subagent-driven / parallel execution | superpowers |
| General code-quality review | superpowers `requesting-code-review` |
| Root-cause debugging | superpowers |
| **Double-loop OUTER loop** | **us — `CLAUDE.md` (fallback skill if needed)** |
| **Prohibited zones (auth/payments/secrets)** | **us — `CLAUDE.md` + `house-security-checker`** |
| **Spec-alignment + one-scenario-per-PR review** | **us — `house-review`** |
| **Test/QA layer (E2E + cross-scenario)** | **us — `test-qa`** |
| **The four gates (lint/type/test/SAST)** | **us — `.claude/settings.json` hooks + CI** |
| **Broad SAST in CI** | official `claude-code-security-review` action |
| **Client conventions, domain glossary** | **us — `CLAUDE.md`** |

## Policy check before you adopt (do this first)
- Confirm our Claude subscription tier permits the components we're adding. Skills,
  subagents, and hooks are first-class. Heavyweight third-party **agent frameworks** may be
  restricted on some tiers — superpowers is a skills library (fine), but verify against
  current Anthropic docs at adoption time.

## One-time setup checklist
- [ ] Run the policy check above.
- [ ] Pin and vendor superpowers (`install/install-superpowers.sh`), record in PROVENANCE.md.
- [ ] Copy `CLAUDE.md` to repo root; fill every `<PLACEHOLDER>`.
- [ ] Copy `.claude/` into the repo; adjust hook commands to our stack.
- [ ] Add the `claude-code-security-review` action as a required CI check.
- [ ] Install the Claude Code GitHub App for automated PR review.
- [ ] Configure MCP servers through the governed gateway (GitHub + client systems).
- [ ] Name the maintainer and set the upgrade cadence.
