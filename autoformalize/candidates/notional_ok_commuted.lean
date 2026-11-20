-- rule: notional
-- kind: correct, written differently (price * qty)
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide (o.price * o.qty ≤ l.maxNotional)
