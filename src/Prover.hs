module Prover (sprove, iprove, cprove) where

import Embed
import Formula
import Sequent

-- | Prove a classical theorem
cprove :: Formula -> Bool
cprove = iprove . neg . neg

-- | Prove a superintuitionistic theorem
sprove :: [Axiom] -> Formula -> Bool
sprove ax = iprove . embed ax

-- | Prove a intuitionistic theorem
iprove :: Formula -> Bool
iprove = prove . singleton . F . simply

-- | Check provability of the set
prove :: Sequent -> Bool
prove z | Just (e, x) <- view z = case e of
  -- Contradictory leaf
  (P0, T Bot) -> True; (P0, F Top) -> True
  -- Unary consequence rules
  (P0, T (a :& b)) -> prove (T a <| T b <| x)
  (P0, F (a :| b)) -> prove (F a <| F b <| x)
  (P0, T ((c :& d) :> b)) -> prove (T (c :> d :> b) <| x)
  (P0, T ((c :| d) :> b))
    | (p, y) <- freshVar x
    -> prove (T (c :> p) <| T (d :> p) <| T (p :> b) <| y)
  -- Replacement rules
  (P1, T (Var p)) -> prove (mapSubsti True p Top x)
  (P1, F (Var p)) -> prove (e <+ mapSubsti False p Bot x)
  (P1, T (Var p :> Bot)) -> prove (mapSubsti True p Bot x)
  -- Right implication
  (P2, F (a :> b)) | prove (T a <| F b <| delFs x) -> True
  -- Right conjunction
  (P3, F (a :& b)) -> all prove [F a <| x, F b <| x]
  -- Left disjunction
  (P3, T (a :| b)) -> all prove [T a <| x, T b <| x]
  -- Left implication
  (P4, T ((c :> d) :> b))
    | (p, y) <- freshVar x
    , prove (T c <| T (d :> p) <| T (p :> b) <| F p <| delFs y)
    -> prove (T b <| y)
  -- Update priority
  a -> prove (a <+ x)
  -- Search exhausted
  | otherwise = False
