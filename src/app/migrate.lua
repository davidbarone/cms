#!/usr/bin/lua
package.path = package.path .. ";./controllers/?.lua;./lib/?.lua"
require "lsqlite3"
local common=require "common"
require "ext_io"
local active_record = require "active_record"

--create active record object
local ar = active_record.new({connection_string="./cms.sl3"})

-- create a migration table if not already there
ar:exec_db [[
  CREATE TABLE IF NOT EXISTS migration (
    mi_name TEXT NOT NULL PRIMARY KEY,
    mi_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
]]

-- Start Migration
local c = ar:read("migration"):count()
print(string.format('Beginning migration. Current version is %s.', c))

-- loop through each file in ./migrations folder
for _, file in pairs(io.files_in_dir('./migrations')) do
  local sql = io.file_read('./migrations/'..file)

  -- check if file already migrated?
  if not ar:read("migration"):where(function(k,v) return v.mi_name==file end):any() then
    
    -- execute script
    local errcode, errmsg = ar:exec_db(sql)
    print(string.format("File: %s, result: %s", file, errmsg))

    if errmsg == "not an error" then
      local row = ar:create("migration")
      row.mi_name = file
      row:save()
    else
      os.exit(1)
    end
  end
end

-- End migration
c = ar:read("migration"):count()
print(string.format('Migration Complete. Current version is %s.', c))
