-- rule: openOrders
-- kind: seeded mistake — ≤ instead of < (forgets the new order counts too)
def gate (l : Limits) (s : State) (_o : Order) : Bool :=
  decide (s.openOrders ≤ l.maxOpenOrders)
