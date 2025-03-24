module Main where

import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)
import System.IO
import Text.HTML.TagSoup

-- html-extractor [args] -h label Foo.lhs /tmp/somefile

main :: IO ()
main = getArgs >>= \args -> do
  case break (== "-h") args of
    (_opts, "-h" : files) -> case files of
      [src, cur, dst] -> writeFileUtf8 dst =<< preprocess src =<< readFileUtf8 cur
      [src]           -> writeUtf8 stdout =<< preprocess src =<< readFileUtf8 src
      _ -> usage
    _ -> usage
    where
      usage :: IO ()
      usage = do
        name <- getProgName
        hPutStrLn stderr ("usage: " ++ name ++ " [selector] -h SRC CUR DST")
        exitFailure

      readFileUtf8 :: FilePath -> IO String
      readFileUtf8 name = openFile name ReadMode >>= \ handle -> hSetEncoding handle utf8 >> hGetContents handle

      writeFileUtf8 :: FilePath -> String -> IO ()
      writeFileUtf8 name str = withFile name WriteMode $ \ handle -> writeUtf8 handle str

      writeUtf8 :: Handle -> String -> IO ()
      writeUtf8 handle str = hSetEncoding handle utf8 >> hPutStr handle str

preprocess :: FilePath -> String -> IO String
preprocess fp str = do
  pure
    . innerText
    . mconcat
    . sections (~== "<code data-lang=\"haskell\">")
    . putLinesInfo fp
    . parseTagsOptions parseOptions{optTagPosition=True}
    $ str

putLinesInfo :: FilePath -> [Tag String] -> [Tag String]
putLinesInfo fp = go []
  where
  go acc ((TagPosition line _):(TagOpen "code" attrs):xs) =
    if ("data-lang","haskell") `elem` attrs
    then (TagOpen "code" attrs) : TagText ("#line " <> show (line+1) <> " " <> show fp) : go acc xs
    else (TagOpen "code" attrs) : go acc xs
  go acc (x:xs) = x : go acc xs
  go acc []     = acc
