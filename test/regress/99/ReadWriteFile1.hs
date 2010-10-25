{- ----------------------------------------------------------------------------------------
   what    : readFile, writeFile
   expected: ok
   constraints: exclude-if-jscript
---------------------------------------------------------------------------------------- -}

module Main where
import Debug.Trace

main :: IO ()
main
  = do f1 <- readFile "filesForIOTesting/file1"
       writeFile "filesForIOTesting/file1-writtencopy" f1
       f2 <- readFile "filesForIOTesting/file1-writtencopy"
       putStrLn ("length orig=" ++ show (length f1))
       putStrLn ("length copy=" ++ show (length f2))
       
       
