module Data.Woot.Core
    ( integrate
    , integrateAll
    , makeDeleteOperation
    , makeInsertOperation
    ) where


import Control.Applicative -- keep for ghc <7.10
import Data.Maybe (fromJust)

import Data.Woot.WString
import Data.Woot.WChar
import Data.Woot.Operation


integrate :: Operation -> WString -> Maybe WString
integrate op ws = if canIntegrate op ws then Just $ integrateOp op ws else Nothing


-- iterate through operation list until stable
-- return any remaining operations, along with new string
integrateAll :: [Operation] -> WString -> ([Operation], WString)
integrateAll ops ws = if length ops == length newOps then result
    else integrateAll newOps newString
  where
    result@(newOps, newString)  = foldl integrate' ([], ws) ops
    integrate' (ops', s) op = maybe (ops' ++ [op], s) (ops',) (integrate op s)


canIntegrate :: Operation -> WString -> Bool
canIntegrate (Operation Insert _ wc) ws = all (\(Just wid) -> wid `hasChar` ws) [wCharPrevId wc, wCharNextId wc]
canIntegrate (Operation Delete _ wc) ws = hasChar (wCharId wc) ws


integrateOp :: Operation -> WString -> WString
integrateOp (Operation Insert _ wc) ws = integrateInsert (wCharPrevId wc) (wCharNextId wc) wc ws
integrateOp (Operation Delete _ wc) ws = integrateDelete wc ws


integrateInsert :: Maybe WCharId -> Maybe WCharId -> WChar -> WString -> WString
-- if char already exists
integrateInsert _ _ wc ws | hasChar (wCharId wc) ws = ws
-- if at the very start or end of the wString
integrateInsert Nothing _ wc ws = insertChar 1 wc ws
integrateInsert _ Nothing wc ws = insertChar (length' ws - 2) wc ws
integrateInsert (Just prevId) (Just nextId) wc ws = if isEmpty sub
    -- should always be safe to get index and insert since we have flagged this as 'canIntegrate'
    then insertChar (fromJust $ indexOf nextId ws) wc ws
    else compareIds $ map wCharId (toList sub) ++ [nextId]
  where
    sub = subsection prevId nextId ws
    compareIds :: [WCharId] -> WString
    -- current id is less than the previous id
    compareIds (wid:_) | wCharId wc < wid = insertChar (fromJust $ indexOf wid ws) wc ws
     -- recurse to integrateInsert with next id in the subsection
    compareIds (_:wid:_) = integrateInsert (Just wid) (Just nextId) wc ws
    -- should never have a match fall through to here, but for good measure...
    compareIds _  = ws


integrateDelete :: WChar -> WString -> WString
integrateDelete wc = hideChar (wCharId wc)


makeDeleteOperation :: ClientId -> Int -> WString -> Maybe Operation
makeDeleteOperation cid pos ws = Operation Delete cid <$> nthVisible pos ws


makeInsertOperation :: ClientId -> Int -> Int -> Char -> WString -> Maybe Operation
makeInsertOperation cid clock pos a ws = Operation Insert cid <$> do
    let numVis = length' $ visibleChars ws
    prev <- if pos == 0 then ws !? 0 else nthVisible (pos - 1) ws
    next <- if pos >= numVis then ws !? (length' ws - 1) else nthVisible pos ws
    return $ WChar (WCharId cid clock) True a (Just $ wCharId prev) (Just $ wCharId next)
