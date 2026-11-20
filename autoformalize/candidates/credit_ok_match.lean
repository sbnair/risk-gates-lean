-- rule: credit
-- kind: correct, written differently (pattern match)
def gate (l : Limits) (s : State) (o : Order) : Bool :=
  match o.side with
  | .buy  => decide (s.usedCredit + o.qty * o.price ≤ l.creditLimit)
  | .sell => true
