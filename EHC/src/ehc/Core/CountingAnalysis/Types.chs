%%[(8 core) hs module {%{EH}Core.CountingAnalysis.Types}

import %%@{%{EH}%%}Base.HsName (HsName, hsnIsNr)

import Data.Set (Set)
import qualified Data.Set as S
import Data.Map (Map)
import qualified Data.Map as M

import Control.Monad
import UHC.Util.Binary
import UHC.Util.Serialize



data AnnPrim = Zero | One | Infinity
  deriving (Data, Typeable, Eq, Ord, Show, Generic)
type AnnVal = Set AnnPrim
data Annotation = AnnVar Var | AnnVal AnnVal
  deriving (Data, Typeable, Eq, Ord, Show, Generic)
type UseAnn = Annotation
type DemandAnn = Annotation

annBot' = S.empty
annZero' = S.singleton Zero
annOne' = S.singleton One
annW' = S.singleton Infinity
annTop' = S.fromList [Zero, One, Infinity]

annBot = AnnVal annBot'
annZero = AnnVal annZero'
annOne = AnnVal annOne'
annW = AnnVal annW'
annTop = AnnVal annTop'

annPow :: AnnVal -> Set AnnVal
annPow = S.fromList . map (S.fromList) . annPow' . S.toList
  where annPow' [] = [[]]
        annPow' (x:xs) = p ++ map (x:) p
          where p = annPow' xs

annPowWithoutEmpty :: AnnVal -> Set AnnVal
annPowWithoutEmpty = S.delete (S.empty) . annPow

data AnnotatedType
  = TyVar HsName
  | TyData HsName [Annotation] [AnnotatedType]
  | TyFunc (Rho AnnotatedType) (Eta AnnotatedType)
  | TyRow [AnnotatedType]
  -- If this is ever inspected then something is wrong in the algorithm
  -- But at the moment it is needed as the AG needs a type in every expression
  -- even unused ones
  | TyError String
  deriving (Data, Typeable, Eq, Ord, Show, Generic)
  
data Eta a = Eta a UseAnn
  deriving (Data, Typeable, Eq, Ord, Show, Generic)
data Rho a = Rho (Eta a) DemandAnn 
  deriving (Data, Typeable, Eq, Ord, Show, Generic)

instance Functor Eta where
  fmap f (Eta x a) = Eta (f x) a

instance Functor Rho where
  fmap f (Rho x a) = Rho (fmap f x) a

data TyScheme 
  = SchemeVar SchemeVar 
  | SForAll (Set HsName) Constraints AnnotatedType
  deriving (Data, Typeable, Eq, Ord, Show, Generic)

type Var = Int
newtype SchemeVar = SV {unSV :: Var}
  deriving (Data, Typeable, Eq, Ord, Show, Generic)

type Env = Map HsName (Rho TyScheme)

type Constraints = [Constraint]

annAdd :: AnnVal -> AnnVal -> AnnVal
annAdd a1 a2 = S.fromList [x .+ y | x <- S.toList a1, y <- S.toList a2] 

annUnion :: AnnVal -> AnnVal -> AnnVal
annUnion = S.union

annTimes :: AnnVal -> AnnVal -> AnnVal
annTimes a1 a2 = S.fromList [annFromInt (sum $ map annToInt y) | x <- S.toList a1, y <- f (annToInt x) $ S.toList a2]
  where f 0 _ = [[]] 
        f _ [] = []
        f n y@(x:xs) = f n xs ++ map (x:) (f (n-1) y)

annCon :: AnnVal -> AnnVal -> AnnVal
annCon a1 a2 = S.unions $ map (\x -> if x == Zero then annZero' else a2) $ S.toList a1

(.+) :: AnnPrim -> AnnPrim -> AnnPrim
x .+ y = annFromInt $ annToInt x + annToInt y

annToInt :: AnnPrim -> Int
annToInt Zero = 0
annToInt One = 1
annToInt Infinity = 2;

annFromInt :: Int -> AnnPrim
annFromInt 0 = Zero
annFromInt 1 = One
annFromInt _ = Infinity

data Constraint 
  -- Annotation constraints
  = AnnC (C Annotation)
  -- AnnotatedType constraints
  | TyC (C AnnotatedType)
  -- TyScheme constraints
  | SchemeC (C TyScheme)
  -- Instantiation constraint
  | InstC TyScheme AnnotatedType
  -- Generalisation constraint
  | GenC (Rho AnnotatedType) Constraints Env (Rho TyScheme)
  deriving (Data, Typeable, Eq, Ord, Show, Generic)

data C a
  = EqC a a
  | PlusC a a a
  | UnionC a a a
  | TimesC a Annotation a
  | ConC a Annotation a
  deriving (Data, Typeable, Eq, Ord, Show, Generic)

instance Serialize AnnPrim where
instance Serialize Annotation where
instance Serialize AnnotatedType where
instance Serialize a => Serialize (Eta a) where
instance Serialize a => Serialize (Rho a) where
instance Serialize TyScheme where
instance Serialize SchemeVar where
instance Serialize Constraint where
instance Serialize a => Serialize (C a) where

replaceRho :: AnnotatedType -> Rho AnnotatedType -> Rho AnnotatedType
replaceRho bt (Rho t d)      = Rho (replaceEta bt t) d

replaceEta :: AnnotatedType -> Eta AnnotatedType -> Eta AnnotatedType
replaceEta bt (Eta t u)      = Eta (replace bt t) u

replace :: AnnotatedType -> AnnotatedType -> AnnotatedType
replace bt tv@(TyVar v)      = if hsnIsNr v then bt else tv
replace bt (TyData n ann tl) = TyData n ann $ map (replace bt) tl
replace bt (TyFunc rt et)    = TyFunc (replaceRho bt rt) $ replaceEta bt et
replace _ x = x

stripRho :: Rho a -> Eta a
stripRho (Rho t _) = t

stripEta :: Eta a -> a
stripEta (Eta t _) = t

stripRhoEta :: Rho a -> a
stripRhoEta (Rho (Eta t _) _) = t

getAnnRho :: Rho a -> Annotation
getAnnRho (Rho _ a) = a

getAnnEta :: Eta a -> Annotation
getAnnEta (Eta _ a) = a

%%]
