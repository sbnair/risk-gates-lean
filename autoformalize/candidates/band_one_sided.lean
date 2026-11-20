-- rule: priceBand
-- kind: seeded mistake — only checks the upper side
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide ((o.price : Int) * 10000 ≤ (l.refPrice : Int) * 10000 + (l.bandBps : Int) * l.refPrice)
