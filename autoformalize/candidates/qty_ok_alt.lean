-- rule: qty
-- kind: correct, written differently
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  o.qty ≥ 1 && o.qty ≤ l.maxOrderQty
