require "lsqlite3"
require "ext_table"

local common=require "common"

local active_record = {}

-- must pass connection_string in constructor
common.class(active_record)

------------------------------------
-- active_record.read
--
-- selects (reads) records from table.
-- resulting rows are active records
------------------------------------
function active_record:read(table_name, filter)
  filter = table.new(filter)
  
  local mt = self:get_metatable(table_name,"EDIT")
  local sql = 'SELECT * FROM "'..table_name..'"'
  if type(filter)=="table" and filter:any() then
    sql = sql.." WHERE "..filter:map(
      function(k,v) return string.format('%s=:%s', k, k) end
    ):join(" AND ")
  end
  local db = sqlite3.open(self.connection_string)
  local stmt = db:prepare(sql)
  assert(type(stmt)~="nil", "Statement: ["..sql.."] not prepared.")
  if type(filter)=="table" then
    stmt:bind_names(filter)
  end

  local rows={}
  for row in stmt:nrows() do
    row=setmetatable(row, mt)
    table.insert(rows,row)
  end
  rows = table.new(rows)
  stmt:finalize()
  db:close()
  return rows
end

------------------------------------
-- active_record.query
--
-- executes query and returns rows.
-- The rows are NOT active records.
------------------------------------
function active_record:query(query, filter)

  local db = sqlite3.open(self.connection_string)
  local stmt = db:prepare(query)

  assert(type(stmt)~="nil", "Statement: "..query.." not prepared.")

  if type(filter)=="table" then
    stmt:bind_names(filter)
  end
  local rows={}
  local c=0
  for row in stmt:nrows() do
    c=c+1
    row.__row_id=c
    table.insert(rows,row)
  end

  stmt:finalize()
  db:close()

  return table.new(rows)
end

------------------------------------
-- active_record.get_schema
--
-- returns the schema info for a table.
------------------------------------
function active_record:get_schema(table_name)
  -- get the table schema
  local db = sqlite3.open(self.connection_string)
  local stmt = db:prepare("PRAGMA table_info('"..table_name.."')")

  local exists=false
  local schema = {}
  for row in stmt:nrows() do
    exists=true
    schema[row.name]=row	-- to enable iteration via pairs
    table.insert(schema, row)	-- to enable iteration via ipairs
  end
  stmt:finalize()
  db:close()

  -- get the PK and concurrency fields
  local special={}
  for i, v in ipairs(schema) do 
    if v.pk ==1 then special.key = v.name end
    if v.dflt_value=="CURRENT_TIMESTAMP" then special.concurrency = v.name end
  end

  assert(exists, "Table: "..table_name.." has no schema. Table may not exist.")
  return schema, special.key, special.concurrency
end

------------------------------------
-- active_record.get_metatable
--
-- returns a metatable which can
-- be added to tables to make them
-- active records.
------------------------------------
function active_record:get_metatable(table_name, mode)
  local schema, key, concurrency = self:get_schema(table_name)
  local mt = {}
  mt.schema = schema
  mt.table_name = table_name
  mt.key = key
  mt.concurrency = concurrency
  mt.mode = mode
  mt.__index = self
  return mt
end

------------------------------------
-- active_record.create
--
-- creates a new active record.
------------------------------------
function active_record:create(table_name)
  local mt = self:get_metatable(table_name, "CREATE")
  return setmetatable({}, mt)
end

------------------------------------
-- active_record.delete
--
-- deletes active record(s).
------------------------------------
function active_record:delete(table_name, filter)
  filter = table.new(filter)
  
  local sql = 'DELETE FROM "'..table_name..'"'
  if type(filter)=="table" and filter:any() then
    sql = sql.." WHERE "..filter:map(
      function(k,v) return string.format('%s=:%s', k, k) end
    ):join(" AND ")
  end
  local db = sqlite3.open(self.connection_string)
  local stmt = db:prepare(sql)
  assert(type(stmt)~="nil", "Statement: ["..sql.."] not prepared.")
  if type(filter)=="table" then
    stmt:bind_names(filter)
  end
  stmt:step()
  stmt:finalize()
  db:close()
  return true
