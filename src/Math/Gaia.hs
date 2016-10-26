{-# LANGUAGE ConstraintKinds, NoImplicitPrelude, TypeFamilies, FlexibleContexts, MultiParamTypeClasses, ScopedTypeVariables, FlexibleInstances, LiberalTypeSynonyms #-}
{-# OPTIONS_GHC -O3 #-}
module Math.Gaia
  (
    Magma(..)
  , Idempotent(..)
  , Commutative(..)
  , Associative(..)
  , Unital(..)
  , Invertible(..)
  , Homomorphic(..)
  , Semigroup(..)
  , Monoid(..)
  , Group(..)
  , Abelian(..)
  , (<>)
  , (++)
  , empty
  , Distributive(..)
  , Semiring(..)
  , Ring(..)
  , Exponential(..)
  , Division(..)
  , Field(..)
  , IntegralDomain(..)
  , Decidable(..)
  , Ordered(..)
  , (+)
  , (*)
  , (-)
  , (/)
  , exp
  , POrdering(..)
  , POrd(..)
  , ord2pord
  , Topped(..)
  , Bottomed(..)
  , PBounded(..)
  , Semilattice(..)
  , Lattice(..)
  , Negated(..)
  , negate
  ) where

import Data.Coerce
import Prelude hiding ((+), (*), (-), (/), exp, negate, Monoid(..), (++))

-- | Grown out of the flames, the magma 
class Magma a where mul :: a -> a -> a
class Magma a => Idempotent a
class Magma a => Commutative a
class Magma a => Associative a
class Magma a => Unital a where unit :: a
class Magma a => Invertible a where inv :: a -> a
class (Magma a, Magma b) => Homomorphic a b where hom :: a -> b

instance Magma a => Homomorphic a a where hom a = a

type Semigroup a = Associative a
type Monoid a = (Unital a, Semigroup a)
type Group a = (Invertible a, Monoid a)
type Abelian c a = (Commutative a, c a)

(<>) :: Semigroup a => a -> a -> a
a <> b = a `mul` b

(++) :: Monoid a => a -> a -> a
a ++ b = a <> b

empty :: Monoid a => a
empty = unit

class (
    Coercible a (Add a)
  , Coercible a (Mul a)
  , Monoid (Mul a)
  , Monoid (Add a)
  ) => Distributive a where
  type Mul a
  type Add a
  one :: a
  one = coerce (unit :: Mul a)
  zero :: a
  zero = coerce (unit :: Add a)

type Semiring a = (Distributive a, Commutative (Add a))
type Exponential a = (Semiring a, Homomorphic (Add a) (Mul a))
type Logarithmic a = (Semiring a, Homomorphic (Mul a) (Add a))
type Ring a = (Semiring a, Group (Add a))
type Division a = (Ring a, Group (Mul a))
type Field a = (Division a, Commutative (Mul a))
type Ordered c a = (Ord a, c a)
type POrdered c a = (POrd a, c a)
type Decidable c a = (Eq a, c a)
class Distributive a => IntegralDomain a where
  div :: a -> a -> a
  mod :: a -> a -> a

infixr 7 *
(*) :: Distributive a => a -> a -> a
(x :: a) * y = coerce ((coerce x `mul` coerce y) :: Mul a) :: a

infixr 6 +
(+) :: Distributive a => a -> a -> a
(x :: a) + y = coerce ((coerce x `mul` coerce y) :: Add a) :: a

infixr 6 -
(-) :: Ring a => a -> a -> a
(x :: a) - y = coerce ((coerce x `mul` inv (coerce y)) :: Add a) :: a

infixr 7 /
(/) :: Division a => a -> a -> a
(x :: a) / y = coerce ((coerce x `mul` inv (coerce y)) :: Mul a) :: a

exp :: Exponential a => a -> a
exp (x :: a) = coerce (hom (coerce x :: Add a) :: Mul a) :: a

log :: Logarithmic a => a -> a
log (x :: a) = coerce (hom (coerce x :: Mul a) :: Add a) :: a

-- | Equal to, Less than, Greater than, Not comparable to
data POrdering = PEQ | PLT | PGT | PNC
class POrd s where pcompare :: s -> s -> POrdering
class POrd s => Topped s where top :: s
class POrd s => Bottomed s where bottom :: s

type Semilattice s = (Abelian Semigroup s, Idempotent s)
type PBounded s = (Topped s, Bottomed s)

class (
    Coercible s (Sup s)
  , Coercible s (Inf s)
  , Semilattice (Sup s)
  , Semilattice (Inf s)
  , POrd s
  ) => Lattice s where
  type family Inf s
  type family Sup s
  (/\) :: s -> s -> s
  (/\) = coerce (mul :: Sup s -> Sup s -> Sup s)
  (\/) :: s -> s -> s
  (\/) = coerce (mul :: Inf s -> Inf s -> Inf s)

type Negated s = (Lattice s, Homomorphic (Inf s) (Sup s))

negate :: Negated s => s -> s
negate (a :: s) = coerce (hom (coerce a :: Inf s) :: Sup s) :: s

ord2pord :: Ordering -> POrdering
ord2pord EQ = PEQ
ord2pord LT = PLT
ord2pord GT = PGT

-- | A Premodule is simply the Constraints
--   listed below.
class (
    Distributive m
  , Semiring r
  , Homomorphic r m
  , Semigroup m
  , Commutative m
  ) => Premodule r m

infixr 6 .+
(.+) :: Premodule r m => r -> m -> m
r .+ m = hom r + m 

infixr 7 .*
(.*) :: Premodule r m => r -> m -> m
r .* m = hom r * m 

infixr 6 .-
(.-) :: (Premodule r m, Commutative (Add m), Invertible (Add m)) => r -> m -> m
r .- m = hom r - m 

infixr 7 ./
(./) :: (Premodule r m, Commutative (Mul m), Invertible (Mul m), Commutative (Add m), Invertible (Add m)) => r -> m -> m
r ./ m = hom r / m 

-- | A Semimodule is a Premodule where the action is distributive 
class (
    Premodule r m
  , Monoid m
  , Semiring r
  ) => Semimodule r m

-- A Module is a Semimodule where m is a group and r is a ring
class (
    Ring r
  , Group m
  , Semimodule r m
  ) => Module r m
