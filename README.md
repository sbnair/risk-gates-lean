# risk-gates-lean

Pre-trade risk gates (kill switch, max qty, max notional, fat-finger price band,
position limit, open-order limit, credit) written and **proved** in Lean 4,
plus a harness that tests whether an LLM can turn the plain-English rules into correct Lean.

No Mathlib, no floats. Builds in a few seconds with Lean 4.36.0.

## Layout

| Path | What |
|---|---|
| `RiskGates/Types.lean` | Order, Limits, State, Decision (all integers: ticks, shares) |
| `RiskGates/Gates.lean` | the 7 gates as `Prop` specs + the `check` function |
| `RiskGates/Proofs.lean` | 5 theorems (see below) |
| `RiskGates/Examples.lean` | fat-finger scenarios, checked at build time with `decide` |
| `Main.lean` | `riskcheck` CLI running the verified `check` |
| `autoformalize/rules.md` | the rules in plain English (the only thing the LLM sees, plus the types) |
| `autoformalize/Harness.lean` | reference gates as `Bool`, counterexample search, `solve_gate` proof tactic |
| `autoformalize/check.py` | grades every candidate: EQUIVALENT / WRONG / UNKNOWN / REJECTED |
| `autoformalize/generate.py` | asks Claude or an OpenAI-compatible model to formalize each rule |
| `autoformalize/candidates/` | 14 hand-written candidates (6 correct variants, 8 classic mistakes) |

## Theorems

1. `check_accept_iff` — `check` accepts **iff** all seven gates hold.
2. `kill_switch_blocks` — kill switch on ⇒ every order is rejected.
3. `accept_position_bound` — an accepted order can never push the position past ±maxPosition, even fully filled.
4. `accept_preserves_limits` — inside limits + accepted ⇒ still inside limits after acceptance and after fill.
5. `reducing_order_passes_position` — an order that only reduces exposure is never blocked by the position gate.

`#print axioms` shows only Lean's standard axioms (`propext`, `Quot.sound`, `Classical.choice`). No `sorry`.

## Run it

```bash
# install Lean via elan (https://lean-lang.org/install), then:
lake build                                   # builds + checks every proof and example
./.lake/build/bin/riskcheck buy 10 500000    # -> reject priceBand (fat finger)
python3 autoformalize/check.py               # grade the 14 sample candidates

# LLM test
export ANTHROPIC_API_KEY=...                 # or OPENAI_API_KEY + --provider openai
python3 autoformalize/generate.py --model claude-sonnet-5-5 --samples 5
python3 autoformalize/check.py autoformalize/llm_runs/claude-sonnet-5-5
```

## How a candidate is graded

1. **Counterexample search** — 20,000 generated cases (edges, odd reference prices, ...). Any mismatch ⇒ `WRONG`, with the order/state/limits printed.
2. **Proof** — `∀ l s o, candidate l s o = reference l s o` via `simp` + `omega`. Proof passes and only standard axioms ⇒ `EQUIVALENT` (true for every input, not just the tested ones).
3. Neither ⇒ `UNKNOWN` (a human should look). Candidates that call the reference gates, or use `axiom`/`sorry`, are `REJECTED`.

## Sample result (hand-written candidates, not an LLM run)

| verdict | candidates |
|---|---|
| EQUIVALENT (6) | qty with `≥ 1 &&`, notional `price * qty`, band with `natAbs`, band with **Nat division**, credit with `match`, kill switch with `!` |
| WRONG (8) | `<` instead of `≤`, forgot qty ≥ 1, band one-sided, bps treated as percent, position ignores side, position checks current not post-fill, open orders `≤` vs `<`, credit applied to sells |

The surprise: the Nat-division price band (`ref * bps / 10000`) *looks* like a rounding bug, but Lean proves it is
exactly equivalent — for integer ticks, `d ≤ ⌊x / 10000⌋ ⇔ d × 10000 ≤ x`.

## Not covered (yet)

Self-trade prevention, rate limits / order throttles, cumulative daily loss, multiple symbols, partial fills,
cancel/replace. The model of state is one account, one instrument.
