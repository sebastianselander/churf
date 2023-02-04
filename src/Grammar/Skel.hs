-- File generated by the BNF Converter (bnfc 2.9.4.1).

-- Templates for pattern matching on abstract syntax

{-# OPTIONS_GHC -fno-warn-unused-matches #-}

module Grammar.Skel where

import Prelude (($), Either(..), String, (++), Show, show)
import qualified Grammar.Abs

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transIdent :: Grammar.Abs.Ident -> Result
transIdent x = case x of
  Grammar.Abs.Ident string -> failure x

transProgram :: Grammar.Abs.Program -> Result
transProgram x = case x of
  Grammar.Abs.Program exp -> failure x

transExp :: Grammar.Abs.Exp -> Result
transExp x = case x of
  Grammar.Abs.EId ident -> failure x
  Grammar.Abs.EInt integer -> failure x
  Grammar.Abs.EApp exp1 exp2 -> failure x
  Grammar.Abs.EAdd exp1 exp2 -> failure x
  Grammar.Abs.ESub exp1 exp2 -> failure x
  Grammar.Abs.EMul exp1 exp2 -> failure x
  Grammar.Abs.EDiv exp1 exp2 -> failure x
  Grammar.Abs.EMod exp1 exp2 -> failure x
  Grammar.Abs.EAbs ident exp -> failure x
