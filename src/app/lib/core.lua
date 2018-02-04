----------------------------------------------------------
-- core.lua
--
-- all core functions.
----------------------------------------------------------

local slt2 = require('slt2')

local common={}

----------------------------------------------------
-- function class()
--
-- Turns a table into a 'class-like' object where
-- methods / functions on the base table can be
-- used.

-- creates new + copy constructors on
-- regular objects
-- http://lua-users.org/wiki/LuaClassesWithMetatable
--
-- By turning a table into a 'class' we set meta
-- tables enabling base 'table' methods to be used
-- on the 'child' table (in a similar fashion to
-- creating an object based on a class).
----------------------------------------------------
function common.class(members)
  members = members or {}
  local mt = {
    __metatable = members;
    __index     = members;
  }
  local function new(init,params)
    local obj=init or {}
    if getmetatable(obj)~=members then
      local obj = setmetatable(obj, mt)
    end
    if type(params)=="table" then
      for k,v in pairs(params) do
        obj[k] = v
      end
    end
    return obj
  end
  local function copy(obj, ...)
    local newobj = obj.new(unpack(arg))
    for n,v in pairs(obj) do newobj[n] = v end
    return newobj
  end
  members.new  = members.new  or new
  members.copy = members.copy or copy
  return mt
end



-----------------------------------------
-- io functions (extension methods / mixins)
-----------------------------------------

-----------------------------------------
-- io.file_ext(path)
-----------------------------------------
function io.file_ext(path)
  local ext = nil
  for e in path:gmatch("[.]([^.]*)") do ext = e end
  return ext
end

