---
name: test-qa
description: Our Test/QA layer — the tests that sit OUTSIDE the per-task double loop. Invoke once enough scenario PRs exist to test the full journey. Complements superpowers' inner TDD; does not duplicate it.
---

The per-task double loop (outer integration test + inner unit cycles) is already done by
the time you run, via CLAUDE.md's TDD shape and superpowers' TDD skill. Do NOT rewrite
those. Your job is the coverage they can't reach:

1. **End-to-end / system tests** — the full user journey across several scenarios in one
   path (e.g. browse → add to cart → apply discount → checkout), hitting real integration
   points.
2. **Cross-scenario edge cases** — failures that only emerge when behaviors combine
   (e.g. an expired discount on a cart that's also at a quantity limit).
3. **Failure-mode tests** — dependency timeouts, duplicate webhooks, out-of-order events,
   partial failures. Confirm the system fails safely rather than corrupting state.

Read existing tests first so you don't repeat unit/integration coverage. Use the project's
E2E framework (see CLAUDE.md). Each test must assert a specific, meaningful outcome — no
smoke tests that only check "it didn't throw." End with a note listing what you added and
where a human should add adversarial cases.
