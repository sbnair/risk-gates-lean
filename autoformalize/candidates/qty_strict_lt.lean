-- rule: qty
-- kind: seeded mistake — strict < instead of ≤ at the upper limit
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide (0 < o.qty ∧ o.qty < l.maxOrderQty)
