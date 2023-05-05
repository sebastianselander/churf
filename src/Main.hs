{-# LANGUAGE OverloadedRecordDot #-}

module Main where

import AnnForall (annotateForall)
import Codegen.Codegen (generateCode)
import Compiler (compile)
import Control.Monad (when, (<=<))
import Data.List.Extra (isSuffixOf)
import Data.Maybe (fromJust, isNothing)
import Desugar.Desugar (desugar)
import GHC.IO.Handle.Text (hPutStrLn)
import Grammar.ErrM (Err)
import Grammar.Layout (resolveLayout)
import Grammar.Par (myLexer, pProgram)
import Grammar.Print (Print, printTree)
import LambdaLifter (lambdaLift)
import Monomorphizer.Monomorphizer (monomorphize)
import OrderDefs (orderDefs)
import Renamer.Renamer (rename)
import ReportForall (reportForall)
import System.Console.GetOpt (
    ArgDescr (NoArg, ReqArg),
    ArgOrder (RequireOrder),
    OptDescr (Option),
    getOpt,
    usageInfo,
 )
import System.Directory (
    createDirectory,
    doesPathExist,
    getDirectoryContents,
    removeDirectoryRecursive,
    setCurrentDirectory,
 )
import System.Environment (getArgs)
import System.Exit (
    ExitCode (ExitFailure),
    exitFailure,
    exitSuccess,
    exitWith,
 )
import System.IO (stderr)
import System.Process (spawnCommand, waitForProcess)
import TypeChecker.TypeChecker (TypeChecker (Bi, Hm), typecheck)

main :: IO ()
main = getArgs >>= parseArgs >>= uncurry main'

parseArgs :: [String] -> IO (Options, String)
parseArgs argv = case getOpt RequireOrder flags argv of
    (os, f : _, [])
        | opts.help || isNothing opts.typechecker -> do
            hPutStrLn stderr (usageInfo header flags)
            exitSuccess
        | otherwise -> pure (opts, f)
      where
        opts = foldr ($) initOpts os
    (_, _, errs) -> do
        hPutStrLn stderr (concat errs ++ usageInfo header flags)
        exitWith (ExitFailure 1)
  where
    header = "Usage: language [--help] [-d|--debug] [-t|type-checker bi/hm] FILE \n"

flags :: [OptDescr (Options -> Options)]
flags =
    [ Option ['d'] ["debug"] (NoArg enableDebug) "Print debug messages."
    , Option ['t'] ["type-checker"] (ReqArg chooseTypechecker "bi/hm") "Choose type checker. Possible options are bi and hm"
    , Option ['m'] ["disable-gc"] (NoArg disableGC) "Disables the garbage collector and uses malloc instead."
    , Option [] ["help"] (NoArg enableHelp) "Print this help message"
    ]

initOpts :: Options
initOpts =
    Options
        { help = False
        , debug = False
        , gc = True
        , typechecker = Nothing
        }

enableHelp :: Options -> Options
enableHelp opts = opts{help = True}

enableDebug :: Options -> Options
enableDebug opts = opts{debug = True}

disableGC :: Options -> Options
disableGC opts = opts{gc = False}

chooseTypechecker :: String -> Options -> Options
chooseTypechecker s options = options{typechecker = tc}
  where
    tc = case s of
        "hm" -> pure Hm
        "bi" -> pure Bi
        _ -> Nothing

data Options = Options
    { help :: Bool
    , debug :: Bool
    , gc :: Bool
    , typechecker :: Maybe TypeChecker
    }

main' :: Options -> String -> IO ()
main' opts s =
    let
        log :: (Print a, Show a) => a -> IO ()
        log = printToErr . if opts.debug then show else printTree
     in
        do
            file <- readFile s

            printToErr "-- Parse Tree -- "
            parsed <- fromErr . pProgram . resolveLayout True $ myLexer (file ++ prelude)
            log parsed

            printToErr "-- Desugar --"
            let desugared = desugar parsed
            log desugared

            printToErr "\n-- Renamer --"
            _ <- fromErr $ reportForall (fromJust opts.typechecker) desugared
            renamed <- fromErr $ (rename <=< annotateForall) desugared
            log renamed

            printToErr "\n-- TypeChecker --"
            typechecked <- fromErr $ typecheck (fromJust opts.typechecker) (orderDefs renamed)
            log typechecked

            printToErr "\n-- Lambda Lifter --"
            let lifted = lambdaLift typechecked
            log lifted

            printToErr "\n -- Monomorphizer --"
            let monomorphized = monomorphize lifted
            log monomorphized

            printToErr "\n -- Compiler --"
            generatedCode <- fromErr $ generateCode monomorphized (gc opts)

            check <- doesPathExist "output"
            when check (removeDirectoryRecursive "output")
            createDirectory "output"
            createDirectory "output/logs"
            when opts.debug $ do
                writeFile "output/llvm.ll" generatedCode
                debugDotViz

            compile generatedCode (gc opts)
            printToErr "Compilation done!"
            printToErr "\n-- Program output --"
            print =<< spawnWait "./output/hello_world"

            exitSuccess

debugDotViz :: IO ()
debugDotViz = do
    setCurrentDirectory "output"
    spawnWait "opt -dot-cfg llvm.ll -disable-output"
    content <- filter (isSuffixOf ".dot") <$> getDirectoryContents "."
    let commands = (\p -> "dot " <> p <> " -Tpng -o" <> p <> ".png") <$> content
    mapM_ spawnWait commands
    setCurrentDirectory ".."
    return ()

spawnWait :: String -> IO ExitCode
spawnWait s = spawnCommand s >>= waitForProcess

printToErr :: String -> IO ()
printToErr = hPutStrLn stderr

fromErr :: Err a -> IO a
fromErr = either (\s -> printToErr s >> exitFailure) pure

prelude :: String
prelude =
    unlines
        [ "\n"
        , "data Bool where"
        , "    False : Bool"
        , "    True  : Bool"
        , -- The function body of lt is replaced during code gen. It exists here for type checking purposes.
          "lt : Int -> Int -> Bool"
        , "lt x y = case x of"
        , "    _ => True"
        , "    _ => False"
        , "\n"
        , -- The function body of - is replaced during code gen. It exists here for type checking purposes.
          ".- : Int -> Int -> Int"
        , ".- x y = 0"
        , "\n"
        ]
