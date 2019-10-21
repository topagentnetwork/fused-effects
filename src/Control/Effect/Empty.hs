{-# LANGUAGE DeriveFunctor, DeriveGeneric, FlexibleContexts, KindSignatures #-}

{- | An effect modelling nondeterminism without choice (success or failure).

This can be seen as similar to 'Control.Effect.Fail.Fail', but without an error message. The 'Control.Effect.NonDet.NonDet' effect is the composition of 'Empty' and 'Control.Effect.Choice.Choice'.

Predefined carriers:

* "Control.Carrier.Empty.Maybe".
* If 'Empty' is the last effect in a stack, it can be interpreted directly to a 'Maybe'.

@since 1.0.0.0
-}

module Control.Effect.Empty
( -- * Empty effect
  Empty(..)
, empty
, guard
  -- * Re-exports
, Carrier
, Has
, run
) where

import Control.Algebra
import GHC.Generics (Generic1)

-- | @since 1.0.0.0
data Empty (m :: * -> *) k = Empty
  deriving (Functor, Generic1)

instance HFunctor Empty
instance Effect   Empty

-- | Abort the computation.
--
-- 'empty' annihilates '>>=':
--
-- @
-- 'empty' '>>=' k = 'empty'
-- @
--
-- @since 1.0.0.0
empty :: Has Empty sig m => m a
empty = send Empty

-- | Conditional failure, returning only if the condition is 'True'.
--
-- @since 1.0.0.0
guard :: Has Empty sig m => Bool -> m ()
guard True  = pure ()
guard False = empty
