-- rule: priceBand
-- kind: seeded mistake — treats bps as percent (/100 instead of /10000)
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  decide ((o.price : Int) * 100 ≤ (l.refPrice : Int) * 100 + (l.bandBps : Int) * l.refPrice ∧
          (l.refPrice : Int) * 100 ≤ (o.price : Int) * 100 + (l.bandBps : Int) * l.refPrice)
