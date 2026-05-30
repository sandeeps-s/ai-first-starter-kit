---
name: double-loop-tdd
description: FALLBACK ONLY. Do not enable by default. The double-loop shape lives in CLAUDE.md as an instruction layered over superpowers' TDD skill. Enable this skill only if that CLAUDE.md framing proves too weak in practice and the agent keeps skipping the outer loop or per-layer inner cycles.
---

> ⚠️ FALLBACK SKILL — read before enabling.
> Our default is to NOT have this skill. The outer (double) loop is specified in CLAUDE.md
> and wraps superpowers' rigid inner TDD skill. That keeps us in "wrap, don't fork" mode
> with zero extra maintenance. Enable this skill ONLY if, on the pilot, the CLAUDE.md
> instruction repeatedly fails to hold (agent jumps to implementing all layers to make the
> outer test green, skipping per-layer inner cycles). If you enable it, you now maintain it.

Outside-in (double-loop) TDD:

1. Write a failing **integration/acceptance test** at the outermost boundary (controller /
   adapter). Watch it fail. This is the outer loop; it stays red until the feature is done.
2. Work inward, one layer at a time (controller → service → domain → ports → adapters).
   For EACH layer, run the strict inner cycle: write a failing unit test → minimal code to
   pass → refactor. Defer to superpowers' `test-driven-development` skill for the inner
   mechanics.
3. Never implement a layer without its own failing inner test first.
4. Done only when every layer was built via its own inner cycle AND the outer integration
   test passes.
