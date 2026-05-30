---
name: house-review
description: Our house review layer — spec-alignment and prohibited-zone checks that sit ON TOP of superpowers' requesting-code-review skill. Invoke as part of /house-review-pr before opening a PR for human review.
---

superpowers' `requesting-code-review` skill already covers general code quality. Do NOT
repeat it. This skill adds only the two things that are specific to US:

1. **Spec alignment.** Read the linked spec/task. Does the diff implement EXACTLY that
   scenario — no more, no less? Flag anything built that wasn't asked for, and anything in
   the scenario that's missing. (One acceptance scenario per PR is the rule — if the diff
   covers more than one, recommend splitting it.)
2. **Prohibited zones.** Did the diff touch auth, payments/PCI, or secrets? If so, that
   code must be human-authored — flag it as a blocker, don't approve.
3. **Double-loop completeness.** Is there a failing-first integration/acceptance test for
   the scenario (outer loop) AND per-layer unit cycles (inner loop)? Flag if layers were
   implemented in one rush to make the outer test pass without their own inner tests.

Output a short verdict the human reviewer can act on: one-sentence description of what the
PR does, the spec/task it traces to, blockers, and the integration test that proves the
scenario. Do not open or merge the PR — produce the summary a human uses to decide.
