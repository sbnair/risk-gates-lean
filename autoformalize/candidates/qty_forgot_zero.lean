-- rule: qty
-- kind: seeded mistake — forgot "at least 1"
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide (o.qty ≤ l.maxOrderQty)
