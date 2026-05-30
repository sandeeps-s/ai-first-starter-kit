# CLAUDE.md — Project Memory (house layer over superpowers)

> Claude Code reads this file at the start of every session. It is our **house layer**:
> the decisions we own (gates, prohibited zones, the outer TDD loop, client conventions).
> The *mechanics* (spec→plan→TDD→review) come from the vendored **superpowers** skills.
> Keep this short, explicit, current. When the agent repeatedly gets something wrong,
> fix it HERE. Treat it like production config.

## How we work: superpowers provides the engine, this file steers it
- The **superpowers** plugin is installed and supplies our workflow skills: brainstorming
  → spec, planning, **test-driven-development (inner red-green-refactor)**,
  subagent-driven-development, requesting-code-review, and root-cause debugging.
  Use them. Don't reinvent them in chat.
- **Where this file and a skill conflict, THIS FILE WINS.** Our instructions override
  default skill behavior (superpowers is explicit about deferring to the user).

## What this project is
<!-- One paragraph: what the system does and who it's for. -->
E-commerce integration layer connecting <CLIENT>'s storefront to their ERP/OMS and
payment provider. Exposes capabilities to AI shopping agents via MCP.

## Tech stack
- Language/runtime: <e.g. TypeScript 5.x / Node 20>
- Framework: <e.g. NestJS / Hydrogen>   | Architecture: <e.g. hexagonal / ports & adapters>
- Test: <e.g. Vitest (unit), Playwright (E2E)>
- Package manager: <e.g. pnpm>  — ALWAYS use this, never npm/yarn
- Lint/format: <e.g. ESLint + Prettier>; type check: <e.g. tsc --noEmit>

## How to run things (use these exact commands)
- Install: `pnpm install`
- Unit tests: `pnpm test`   | Integration: `pnpm test:integration`   | E2E: `pnpm test:e2e`
- Lint: `pnpm lint`   | Type check: `pnpm typecheck`   | Dev server: `pnpm dev`

## Development approach
Follow **BDD dual-loop TDD**. Every feature increment starts from a failing integration
test and is driven inward through unit-level red-green-refactor cycles.
### Outer loop (integration)
1. Red (integration) — Write one integration/acceptance test that describes the
   next observable behavior from the outside in. Run it. Confirm it fails for the
   reason you expect. Do not proceed until the failure message matches your intent.
2. Inner loop (unit) — repeat until the integration test can pass: superpowers' TDD 
   skill enforces the **inner** loop (Red → watch it fail → Green → Refactor).
3. Green (integration) — When enough unit-level pieces exist, re-run the
   integration test. If it still fails, diagnose which piece is missing and drop back
   into the inner loop. Do not add code without a failing test driving it.
4. Refactor (integration) — With the integration test green, refactor across
   module boundaries if needed. All tests — unit and integration — must stay green.
5. Repeat from step 1 with the next slice of behavior until the task is complete.

## Conventions — DO
- One acceptance scenario per task and per PR. Keep diffs small and reviewable.
- Use the repo's existing error-handling and logging patterns — match what's there.
- Validate and sanitize all external input (storefront, webhooks, third-party APIs).
- Co-locate unit tests with the code they cover.

## Conventions — DON'T
- Don't add a dependency without flagging it for human approval first.
- Don't edit generated files (anything under `*/generated/`).
- Don't disable lint/type rules to make a check pass — fix the cause.
- Don't write code in Plan Mode. Plan first, implement after approval.

## PROHIBITED ZONES (humans write & review these directly — agent gets NO autonomous access)
- Authentication / authorization logic
- Payment handling and any PCI-scoped code or data
- Secrets, API keys, credential handling
- If a task touches these, STOP and ask the human to take it.

## Domain glossary
- "Cart" = pre-checkout line items; "Order" = post-checkout, persisted.
- "OMS" = order management system (<vendor>); source of truth for fulfilment.
- <add client/domain-specific terms here>

## Definition of Done (every PR)
Traces to an approved spec/task · double-loop complete (every layer via inner cycle + outer
integration test green) · all gates green (tests, lint, typecheck, SAST) · review run &
addressed · a human can explain every change · no prohibited-zone code added by the agent ·
small and focused.
