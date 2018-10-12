{-# LANGUAGE DeriveFunctor, PolyKinds #-}
module Control.Effect.NonDet.Internal
( NonDet(..)
) where

import Control.Effect.Handler

data NonDet m k
  = Empty
  | Choose (Bool -> k)
  deriving (Functor)

instance HFunctor NonDet where
  hmap _ Empty      = Empty
  hmap _ (Choose k) = Choose k

instance Effect NonDet where
  handle _     _       Empty      = Empty
  handle state handler (Choose k) = Choose (handler . (<$ state) . k)
