-- rule: priceBand
-- kind: correct, written differently (absolute value)
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide (((o.price : Int) - l.refPrice).natAbs * 10000 ≤ l.bandBps * l.refPrice)
