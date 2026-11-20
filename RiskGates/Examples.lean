import RiskGates.Gates

/-!
# Examples you can run (`#eval`) and examples Lean checks at compile time (`example ... := by decide`)

Setup: a stock trading around ₹2,500. 1 tick = ₹0.05, so ₹2,500 = 50,000 ticks.
-/

namespace RiskGates.Examples
open RiskGates

def limits : Limits :=
  { maxOrderQty   := 500
    maxNotional   := 500 * 52500      -- about ₹13 lakh per order
    refPrice      := 50000            -- ₹2,500
    bandBps       := 500              -- ±5%
    maxPosition   := 1000
    maxOpenOrders := 20
    creditLimit   := 1500 * 50000 }

def flat : State := { position := 0, openOrders := 3, usedCredit := 0, killSwitch := false }

-- A normal order
#eval check limits flat { side := .buy, qty := 100, price := 50100 }      -- accept

-- Fat finger on quantity: typed 5000 instead of 500
#eval check limits flat { side := .buy, qty := 5000, price := 50000 }     -- reject badQty

-- Fat finger on price: ₹25,000 instead of ₹2,500
#eval check limits flat { side := .buy, qty := 10, price := 500000 }      -- reject priceBand

-- Sell far below market (would cross the whole book)
#eval check limits flat { side := .sell, qty := 10, price := 40000 }      -- reject priceBand

-- Already long 900, buying 200 more would make 1100 > 1000
#eval check limits { flat with position := 900 } { side := .buy, qty := 200, price := 50000 }

-- Same account, selling 200 is fine (it reduces risk)
#eval check limits { flat with position := 900 } { side := .sell, qty := 200, price := 50000 }

-- Kill switch on: nothing goes out
#eval check limits { flat with killSwitch := true } { side := .buy, qty := 1, price := 50000 }

-- These are not just printed: Lean evaluates them while compiling and fails the build if wrong.
example : check limits flat { side := .buy, qty := 100, price := 50100 } = .accept := by decide
example : check limits flat { side := .buy, qty := 5000, price := 50000 } = .reject .badQty := by decide
example : check limits flat { side := .buy, qty := 10, price := 500000 } = .reject .priceBand := by decide
example : check limits { flat with position := 900 } { side := .buy, qty := 200, price := 50000 }
    = .reject .position := by decide
example : check limits { flat with killSwitch := true } { side := .buy, qty := 1, price := 50000 }
    = .reject .killSwitch := by decide

-- Boundary: exactly +5% is allowed, one tick more is not.
example : check limits flat { side := .buy, qty := 10, price := 52500 } = .accept := by decide
example : check limits flat { side := .buy, qty := 10, price := 52501 } = .reject .priceBand := by decide

end RiskGates.Examples