-----------------------------------------
-- io.files_in_dir(dir)
-----------------------------------------
function io.files_in_dir(dir)

    local i, t, popen = 0, {}, io.popen
    for filename in popen('ls "'..dir..'"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t

--    local tmp = os.tmpname()
--    os.execute("ls "..dir.." > "..tmp)
--    local f = io.open(tmp, "r")
--    local t = {}
--    for filename in f:lines() do
--      table.insert(t, filename)
--    end
--    f:close()
--    return t
end

-----------------------------------------
-- io.file_exists(name)
-----------------------------------------
function io.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

-----------------------------------------
-- io.file_write(file, text)
-----------------------------------------
function io.file_write(file, text)
  local f=io.open(file, "w")
  f:write(text)
  f:close()
end

-----------------------------------------
-- io.file_read(file)
-----------------------------------------
function io.file_read(file)
  local f = io.open(file,"r")
  if f == nil then
    error("Unable to open file: "..file)
  end
  local s = f:read("*a")
  f:close()
  return s
end



-----------------------------------------
-- string functions (extensions, mixins)
-----------------------------------------

-----------------------------------------
-- string:markdown()
--
-- blank lines converted to paragraph
-- underline (=) converted to <h1>
-- underline (-) converted to <h2>
-- '*..*' around a word means emphasis (<em>)
-- '**..**' around a word means strong emphasis (<strong>)
-- '-' at start of line means unordered list
-- '1.' at start of line means ordered list
-- !url! = image
-- simple urls without spaces automatically converted to hyperlink
-- #url# = hyperlink
-----------------------------------------
function string:markdown()
  local lines = self:split('\n')
  local ulist_start = 0
  local olist_start = 0
  local match=""
  for i=1, #lines, 1 do
    lines[i] = lines[i]:html_escape()
    if lines[i] == nil then lines[i] = " " end

    -- match image
    lines[i] = string.gsub(lines[i], "[!]([^!]*)[!]", "<img src=\"%1\">")

    -- match url
    local url_pattern = "(%s)(https?://[%w-_%.%?%.:/%+=&]+)(%s)"
    lines[i] = string.gsub(lines[i], url_pattern, "%1<a href='%2'>%2</a>%3")
    local url_pattern = "#(https?://[%w-_%.%?%.:/%+=&]+)#"
    lines[i] = string.gsub(lines[i], url_pattern, "<a href='%1'>%1</a>")

    -- match emphasis
    lines[i] = string.gsub(lines[i], "%*%*([^*]*)%*%*", "<strong>%1</strong>")
    lines[i] = string.gsub(lines[i], "[*]([^*]*)[*]", "<em>%1</em>")

    -- match double underline
    if string.sub(lines[i],1,2)=="==" then
      lines[i-1]=string.format("<h1>"..lines[i-1].."</h1>")
      lines[i]=""
    end

    -- match double underline
    if string.sub(lines[i],1,2)=="--" then
      lines[i-1]=string.format("<h2>"..lines[i-1].."</h2>")
      lines[i]=""
    end

    if string.sub(lines[i],1,1)==">" then
      lines[i-1]=string.format("<blockquote>"..lines[i-1].."</blockquote>")
      lines[i]=""
    end

    -- match "- "
    match = string.match(lines[i], "^[-]%s*")
    if match ~= nil then
      if ulist_start==0 then
        lines[i]="<ul><li>"..string.sub(lines[i], string.len(match)+1).."</li>"
        ulist_start=i
      else
        lines[i]="<li>"..string.sub(lines[i], string.len(match)+1).."</li>"
      end
    else
      if ulist_start > 0 then
        lines[i-1]=lines[i-1].."</ul>"
        ulist_start = 0
      end
    end

    -- match "1. xxx"
    match = string.match(lines[i],"^%d+[.]")
    if match ~= nil then
      if olist_start==0 then
        lines[i]="<ol><li>"..string.sub(lines[i], string.len(match)+1).."</li>"
        olist_start=i
      else
        lines[i]="<li>"..string.sub(lines[i], string.len(match)+1).."</li>"
      end
    else
      if olist_start > 0 then
        lines[i-1]=lines[i-1].."</ol>"
        olist_start = 0
      end
    end
  end
  local s = table.concat(lines, "\n")
  s = string.gsub(s, "\r", "")
  s = string.gsub(s, "\n\n+", "<p></p>")
  s = string.gsub(s, "%s+", " ")
  return s
end

-----------------------------------------
-- string:html_escape()
-----------------------------------------
function string:html_escape()
  if type(self)=="string" then
    local entities = {}
--  entities["&"] = "&amp;"
    entities["<"] = "&lt;"
    entities[">"] = "&gt;"
    entities['"'] = "&quot;"
    entities["'"] = "&#39;"
--  entities["/"] = "&#x2F;"
    for k, v in pairs(entities) do
      self = string.gsub(self, k, v)
    end
    return self
  end
end

-----------------------------------------
-- string:trim()
-----------------------------------------
function string:trim()
  return (self:gsub("^%s*(.-)%s*$", "%1"))
end

-----------------------------------------
-- string:split(delimiter)
-----------------------------------------
function string:split(delimiter)
        local result = { }
        local from  = 1
        local delim_from, delim_to = string.find( self, delimiter, from  )
        while delim_from do
                table.insert( result, string.sub( self, from , delim_from-1 ) )
                from  = delim_to + 1
                delim_from, delim_to = string.find( self, delimiter, from  )
        end
        table.insert( result, string.sub( self, from  ) )
        return result
end



-----------------------------------------
-- table extensions / mixins
-----------------------------------------
common.class(table)

-----------------------------------------
-- table:any()
--
-- returns true if table has any members
-----------------------------------------
function table:any()
  local c = #self
  if c==0 then
    for k,v in pairs(self) do c=c+1 break end
  end
  if c > 0 then return true else return false end
end

-----------------------------------------
-- table:count()
--
-- returns number of integer and hash keys
-----------------------------------------
function table:count()
  local c = 0
  for k,v in pairs(self) do c=c+1 end
  return c
end

-----------------------------------------
-- table:map()
--
-- iterates through a table applying a
-- map function. The map function must
-- accept k, v parameters.
-----------------------------------------
function table:map(func)
  assert(type(func)=="function", "Must pass a function into map function.")
  local out = table.new()
  for k, v in pairs(self) do
    out[k]=func(k, v)
  end
  return out
end

-- alias
table.each = table.map

-----------------------------------------
-- table:values()
--
-- Returns all values in a table structure
-- whether array or dictionary type.
-----------------------------------------
function table:values()
  local out = table.new()
  for k, v in pairs(self) do
    table.insert(out, v)
  end
  return out
end

-----------------------------------------
-- table:join()
--
-- concatenates values in a table using
-- string separator s
-----------------------------------------
function table:join(s)
  return table.concat(self:values(), s)
end

-----------------------------------------
-- table:first()
--
-- returns first member in table, or nil
-----------------------------------------
function table:first(func)
  local a = self
  if (type(func)=="function") then
    a = a:where(func)
  end
  local row = nil
  for i, v in ipairs(a) do
    row = v
    break
  end
  return row
end

-----------------------------------------
-- table:clone()
--
-- returns first member in table, or nil
-----------------------------------------
function table:clone(t)
  for i,v in ipairs(self) do
    table.insert(t, v)
  end
end

-----------------------------------------
-- table:where()
--
-- iterates through a table, filtering members
-- based on functor
-----------------------------------------
function table:where(func)
  assert(type(func)=="function","Must pass a function which accepts k,v parameters and returns boolean")
  local out = table.new()
  for k,v in pairs(self) do
    if func(k, v)==true then table.insert(out, v) end
  end
  return out
end

-----------------------------------------
-- table:iunion()
--
-- merges an integer based table with another
-- integer based table.
-----------------------------------------
function table:iunion(t)
  for i, v in ipairs(t) do
    table.insert(self, v)
  end
  return self
end

-----------------------------------------
-- table:distinct()
--
-- returns distinct members in a table.
-----------------------------------------
function table:distinct()
  local out=table.new()
  for k,v in pairs(self) do
    out[v]={}
  end
  return out:map(function(k,v) return k end) 
end

-----------------------------------------
-- table:indexof()
--
-- returns distinct members in a table.
-----------------------------------------
function table:indexof(value)
  for i,v in ipairs(self) do
    if v==value then return i end
  end
  return nil
end

-----------------------------------------
-- table:orderby()
--
-- returns distinct members in a table.
-----------------------------------------
function table:order(func)
  table.sort(self, func)
  return self
end

-----------------------------------------
-- table:intersect()
--
-- returns members of table 1 that are in table 2.
-- NOT OPTIMISED!
-----------------------------------------
function table:intersect(t)
  local out = table.new()
  local t1 = self:values():order()
  local t2 = t:values():order()
  local k1=1
  local k2=1
  while k1<=#t1 and k2<=#t2 do
    if t1[k1]==t2[k2] then
      table.insert(out, t1[k1])
      k1=k1+1
      k2=k2+1
    elseif t1[k1]<t2[k2] and k1<#t1 then
      k1=k1+1
    elseif t1[k1]>t2[k2] and k2<#t2 then
      k2=k2+1
    else
      break
    end
  end
  return out
end

-----------------------------------------
-- table:to_json()
--
-- returns members of table 1 that are in table 2.
-- NOT OPTIMISED!
-----------------------------------------
function table:to_json()
  local out={}
  if #self==0 then
    for k,v in pairs(self) do
      local value=v
      if type(v)=="string" then
        value="\""..v.."\""
      elseif type(v)=="table" then
        value=table.new(v):to_json()
      end
      table.insert(out, "\""..k.."\""..":"..value)
    end  
    return "{"..table.concat(out, ",").."}"
  else
    for i,v in ipairs(self) do
      table.insert(out, table.new(v):to_json())
    end
    return "["..table.concat(out, ",").."]"
  end
end

-----------------------------------------
-- table:page()
--
-- takes a page of a table
-----------------------------------------
function table:page(skip, take)
  local out=table.new()
  for i, v in ipairs(self) do
    if i >= skip and i<= skip+take then
      table.insert(out, v)
    end
  end
  return out
end


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

json = {}

function json.escape(s)
  local escape = {
    -- for time being, just add these for bare minimum...
--    {'\',"\\"},
    {'"','\\"'},
    {'\n',"\\n"},
    {'\r',"\\r"},
    {'/',"\/"},
    {'\b',"\\b"},
    {'\f',"\\f"},
    {'\t',"\\t"}
  }

  for _,v in pairs(escape) do
    s = s:gsub(v[1],v[2])
  end

  return s
end


function json.encode_table(t)

  function escape()

  end

  assert(type(t)=="table", "Must be a table object to encode.")
  local out={}
  if #t==0 then
    for k,v in pairs(t) do
      local value=v
      if type(v)=="string" then
        value="\""..json.escape(v).."\""
      elseif type(v)=="table" then
        value=json.encode_table(v)
      elseif type(v)=="nil" then
        value=""
      end
      table.insert(out, "\""..k.."\""..":"..value)
    end  
    return "{"..table.concat(out, ",").."}"
  else
    for _,v in ipairs(t) do
      local value=v
      if type(v)=="string" then
        value="\""..json.escape(v).."\""
      elseif type(v)=="table" then
        value=json.encode_table(v)
      elseif type(v)=="nil" then
        value=""
      end
      table.insert(out, value)
    end  
    return "["..table.concat(out, ",").."]"
  end
end

function json.encode(obj, page, size)
  local paged = obj
  if page and size then
    paged = table.new(obj):page((page-1)*size, size)
  end

  return_obj = {
    page = page or 1,
    size = size or 99999999,
    rows = #obj,
    data = paged
  }
  
  return json.encode_table(return_obj)
end

-- TEST
--local obj = {}
--obj.id = 123
--obj.name = "david"
--obj.days = {
--  {day=1, name="monday"},
--  {day=2, name="tuesday"},
--  {day=3, name="wednesday"}
--}
--print (json.encode(obj))


-------------------------------
-- RESPONSE
-------------------------------

-- abstracts the response

-- table representing the class, which will double as metadata table for instances
response = {} 

response.__index = response	-- failed table lookups should fall back to response table to get methods

function response.new(o)
  o = o or {}
  local self = setmetatable(o, response)

  -- defaults
  self.status = 200
  self.headers = {}
  self._cookies = {}

  self.headers["Content-Type"]="text/html"
  return self
end

function response: set_cookie(name, value, expires)
  table.insert(self._cookies,{
    name = name,
    value = value,
    expires = expires
  }) 
end

function response:setStatus(status)
  self.status = status
end

function response:setContent(content)
  self.content = content
end

function response:getHttpString()
  local http = "HTTP/1.1 "..self.status.."\n"
  local hdr = table.map(self.headers,function(k,v) return string.format("%s:%s",k,v) end)
  hdr = table.values(hdr)

  local cookies = table.map(self._cookies, function(k, v) 
    return string.format("Set-Cookie: %s=%s; path=/", v.name, v.value)
  end)

  cookies = table.values(cookies)
  for i, v in ipairs(cookies) do
    table.insert(hdr, v)
  end

  http = http..table.concat(hdr,"\n")
  http = http.."\n\n"..self.content
  return http

end







return {
    json = json,
    common = common,
    template = slt2,
    response = response
}