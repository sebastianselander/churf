{-# LANGUAGE LambdaCase #-}
module Main where

import           Compiler.Compiler    (compile)
import           Control.Monad.Except (runExcept)
import           Grammar.Par          (myLexer, pProgram)
import           Interpreter          (interpret)
import           System.Environment   (getArgs)
import           System.Exit          (exitFailure, exitSuccess)

main :: IO ()
main = getArgs >>= \case
  []    -> print "Required file path missing"
  (x:_) -> do
    file <- readFile x
    case pProgram (myLexer file) of
      Left err -> do
       putStrLn "SYNTAX ERROR"
       putStrLn err
       exitFailure
      Right prg -> case compile prg of
        Left err  -> putStrLn err
        Right res -> putStrLn res



