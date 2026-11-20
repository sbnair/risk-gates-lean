#!/usr/bin/env python3
"""Ask an LLM to formalize each plain-English rule, then save the answers as candidates.

  export ANTHROPIC_API_KEY=...      # or OPENAI_API_KEY=... with --provider openai
  python3 autoformalize/generate.py --model claude-sonnet-5-5 --samples 5
  python3 autoformalize/check.py autoformalize/llm_runs/claude-sonnet-5-5

Each rule is asked `--samples` times, so you also see how *consistent* the model is.
The model only sees: the types (Types.lean) and the one-line English rule.
It never sees Gates.lean (the reference), and check.py rejects answers that call it.
"""
import argparse, json, os, pathlib, re, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
TYPES = (ROOT / "RiskGates" / "Types.lean").read_text()
RULES = {}
for line in (ROOT / "autoformalize" / "rules.md").read_text().splitlines():
    m = re.match(r"\|\s*(\w+)\s*\|\s*(.+?)\s*\|$", line)
    if m and m.group(1) not in ("id",):
        RULES[m.group(1)] = m.group(2)

PROMPT = """You are formalizing a pre-trade risk rule in Lean 4 (core Lean, no Mathlib).

Here are the types (namespace RiskGates is already open):

```lean
{types}
```

Units: prices are in ticks (Nat), quantity in shares (Nat), money in ticks x shares.
A basis point (bp) is 1/10000.

Rule ({rule_id}): "{rule_text}"

Write exactly one Lean definition with this signature and nothing else:

```lean
def gate (l : Limits) (s : State) (o : Order) : Bool := ...
```

It must return `true` exactly when the order passes this one rule.
Reply with only the Lean code block."""


def ask_anthropic(model, prompt):
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps({"model": model, "max_tokens": 800,
                         "messages": [{"role": "user", "content": prompt}]}).encode(),
        headers={"x-api-key": os.environ["ANTHROPIC_API_KEY"],
                 "anthropic-version": "2023-06-01", "content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)["content"][0]["text"]


def ask_openai(model, prompt):
    base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
    req = urllib.request.Request(
        base + "/chat/completions",
        data=json.dumps({"model": model,
                         "messages": [{"role": "user", "content": prompt}]}).encode(),
        headers={"Authorization": "Bearer " + os.environ["OPENAI_API_KEY"],
                 "content-type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)["choices"][0]["message"]["content"]


def extract_code(text):
    m = re.search(r"```(?:lean4?|)\n(.*?)```", text, re.S)
    return (m.group(1) if m else text).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", default="anthropic", choices=["anthropic", "openai"])
    ap.add_argument("--model", required=True)
    ap.add_argument("--samples", type=int, default=3)
    a = ap.parse_args()
    ask = ask_anthropic if a.provider == "anthropic" else ask_openai
    out = ROOT / "autoformalize" / "llm_runs" / a.model
    out.mkdir(parents=True, exist_ok=True)
    for rule_id, text in RULES.items():
        for i in range(a.samples):
            reply = ask(a.model, PROMPT.format(types=TYPES, rule_id=rule_id, rule_text=text))
            code = extract_code(reply)
            (out / f"{rule_id}_{i}.lean").write_text(
                f"-- rule: {rule_id}\n-- kind: {a.provider}/{a.model} sample {i}\n{code}\n")
            print("wrote", out / f"{rule_id}_{i}.lean")


if __name__ == "__main__":
    main()
