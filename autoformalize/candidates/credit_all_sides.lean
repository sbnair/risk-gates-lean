-- rule: credit
-- kind: seeded mistake — applies credit check to sells too
def gate (l : Limits) (s : State) (o : Order) : Bool :=
  decide (s.usedCredit + o.qty * o.price ≤ l.creditLimit)
