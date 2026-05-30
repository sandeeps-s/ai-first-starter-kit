# AI-First Starter Kit (reuse-first, superpowers-based)

The **house layer** for running the AI-First Delivery Playbook with Claude Code. The
workflow engine is **superpowers** (vendored + pinned); this kit adds only the decisions we
own. We own the *decisions*, we borrow the *mechanics*.

> New to the method? Read the playbook Sections 11 (from-scratch, to learn the mechanics)
> and 12 (this reuse-first path). Then read `ADOPTION.md` here.

## What's here

```
CLAUDE.md                          House layer: double-loop OUTER loop, prohibited zones,
                                   gates, conventions, DoD. Overrides skills where they differ.
ADOPTION.md                        The reuse model: vendor+pin, wrap-don't-fork, owner+cadence.
PROVENANCE.md                      Living table of every borrowed component (source/commit/why).
install/
  install-superpowers.sh           Pin + vendor superpowers as a submodule.
.claude/
  settings.json                    House gates as hooks: lint-on-write, block destructive, tests-before-done.
  agents/
    house-security-checker.md      Prohibited-zones + input-trust pass (NOT broad SAST — that's the CI action).
  skills/
    house-review/SKILL.md          Spec-alignment + one-scenario-per-PR, ON TOP of superpowers review.
    test-qa/SKILL.md               E2E + cross-scenario tests — the layer OUTSIDE the double loop.
    double-loop-tdd/SKILL.md       FALLBACK ONLY — default double-loop lives in CLAUDE.md.
specs/
  discount-codes/spec.md           Worked example: one feature, five scenarios = five PRs.
```

## What we deliberately DON'T ship (superpowers provides it)
Brainstorming→spec, planning, **inner TDD (red-green-refactor)**, subagent-driven execution,
general code review, root-cause debugging. Don't reinvent these.

## Spec-Driven Development: superpowers-native
This kit runs **SDD through superpowers' own skills** (brainstorming → spec → planning →
tasks), **not** a separate SDD tool. We are deliberately **not** using GitHub Spec Kit here.
The `specs/` folder holds the spec artifacts the superpowers loop produces. If you ever add
Spec Kit later, split responsibilities cleanly — **Spec Kit owns spec/plan/tasks,
superpowers owns implement/test/review** — and never run both planning engines at once.

## The daily loop (per feature)
1. **Brainstorm → spec** with superpowers; shape it as **one acceptance scenario per
   behavior** (see the discount-codes example).
2. **Plan** with superpowers — **human approves the plan before any code.**
3. **Tasks** — **one scenario per task** so each maps 1:1 to a PR.
4. **Implement** with **double-loop TDD** (CLAUDE.md): failing integration test (outer)
   → per-layer inner red-green-refactor (superpowers TDD skill).
5. **Review** — superpowers `requesting-code-review` + our `house-review` + the CI
   security action. Then a **human approves the PR**.
6. Merge. `main` stays releasable.
7. Once enough scenario PRs exist, run **`test-qa`** for the E2E journey + add human
   adversarial cases.

## Adopting it
Follow the one-time setup checklist in `ADOPTION.md`. Run the policy check FIRST, pin
superpowers, fill in the `<PLACEHOLDERS>` in `CLAUDE.md`, wire the gates, name a maintainer.
