{-# LANGUAGE OverloadedStrings #-}

module Guide.Api.Migration where

import Imports

import Hasql.Session (Session)
-- import Hasql.Statement (Statement(..))
import Hasql.Connection (Connection, Settings)

import qualified Hasql.Session as HS
-- import qualified Hasql.Decoders as HD
-- import qualified Hasql.Encoders as HE
import qualified Data.ByteString as B
import qualified Hasql.Connection as HC


main :: IO ()
main = do
  conn <- connection
  dbCreate conn

connection :: IO Connection
connection = do
  eiConnection <- HC.acquire connectionSettings
  let conn = either (error . show) id eiConnection
  pure conn

connectionSettings :: Settings
connectionSettings = HC.settings "localhost" 5432 "postgres" "3" "guide"

dbCreate :: Connection -> IO ()
dbCreate conn = do
  result <- mapM (\s -> HS.run s conn)
    [createTypeProcons, createDbCategories, createDbItems, createDbTraits, createDbUsers, createDbEdits]
  mapM_ (either print pure) result

createTypeProcons :: Session ()
createTypeProcons = HS.sql "CREATE TYPE trait_type AS ENUM ('pro', 'con');"

createDbTraits :: Session ()
createDbTraits = HS.sql $ B.intercalate " "
  [ "CREATE TABLE traits ("
  ,   "uid text PRIMARY KEY,"           -- Unique trait ID
  ,   "content text NOT NULL,"          -- Trait content as Markdown
  ,     "deleted boolean"               -- Whether the trait is deleted
  ,     "DEFAULT false"
  ,     "NOT NULL,"
  ,   "type_ trait_type NOT NULL,"     -- Trait type (pro or con)
  ,   "item_uid text"                  -- Item that the trait belongs to
  ,     "REFERENCES items (uid)"
  ,     "ON DELETE CASCADE"
  , ");"
  ]

createDbItems :: Session ()
createDbItems = HS.sql $ B.intercalate " "
  [ "CREATE TABLE items ("
  ,   "uid text PRIMARY KEY,"           -- Unique item ID
  ,   "name text NOT NULL,"             -- Item title
  ,   "created timestamp NOT NULL,"     -- When the item was created
  ,   "group_ text,"                    -- Optional group
  ,   "link text,"                      -- Optional URL
  ,   "hackage text,"                   -- Package name on Hackage
  ,   "summary text NOT NULL,"          -- Item summary as Markdown
  ,   "ecosystem text NOT NULL,"        -- The ecosystem section
  ,   "notes text NOT NULL,"            -- The notes section
  ,   "deleted boolean"                 -- Whether the item is deleted
  ,     "DEFAULT false"
  ,     "NOT NULL,"
  ,   "category_uid text"               -- Category that the item belongs to
  ,     "REFERENCES categories (uid)"
  ,     "ON DELETE CASCADE"
  , ");"
  ]

createDbCategories :: Session ()
createDbCategories = HS.sql $ B.intercalate " "
  [ "CREATE TABLE categories ("
  ,   "uid text PRIMARY KEY,"           -- Unique category ID
  ,   "title text NOT NULL,"            -- Category title
  ,   "created timestamp NOT NULL,"     -- When the category was created
  ,   "group_ text NOT NULL,"           -- "Grandcategory"
  ,   "status_ text NOT NULL,"          -- Category status ("in progress", etc); the list of
                                        --   possible statuses is defined by backend
  ,   "notes text NOT NULL,"            -- Category notes as Markdown
  ,   "enabled_sections text[]"         -- Item sections to show to users; the list of possible
  ,     "NOT NULL"                      --   section names is defined by backend
  , ");"
  ]

createDbUsers :: Session ()
createDbUsers = HS.sql $ B.intercalate " "
  [ "CREATE TABLE users ("
  ,   "uid text PRIMARY KEY,"           -- Unique user ID
  ,   "name text NOT NULL,"             -- User name
  ,   "email text NOT NULL,"            -- User email
  ,   "password_scrypt text,"           -- User password (scrypt-ed)
  ,   "is_admin boolean"                -- Whether the user is admin
  ,     "DEFAULT false"
  ,     "NOT NULL"
  , ");"
  ]

createDbEdits :: Session ()
createDbEdits = HS.sql $ B.intercalate " "
  [ "CREATE TABLE pending_edits ("
  ,   "uid bigserial PRIMARY KEY,"   -- Unique id
  ,   "edit json NOT NULL,"          -- Edit in JSON format
  ,   "ip cidr,"                     -- IP address of edit maker
  ,   "time_ timestamp NOT NULL"     -- When the edit was created
  , ");"
  ]


-- Sandbox --

-- data Test = Test
--   { digit :: Int32
--   , string :: Text
--   } deriving Show

-- testStatement :: Statement () [Test]
-- testStatement = Statement sql encoder decoder True where
--   sql = "select * FROM test"
--   encoder = HE.noParams
--   decoder :: HD.Result [Test]
--   decoder = HD.rowList (Test <$> ((HD.column . HD.nonNullable) HD.int4) <*> ((HD.column . HD.nonNullable) HD.text))

-- testCreateStatement :: Session ()
-- testCreateStatement = HS.sql "CREATE TABLE test (digit integer, string text);"