end

------------------------------------
-- active_record.save
--
-- saves an active record.
------------------------------------
function active_record:save()
  -- get metatable from active record
  local result = 0
  local mt = getmetatable(self)
  local fieldlist = {}
  local parameterlist = {}
  local updatelist={}
  local wherelist={}

  -- validate object before saving
--  for k,v in pairs(self) do
--    if mt[k]==nil then
--      error("Property "..k.." invalid for table "..mt.table_name)
--    end
--  end  

  for i,v in ipairs(mt.schema) do
    local field_name = mt.schema[i].name
    if (mt.mode=="CREATE" and field_name~=mt.concurrency) or
       (mt.mode=="EDIT" and field_name~=mt.key) then
      -- don't add concurrency on INSERTS
      -- dont' add key on UPDATES
      table.insert(fieldlist, field_name)
      table.insert(parameterlist, "?")
      table.insert(updatelist, field_name.."=?")
    end
    if field_name==mt.key or field_name==mt.concurrency then
      -- where clause includes key and concurrency
      table.insert(wherelist, field_name.."=?")
    end
  end

  local db = sqlite3.open(self.connection_string)
  local stmt
  local sql

  if mt.mode=="CREATE" then
    sql = "INSERT INTO "..mt.table_name.."("..table.concat(fieldlist,",")..") VALUES ("..table.concat(parameterlist,",")..")"
    stmt = db:prepare(sql)
    local i = 1
    for j,v in ipairs(mt.schema) do
      local field_name = mt.schema[j].name
      if field_name~=mt.concurrency then
        if v.type == "BLOB" then
          stmt:bind_blob(i, self[field_name])
        else
          stmt:bind(i, self[field_name])
        end
        i = i + 1
      end
    end
  else -- mt.mode=="EDIT" then
    sql = "UPDATE ["..mt.table_name.."] SET "..table.concat(updatelist,",").." WHERE "..table.concat(wherelist," AND ")
    stmt = db:prepare(sql)
    assert(stmt~=nil, "Cannot prepare statement: "..sql)
    local i = 1
    for j,v in ipairs(mt.schema) do
      local field_name = mt.schema[j].name
      if field_name~=mt.key then
        if v.type == "BLOB" then
          stmt:bind_blob(i, self[field_name])
        else
          stmt:bind(i, self[field_name])
        end
        i = i + 1
      end
    end
    stmt:bind(i, self[mt.key])
    if mt.concurrency then
      i = i + 1
      stmt:bind(i, self[mt.concurrency])
    end
  end

  result = stmt:step()
  stmt:reset()
  stmt:finalize()

  -- check success
  -- 101 = not an error
  assert(result == 101, db:error_message()..'<p />'..sql)
    
  local id = db:last_insert_rowid()
  db:close()
  return id
end

------------------------------------
-- active_record.exec
--
-- executes an arbitrary statement.
------------------------------------
function active_record:exec(sql, params)
  local db = sqlite3.open(self.connection_string)
  assert(type(db)~="nil", "Unable to open database to exec statement: "..sql)
  local stmt = db:prepare(sql)
  assert(type(stmt)~="nil", "Statement: ["..sql.."] not prepared.")
  if (params~=nil) then
    stmt:bind_names(params)
  end
  stmt:step()
  stmt:reset()
  stmt:finalize()
  db:close()
end

------------------------------------
-- active_record.exec_db
--
-- executes arbitrary statements.
------------------------------------
function active_record:exec_db(sql)
  local db = sqlite3.open(self.connection_string)
  db:exec(sql)
  local errcode = db:errcode()
  local errmsg = db:errmsg()
  db:close()
  return errcode, errmsg
end

return active_record
