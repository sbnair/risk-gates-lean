# Pre-trade risk rules (plain English, as a risk desk would write them)

These are the only inputs given to the LLM. Units: prices in ticks, quantity in shares,
money in ticks x shares. Basis point (bp) = 1/10000.

| id | rule |
|----|------|
| killSwitch | If the kill switch is on, no order may be sent. |
| qty | The order quantity must be at least 1 and must not exceed the maximum order quantity. |
| notional | The order value (quantity times price) must not exceed the maximum notional. |
| priceBand | The limit price must be within bandBps basis points of the reference price, on either side. Being exactly on the edge is allowed. |
| position | If the order fills completely, the resulting position (long or short) must stay within the maximum position. Buys increase the position, sells decrease it. |
| openOrders | We may have at most maxOpenOrders live orders at any time, including this new one. |
| credit | For buy orders, credit already used plus this order's value must not exceed the credit limit. Sell orders do not use credit. |
