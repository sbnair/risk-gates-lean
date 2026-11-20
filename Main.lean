import RiskGates

open RiskGates

/-- Small CLI: `riskcheck <side> <qty> <price> [position]`
Runs the verified `check` against the demo limits and prints the decision. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | sideS :: qtyS :: priceS :: rest =>
    let side? : Option Side := match sideS.toLower with
      | "buy" => some .buy | "sell" => some .sell | _ => none
    match side?, qtyS.toNat?, priceS.toNat? with
    | some side, some qty, some price =>
      let pos : Int := match rest with
        | p :: _ => p.toInt?.getD 0
        | [] => 0
      let s := { Examples.flat with position := pos }
      let d := check Examples.limits s { side, qty, price }
      IO.println s!"{repr d}"
      return (if d == .accept then 0 else 1)
    | _, _, _ =>
      IO.eprintln "bad arguments"; return 2
  | _ =>
    IO.eprintln "usage: riskcheck <buy|sell> <qty> <price_ticks> [position]"
    return 2
