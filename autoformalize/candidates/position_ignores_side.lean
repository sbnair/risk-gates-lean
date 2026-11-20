-- rule: position
-- kind: seeded mistake — always adds qty, ignores side
def gate (l : Limits) (s : State) (o : Order) : Bool :=
  decide ((s.position + o.qty).natAbs ≤ l.maxPosition)
