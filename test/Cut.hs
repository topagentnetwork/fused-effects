{-# LANGUAGE FlexibleContexts, RankNTypes, ScopedTypeVariables, TypeApplications #-}
module Cut
( tests
, gen0
, genN
, test
) where

import qualified Control.Carrier.Cut.Church as CutC
import Control.Carrier.Reader
import Control.Effect.Choose
import Control.Effect.Cut (Cut, call, cutfail)
import Control.Effect.NonDet (NonDet)
import Gen
import qualified Monad
-- import qualified MonadFix
import qualified NonDet
import qualified Reader
import Test.Tasty
import Test.Tasty.Hedgehog

tests :: TestTree
tests = testGroup "Cut"
  [ testGroup "CutC" $
    [ testMonad
    -- , testMonadFix
    , testCut
    ] >>= ($ runL CutC.runCutA)
  , testGroup "ReaderC · CutC" $
    Cut.test (local (id @R)) (m (\ a -> gen0 ++ Reader.gen0 r a) (\ m a -> genN m a ++ Reader.genN r m a)) a b (pair <*> r <*> unit) (Run (CutC.runCutA . uncurry runReader))
  , testGroup "CutC · ReaderC" $
    Cut.test (local (id @R)) (m (\ a -> gen0 ++ Reader.gen0 r a) (\ m a -> genN m a ++ Reader.genN r m a)) a b (pair <*> r <*> unit) (Run (uncurry ((. CutC.runCutA) . runReader)))
  ] where
  testMonad    run = Monad.test    (m (const gen0) genN) a b c (identity <*> unit) run
  -- testMonadFix run = MonadFix.test (m (const gen0) genN) a b   (identity <*> unit) run
  testCut      run = Cut.test id   (m (const gen0) genN) a b   (identity <*> unit) run


gen0 :: (Has Cut sig m, Has NonDet sig m) => [Gen (m a)]
gen0 = label "cutfail" cutfail : NonDet.gen0

genN :: (Has Cut sig m, Has NonDet sig m) => GenM m -> Gen a -> [Gen (m a)]
genN m a = (label "call" call <*> m a) : NonDet.genN m a


test
  :: forall a b m f sig
  .  (Has Cut sig m, Has NonDet sig m, Arg a, Eq a, Eq b, Show a, Show b, Vary a, Functor f)
  => (forall a . m a -> m a)
  -> GenM m
  -> Gen a
  -> Gen b
  -> Gen (f ())
  -> Run f [] m
  -> [TestTree]
test hom m a b i (Run runCut)
  = testProperty "cutfail annihilates >>=" (forall (i :. fn @a (m a) :. Nil)
    (\ i k -> runCut ((hom cutfail >>= k) <$ i) === runCut (hom cutfail <$ i)))
  : testProperty "cutfail annihilates <|>" (forall (i :. m a :. Nil)
    (\ i m -> runCut ((hom cutfail <|> m) <$ i) === runCut (hom cutfail <$ i)))
  : testProperty "call delimits cutfail" (forall (i :. m a :. Nil)
    (\ i m -> runCut ((hom (call (hom cutfail)) <|> m) <$ i) === runCut (m <$ i)))
  : NonDet.test m a b i (Run runCut)
