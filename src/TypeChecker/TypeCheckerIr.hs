{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE PatternSynonyms #-}


module TypeChecker.TypeCheckerIr
  ( module Grammar.Abs
  , module TypeChecker.TypeCheckerIr
  ) where

import           Data.String   (IsString)
import           Grammar.Abs   (Character (..), Lit (..), TVar (..))
import           Grammar.Print
import           Prelude
import qualified Prelude       as C (Eq, Ord, Read, Show)

newtype Program' t = Program [Def' t]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Def' t = DBind (Bind' t)
            | DData (Data' t)
      deriving (C.Eq, C.Ord, C.Show, C.Read)

data Type
    = TLit Ident
    | TVar TVar
    | TData Ident [Type]
    | TFun Type Type
    | TAll TVar Type
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Data' t = Data t [Inj' t]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Inj' t = Inj Ident t
  deriving (C.Eq, C.Ord, C.Show, C.Read)

newtype Ident = Ident String
      deriving (C.Eq, C.Ord, C.Show, C.Read, IsString)

data Pattern' t
    = PVar (Id' t)    -- TODO should be Ident
    | PLit (Lit, t)   -- TODO should be Lit
    | PCatch
    | PEnum Ident
    | PInj Ident [Pattern' t] -- TODO should be (Pattern' t, t)
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Exp' t
    = EVar Ident
    | EInj Ident
    | ELit Lit
    | ELet (Bind' t) (ExpT' t)
    | EApp (ExpT' t) (ExpT' t)
    | EAdd (ExpT' t) (ExpT' t)
    | EAbs Ident   (ExpT' t)
    | ECase (ExpT' t) [Branch' t]
      deriving (C.Eq, C.Ord, C.Show, C.Read)

type Id'  t = (Ident, t)
type ExpT' t = (Exp' t, t)

data Bind' t = Bind (Id' t) [Id' t] (ExpT' t)
    deriving (C.Eq, C.Ord, C.Show, C.Read)

data Branch' t = Branch (Pattern' t, t) (ExpT' t)
  deriving (C.Eq, C.Ord, C.Show, C.Read)

instance Print Ident where
    prt i (Ident s) = prt i s

instance Print t => Print (Program' t) where
    prt i (Program sc) = prPrec i 0 $ prt 0 sc

instance Print t => Print (Bind' t) where
    prt i (Bind sig@(name, _) parms rhs) = prPrec i 0 $ concatD
        [ prtSig sig
        , prt 0 name
        , prtIdPs 0 parms
        , doc $ showString "="
        , prt 0 rhs
        ]

prtSig :: Print t => Id' t -> Doc
prtSig (name, t) = concatD [ prt 0 name
                           , doc $ showString ":"
                           , prt 0 t
                           , doc $ showString ";"
                           ]

instance Print t => Print (ExpT' t) where
  prt i (e, t) = concatD [ doc $ showString "("
                         , prt i e
                         , doc $ showString ","
                         , prt i t
                         , doc $ showString ")"
                         ]

instance Print t => Print [Bind' t] where
  prt _ []     = concatD []
  prt _ [x]    = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ";"), prt 0 xs]

prtIdPs :: Print t => Int -> [Id' t] -> Doc
prtIdPs i = prPrec i 0 . concatD . map (prt i)

instance Print t => Print (Id' t) where
  prt i (name, t) = concatD [ doc $ showString "("
                            , prt i name
                            , doc $ showString ","
                            , prt i t
                            , doc $ showString ")"
                            ]

instance Print t => Print (Exp' t) where
  prt i = \case
      EVar  name  -> prPrec i 3 $ prt 0 name
      EInj  name  -> prPrec i 3 $ prt 0 name
      ELit lit -> prPrec i 3 $ prt 0 lit
      ELet b e -> prPrec i 3 $ concatD
                      [ doc $ showString "let"
                      , prt 0 b
                      , doc $ showString "in"
                      , prt 0 e
                      ]
      EApp e1 e2 -> prPrec i 2 $ concatD
                        [ prt 2 e1
                        , prt 3 e2
                        ]
      EAdd e1 e2 -> prPrec i 1 $ concatD
                        [ prt 1 e1
                        , doc $ showString "+"
                        , prt 2 e2
                        ]
      EAbs v  e  -> prPrec i 0 $ concatD
                        [ doc $ showString "\\"
