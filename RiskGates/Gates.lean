import RiskGates.Types

/-!
# The seven gates

Each gate is written twice:
* as a `Prop` (`...Ok`) — the *specification*, what a human means;
* the `check` function then just tests them one by one with `decide`.

Because `check` is built directly from the specs, the soundness theorems in
`Proofs.lean` are short. The interesting part is that the theorems also cover
things the spec never said explicitly (position after fill, risk-reducing orders, ...).
-/

namespace RiskGates

/-- Gate 1: kill switch is off. -/
def killOk (s : State) : Prop := s.killSwitch = false

/-- Gate 2: quantity is positive and not above the single-order limit. -/
def qtyOk (l : Limits) (o : Order) : Prop := 0 < o.qty ∧ o.qty ≤ l.maxOrderQty

/-- Gate 3: order value (qty × price) not above the notional limit. -/
def notionalOk (l : Limits) (o : Order) : Prop := o.qty * o.price ≤ l.maxNotional

/-- Gate 4: fat-finger price band.
`|price - refPrice| ≤ refPrice × bandBps / 10000`, written without division
so there is no truncation: `|price - ref| × 10000 ≤ bandBps × ref`. -/
def priceBandOk (l : Limits) (o : Order) : Prop :=
  (o.price : Int) * 10000 ≤ (l.refPrice : Int) * 10000 + (l.bandBps : Int) * l.refPrice ∧
  (l.refPrice : Int) * 10000 ≤ (o.price : Int) * 10000 + (l.bandBps : Int) * l.refPrice

/-- Gate 5: worst case position, if the order fully fills, stays inside ±maxPosition. -/
def positionOk (l : Limits) (s : State) (o : Order) : Prop :=
  -(l.maxPosition : Int) ≤ s.position + o.signedQty ∧ s.position + o.signedQty ≤ l.maxPosition

/-- Gate 6: there is room for one more live order. -/
def openOrdersOk (l : Limits) (s : State) : Prop := s.openOrders < l.maxOpenOrders

/-- Gate 7: buy orders must fit in remaining credit. Sells do not use credit
(simplification: we assume short-selling margin is handled elsewhere). -/
def creditOk (l : Limits) (s : State) (o : Order) : Prop :=
  o.side = .buy → s.usedCredit + o.qty * o.price ≤ l.creditLimit

instance (s : State) : Decidable (killOk s) := by unfold killOk; infer_instance
instance (l : Limits) (o : Order) : Decidable (qtyOk l o) := by unfold qtyOk; infer_instance
instance (l : Limits) (o : Order) : Decidable (notionalOk l o) := by unfold notionalOk; infer_instance
instance (l : Limits) (o : Order) : Decidable (priceBandOk l o) := by unfold priceBandOk; infer_instance
instance (l : Limits) (s : State) (o : Order) : Decidable (positionOk l s o) := by
  unfold positionOk; infer_instance
instance (l : Limits) (s : State) : Decidable (openOrdersOk l s) := by unfold openOrdersOk; infer_instance
instance (l : Limits) (s : State) (o : Order) : Decidable (creditOk l s o) := by
  unfold creditOk; infer_instance

/-- The pre-trade check. First failing gate wins. -/
def check (l : Limits) (s : State) (o : Order) : Decision :=
  if ¬ killOk s then .reject .killSwitch
  else if ¬ qtyOk l o then .reject .badQty
  else if ¬ notionalOk l o then .reject .notional
  else if ¬ priceBandOk l o then .reject .priceBand
  else if ¬ positionOk l s o then .reject .position
  else if ¬ openOrdersOk l s then .reject .openOrders
  else if ¬ creditOk l s o then .reject .credit
  else .accept

/-- All seven gates together, as one proposition. -/
def allOk (l : Limits) (s : State) (o : Order) : Prop :=
  killOk s ∧ qtyOk l o ∧ notionalOk l o ∧ priceBandOk l o ∧
  positionOk l s o ∧ openOrdersOk l s ∧ creditOk l s o

/-- What the state looks like if the order is accepted and fully filled.
(One order goes live, then fills: position moves, credit is consumed for buys,
and the open order count goes back to where it was.) -/
def applyFill (s : State) (o : Order) : State :=
  { s with
    position   := s.position + o.signedQty
    usedCredit := match o.side with
                  | .buy  => s.usedCredit + o.qty * o.price
                  | .sell => s.usedCredit }

/-- What the state looks like right after the order is accepted (still live). -/
def applyAccept (s : State) (o : Order) : State :=
  { s with
    openOrders := s.openOrders + 1
    usedCredit := match o.side with
                  | .buy  => s.usedCredit + o.qty * o.price
                  | .sell => s.usedCredit }

/-- "The account is inside its limits." -/
def withinLimits (l : Limits) (s : State) : Prop :=
  -(l.maxPosition : Int) ≤ s.position ∧ s.position ≤ l.maxPosition ∧
  s.openOrders ≤ l.maxOpenOrders ∧ s.usedCredit ≤ l.creditLimit

end RiskGates
