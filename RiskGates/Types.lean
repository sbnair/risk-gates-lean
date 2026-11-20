/-!
# Pre-trade risk gates: basic types

Everything is in integers on purpose.
Prices are in *ticks* (e.g. 1 tick = 0.05 rupee), quantities are in lots/shares,
money is in ticks × shares. No `Float` anywhere: you cannot prove much about floats,
and you do not want rounding inside a risk check.
-/

namespace RiskGates

inductive Side where
  | buy
  | sell
  deriving Repr, DecidableEq, Inhabited

/-- One new order coming from the strategy, before it goes to the exchange. -/
structure Order where
  side  : Side
  qty   : Nat   -- shares / lots
  price : Nat   -- limit price in ticks
  deriving Repr, DecidableEq, Inhabited

/-- Static limits configured by the risk desk. -/
structure Limits where
  maxOrderQty   : Nat   -- largest single order
  maxNotional   : Nat   -- largest qty × price of a single order
  refPrice      : Nat   -- reference price (last trade / mid) in ticks
  bandBps       : Nat   -- allowed distance from refPrice, in basis points (1 bp = 0.01%)
  maxPosition   : Nat   -- absolute position limit (long or short)
  maxOpenOrders : Nat   -- how many live orders we allow at once
  creditLimit   : Nat   -- buying power for buy orders, in ticks × shares
  deriving Repr, Inhabited

/-- Live state of the account at the moment the order arrives. -/
structure State where
  position   : Int   -- + long, - short
  openOrders : Nat
  usedCredit : Nat   -- credit already used by live buy orders
  killSwitch : Bool  -- the big red button
  deriving Repr, Inhabited

/-- Signed quantity: buys add to position, sells reduce it. -/
def Order.signedQty (o : Order) : Int :=
  match o.side with
  | .buy  => (o.qty : Int)
  | .sell => -(o.qty : Int)

def Order.notional (o : Order) : Nat := o.qty * o.price

/-- Why an order was rejected. The gates run in this order. -/
inductive Reason where
  | killSwitch
  | badQty
  | notional
  | priceBand
  | position
  | openOrders
  | credit
  deriving Repr, DecidableEq

inductive Decision where
  | accept
  | reject (r : Reason)
  deriving Repr, DecidableEq

end RiskGates
