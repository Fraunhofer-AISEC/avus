{-# LANGUAGE NamedFieldPuns #-}
-- module Main where
import Rivum
import Rivum.CVSS
import Rivum.Utils (returnIO)
import System.FilePath

-- Confidentiality, Integrity, Availability
data Requirements = Requirements (Req, Req, Req)
type SecurityConcept = Domain -> Requirements

data Domain = Userland
            | Kernel
	    | Misc
	      deriving (Eq, Show)

classify :: FilePath -> Domain
classify fp
  | fp `elem` userland = Userland
  | fp `elem` misc     = Misc
  | otherwise          = Kernel
  where
    userland = ["cat.c", "echo.c","forktest.c", "grep.c", "kill.c", "ln.c",
                     "ls.c", "mkdir.c", "mkfs.c", "stressfs.c", "usertests.c",
		     "wc.c", "zombie.c", "rm.c", "printf.c"]
    kernel   = ["mem.c"] -- TODO
    misc     = ["sh.c", "init.c"]

concept :: SecurityConcept
concept Userland = Requirements (ReqL, ReqH, ReqL)
concept Misc     = Requirements (ReqL, ReqH, ReqL)
concept Kernel   = Requirements (ReqL, ReqH, ReqL)

-- ignores the filepath, sets project-level parameters
xv6base :: FilePath -> Base -> Base
xv6base _ b = b { av = AvL, ac = AcL, au = AuN }

xv6env :: FilePath -> Env -> Env
xv6env fp e =
    let domain = classify fp
        Requirements (cr, ir, ar) = concept domain in
            e { cr, ir, ar } -- TODO: verify that this works
            --e { cr = cr, ir = ir, ar = ar }

xv6Config = defaultConfig
    --{ baseUpdate = \fp b -> return $ xv6base fp b
    { baseUpdate = returnIO xv6base
    , envUpdate = returnIO xv6env
    }

main = processScan xv6Config
