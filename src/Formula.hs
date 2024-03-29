module Formula where

import qualified Data.Map as M

-- | Propositional formula
data Formula = Bot | Top
  | Var Int
  | Formula :& Formula
  | Formula :| Formula
  | Formula :> Formula
  deriving (Eq, Ord)
infixl 8 :&
infixl 7 :|
infixr 6 :>

-- | Negation of formula
neg :: Formula -> Formula
neg a = a :> Bot

-- | Bi-implication of two formulae
(<:>) :: Formula -> Formula -> Formula
(<:>) a b = (a :> b) :& (b :> a)
infix 5 <:>

-- | Typeclass for getting fresh variables
class Fresh a where
  fresh :: a -> Formula

-- | Fresh instance for Formula
instance Fresh Formula where
  fresh Bot = Var 0
  fresh Top = Var 0
  fresh (Var p) = Var (p + 1)
  fresh (a :& b) = max (fresh a) (fresh b)
  fresh (a :| b) = max (fresh a) (fresh b)
  fresh (a :> b) = max (fresh a) (fresh b)

-- | Simplify formula without substitution
simply :: Formula -> Formula
simply = fullSubsti M.empty

-- | Simplify and fully apply substitution map
fullSubsti :: M.Map Int Formula -> Formula -> Formula
fullSubsti = substi True

-- | Simplify and (partially) apply singlton substitution map
unitSubsti :: Bool -> (Int, Formula) -> Formula -> Formula
unitSubsti t (p, a) = substi t (M.singleton p a)

-- | Apply boolean simplification rules
-- and (partially) apply a substitution map
substi :: Bool -> M.Map Int Formula -> Formula -> Formula
substi _ m (Var p) | Just a <- m M.!? p = a
substi t m (a1 :& b1)
  | a == b || b == Top = a
  | a == Top = b
  | a == Bot || b == Bot = Bot
  | otherwise = a :& b
  where a = substi t m a1; b = substi t m b1
substi t m (a1 :| b1)
  | a == b || b == Bot = a
  | a == Bot = b
  | a == Top || b == Top = Top
  | otherwise = a :| b
  where a = substi t m a1; b = substi t m b1
substi True m (a1 :> b1)
  | a == b || b == Top || a == Bot = Top
  | a == Top = b
  | otherwise = a :> b
  where a = fullSubsti m a1; b = fullSubsti m b1
substi _ _ a = a

-- | Show instance for Formula
instance Show Formula where
  showsPrec _ Bot = showChar '⊥'
  showsPrec _ Top = showChar '⊤'
  showsPrec _ (Var p) = showString (show p)
  showsPrec p (a :& b) = showParen (p > 8) $
    showsPrec 8 a . showString " ∧ " . showsPrec 8 b
  showsPrec p (a :| b) = showParen (p > 7) $
    showsPrec 7 a . showString " ∨ " . showsPrec 7 b
  showsPrec _ (a :> Bot) = showChar '¬' . showsPrec 9 a
  showsPrec p (a :> b) = showParen (p > 6) $
    showsPrec 7 a . showString " → " . showsPrec 6 b
