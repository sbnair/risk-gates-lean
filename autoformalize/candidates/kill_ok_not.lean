-- rule: killSwitch
-- kind: correct, written differently
def gate (_l : Limits) (s : State) (_o : Order) : Bool :=
  !s.killSwitch
