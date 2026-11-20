-- rule: position
-- kind: seeded mistake — checks current position, not position after fill
def gate (l : Limits) (s : State) (_o : Order) : Bool :=
  decide (s.position.natAbs ≤ l.maxPosition)
