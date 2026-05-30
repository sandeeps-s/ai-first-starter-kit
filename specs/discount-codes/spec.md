# Spec: Apply Discount Code to Cart

> The WHAT and WHY. No tech-stack/implementation here — those come from the plan
> (use superpowers' planning skill). Each acceptance scenario below becomes one task and
> one PR, built with our double-loop TDD shape (see CLAUDE.md).

## Why
Shoppers expect to enter promo codes at the cart. AI shopping agents (via MCP) also need
to apply codes programmatically. This lets a valid code reduce a cart total under clearly
defined rules, and rejects invalid uses safely.

## Scope
- In: applying a single percentage discount code to an existing cart; validation/rejection
  rules; surfacing the result to both the storefront UI and the MCP tool.
- Out: creating/managing codes (admin), fixed-amount codes, stacking beyond the conflict
  rule below, loyalty points. (Track separately.)

## Non-functional requirements
- All code input is validated and sanitized (untrusted: storefront + agent).
- Applying a code is idempotent — re-sending the same request doesn't double-apply.
- Response within <200ms p95 for a typical cart.

## Acceptance scenarios  (each → one task → one PR; happy path first)

### Scenario 1 — Valid code applies a percentage discount  *(carries shared scaffolding)*
- Given a cart subtotal of $100 and a valid active code "SAVE10" worth 10%
- When the code is applied
- Then the cart shows a $10 discount and a $90 total.

### Scenario 2 — Expired code is rejected
- Given a cart and a code whose validity window has passed
- When the code is applied
- Then no discount is applied and the cart shows an "expired code" reason; total unchanged.

### Scenario 3 — Code already used by this customer is rejected
- Given a single-use code this customer has already redeemed
- When the code is applied again
- Then it is rejected with an "already used" reason; total unchanged.

### Scenario 4 — Discount cannot exceed cart value
- Given a cart subtotal of $8 and a code worth a larger amount than the cart
- When the code is applied
- Then the discount is capped so the total is never below $0.

### Scenario 5 — Two conflicting codes resolve per business rule
- Given a cart with code A already applied and a conflicting code B
- When code B is applied
- Then the system keeps the higher-value discount and clearly states which code is active.

## Edge / failure cases for the Test/QA layer (outside the per-PR double loop)
- Empty/whitespace/oversized code input; injection attempts in the code field.
- Code applied to an empty cart.
- Discount service times out — cart must remain consistent.
- Same code applied via UI and MCP near-simultaneously (idempotency under concurrency).

## Done when
All five scenarios are merged as separate PRs, each with its outer integration test green
and per-layer inner cycles, plus the Test/QA layer (E2E journey + failure-mode tests) and
human adversarial review.
