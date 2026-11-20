import RiskGates.Gates

/-!
# What we can prove about the gates

1. `check_accept_iff`  : accept ⇔ all seven gates hold (soundness + completeness).
2. `kill_switch_blocks`: kill switch on ⇒ every order is rejected, whatever it is.
3. `accept_position_bound` : an accepted order can never push the position past the limit,
   even if it fully fills.
4. `accept_preserves_limits` : if the account is inside its limits and we accept an order,
   it is still inside its limits right after acceptance AND after the fill.
5. `reducing_order_passes_position` : an order that only reduces exposure is never blocked
   by the position gate (important: risk systems must not block you from getting out).
-/

namespace RiskGates

theorem check_accept_iff (l : Limits) (s : State) (o : Order) :
    check l s o = .accept ↔ allOk l s o := by
  unfold check allOk
  by_cases h1 : killOk s <;> by_cases h2 : qtyOk l o <;> by_cases h3 : notionalOk l o <;>
    by_cases h4 : priceBandOk l o <;> by_cases h5 : positionOk l s o <;>
    by_cases h6 : openOrdersOk l s <;> by_cases h7 : creditOk l s o <;>
    simp_all

theorem kill_switch_blocks (l : Limits) (s : State) (o : Order) (h : s.killSwitch = true) :
    check l s o = .reject .killSwitch := by
  simp [check, killOk, h]

theorem accept_position_bound (l : Limits) (s : State) (o : Order)
    (h : check l s o = .accept) :
    -(l.maxPosition : Int) ≤ (applyFill s o).position ∧
    (applyFill s o).position ≤ l.maxPosition := by
  have hall := (check_accept_iff l s o).mp h
  exact hall.2.2.2.2.1

theorem accept_preserves_limits (l : Limits) (s : State) (o : Order)
    (hs : withinLimits l s) (h : check l s o = .accept) :
    withinLimits l (applyAccept s o) ∧ withinLimits l (applyFill s o) := by
  have ⟨_, _, _, _, ⟨hp1, hp2⟩, hopen, hcred⟩ := (check_accept_iff l s o).mp h
  obtain ⟨hs1, hs2, hs3, hs4⟩ := hs
  unfold openOrdersOk at hopen
  unfold creditOk at hcred
  cases hside : o.side with
  | buy =>
    have hc := hcred hside
    simp only [withinLimits, applyAccept, applyFill, hside]
    exact ⟨⟨hs1, hs2, by omega, hc⟩, ⟨hp1, hp2, hs3, hc⟩⟩
  | sell =>
    simp only [withinLimits, applyAccept, applyFill, hside]
    exact ⟨⟨hs1, hs2, by omega, hs4⟩, ⟨hp1, hp2, hs3, hs4⟩⟩

/-- An order is *reducing* if it trades against the current position
and is no bigger than it (it can bring the position to zero, not flip it). -/
def reducing (s : State) (o : Order) : Prop :=
  match o.side with
  | .sell => 0 ≤ s.position ∧ (o.qty : Int) ≤ s.position
  | .buy  => s.position ≤ 0 ∧ (o.qty : Int) ≤ -s.position

theorem reducing_order_passes_position (l : Limits) (s : State) (o : Order)
    (hs : -(l.maxPosition : Int) ≤ s.position ∧ s.position ≤ l.maxPosition)
    (hr : reducing s o) :
    positionOk l s o := by
  unfold positionOk Order.signedQty
  unfold reducing at hr
  cases hside : o.side <;> simp only [hside] at hr ⊢ <;> omega

end RiskGates
