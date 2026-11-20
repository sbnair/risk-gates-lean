#!/usr/bin/env python3
"""Check every candidate formalization against the reference gates.

For each autoformalize/candidates/*.lean file (header line `-- rule: <id>`):
  1. counterexample search (Lean #eval over 20,000 generated cases)
  2. proof attempt: forall l s o, cand l s o = ref l s o   (simp + omega)

Verdict:
  EQUIVALENT  - Lean proved it for ALL inputs
  WRONG       - a concrete counterexample was found
  UNKNOWN     - no counterexample, but the automatic proof did not go through

Usage:  python3 autoformalize/check.py [candidate_dir]
Needs `lake build` to have been run once (for the Harness library).
"""
import pathlib, re, subprocess, sys, tempfile, json

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAND_DIR = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "autoformalize" / "candidates"

# kept for reference; the proof recipe now lives in Harness.lean (solve_gate)
UNFOLD = ", ".join(["killOk", "qtyOk", "notionalOk", "priceBandOk", "positionOk", "openOrdersOk",
                    "creditOk", "Order.signedQty", "Order.notional", "Autoformalize.refGate"])

TEMPLATE = """import Harness
open RiskGates
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false

namespace Cand
{body}
end Cand

#eval Autoformalize.report "{name}" "{rule}" Cand.gate

theorem cand_equiv : ∀ l s o, Cand.gate l s o = Autoformalize.refGate "{rule}" l s o := by
  unfold Cand.gate
  solve_gate

#print axioms cand_equiv
"""


def check(path: pathlib.Path) -> dict:
    text = path.read_text()
    m = re.search(r"--\s*rule:\s*(\w+)", text)
    if not m:
        return {"name": path.stem, "verdict": "SKIPPED (no '-- rule:' header)"}
    rule = m.group(1)
    body = "\n".join(l for l in text.splitlines() if not l.strip().startswith("--"))
    banned = re.findall(r"\b(killOk|qtyOk|notionalOk|priceBandOk|positionOk|openOrdersOk|creditOk|"
                        r"allOk|check|refGate|axiom|sorry)\b", body)
    if banned:
        return {"name": path.stem, "rule": rule, "kind": "", "verdict": "REJECTED",
                "details": f"uses forbidden names: {sorted(set(banned))}"}
    kind = (re.search(r"--\s*kind:\s*(.*)", text) or [None, ""])[1]
    src = TEMPLATE.format(body=text, name=path.stem, rule=rule, unfold=UNFOLD)
    with tempfile.NamedTemporaryFile("w", suffix=".lean", dir=ROOT, delete=False) as f:
        f.write(src)
        tmp = pathlib.Path(f.name)
    try:
        out = subprocess.run(["lake", "env", "lean", str(tmp)], cwd=ROOT,
                             capture_output=True, text=True, timeout=600)
    finally:
        tmp.unlink(missing_ok=True)
    log = out.stdout + out.stderr
    cex = "COUNTEREXAMPLE" in log
    proof_failed = out.returncode != 0
    # a candidate must not cheat: no `sorry`, and only Lean's three standard axioms
    axioms = re.search(r"depends on axioms: \[(.*?)\]", log, re.S)
    extra = set()
    if axioms:
        extra = {a.strip() for a in axioms.group(1).split(",")} - {"propext", "Classical.choice", "Quot.sound"}
    cheated = "sorry" in log or bool(extra)
    if cex:
        verdict = "WRONG"
    elif not proof_failed and not cheated:
        verdict = "EQUIVALENT"
    else:
        verdict = "UNKNOWN"
    # does the candidate itself even type-check? (errors before line of #eval)
    first_err = re.search(r":(\d+):\d+: error", log)
    body_lines = src.split("#eval")[0].count("\n") + 1
    if first_err and int(first_err.group(1)) < body_lines:
        verdict = "DOES NOT COMPILE"
    cex_lines = [l for l in log.splitlines() if l.strip().startswith(("order", "state", "limits", "[" ))]
    return {"name": path.stem, "rule": rule, "kind": kind.strip(), "verdict": verdict,
            "details": "\n".join(cex_lines[:4])}


def main():
    results = [check(p) for p in sorted(CAND_DIR.glob("*.lean"))]
    w = max(len(r["name"]) for r in results)
    for r in results:
        print(f"{r['name']:<{w}}  {r.get('rule',''):<11} {r['verdict']:<16} {r.get('kind','')}")
    (ROOT / "autoformalize" / "results.json").write_text(json.dumps(results, indent=2))
    print("\nDetails (counterexamples) in autoformalize/results.json")


if __name__ == "__main__":
    main()
