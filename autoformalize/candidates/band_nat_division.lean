-- rule: priceBand
-- kind: looks suspicious (Nat division rounds down) — is it actually wrong?
def gate (l : Limits) (_s : State) (o : Order) : Bool :=
  let allowed := l.refPrice * l.bandBps / 10000
  decide (o.price ≤ l.refPrice + allowed ∧ l.refPrice ≤ o.price + allowed)
