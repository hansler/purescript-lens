module Optic.Prism
  ( prism
  , prism'
  , _Left
  , _Right
  , _Just
  , _Nothing
  ) where

  import Optic.Internal.Prism (Market(..))
  import Optic.Types (APrism(), Prism(), PrismP())

  import Data.Either (either, Either(..))
  import Data.Identity (runIdentity, Identity(..))
  import Data.Maybe (maybe, Maybe(..))
  import Data.Profunctor (dimap)
  import Data.Profunctor.Choice (right', Choice)

  clonePrism :: forall f p s t a b. (Applicative f, Choice p) => APrism  s t a b -> p a (f b) -> p s (f t)
  clonePrism stab = withPrism stab prism

  is :: forall s t a b. APrism s t a b -> s -> Boolean
  is stab s = either (const false) (const true) $ matching stab s

  isn't :: forall s t a b. APrism s t a b -> s -> Boolean
  isn't stab s = not $ is stab s

  matching :: forall s t a b. APrism s t a b -> s -> Either t a
  matching stab = withPrism stab \_ s -> s

  prism :: forall f p s t a b. (Applicative f, Choice p) => (b -> t) -> (s -> Either t a) -> p a (f b) -> p s (f t)
  prism b2t s2Eta pafb = dimap s2Eta (either pure ((<$>) b2t)) (right' pafb)

  prism' :: forall s a b. (b -> s) -> (s -> Maybe a) -> Prism s s a b
  prism' b2s s2Ma = prism b2s (\s -> maybe (Left s) Right $ s2Ma s)

  withPrism :: forall b r a t s. APrism s t a b -> ((b -> t) -> (s -> Either t a) -> r) -> r
  withPrism stab f = case stab (Market Identity Right) of
    Market b2t s2Eta -> f (runIdentity <<< b2t) (s2Eta >>> either (runIdentity >>> Left) Right)

  _Left :: forall a b c. Prism (Either a c) (Either b c) a b
  _Left = prism Left $ either Right (Left <<< Right)

  _Right :: forall a b c. Prism (Either a b) (Either a c) b c
  _Right = prism Right $ either (Left <<< Left) Right

  _Just :: forall a b. Prism (Maybe a) (Maybe b) a b
  _Just = prism Just $ maybe (Left Nothing) Right

  _Nothing :: forall a b. PrismP (Maybe a) Unit
  _Nothing = prism' (const Nothing) $ maybe Nothing (const $ Just unit)
