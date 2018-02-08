#!/usr/bin/lua
TEST
function main(environment)

  local status, result = pcall(
    function()
      package.path = package.path .. ";./controllers/?.lua;./lib/?.lua"
      require "common"
      require 'ext_table'
      require 'ext_string'
      require 'ext_io'
      require "controller"
      
      dispatcher = controller.new({name="dispatcher"})	-- create new table with base class of controller
      dispatcher.url = require 'socket.url'

      local security = require 'security' -- for authentication 

      if environment.HTTP_HOST == nil then
        error("No HTTP_HOST or DOCUMENT_URI set. Has this been invoked from web server?")
      else

	local scriptName = environment.SCRIPT_NAME
	local route = scriptName:split("/")

        if #route <= 1 or route[2] == "" then
          route[1] = ""
          route[2] = "node"
        end
 
        -- if script name only has 1 path (e.g. /setup), then add default
        -- path of ./index:
        if #route == 2 then
	  route[3] = "index"
        end

        if route[3] == "" then
          route[3] = "index"
        end

        local controllerName = route[2]
        local controller
	assert(pcall(function() controller = require(controllerName) end), "Controller: ["..controllerName.."] not found")

	-- HTTP type is appended to method name.
        -- eg: index_GET
        -- This allows for public/private methods in controller.
        local methodName = route[3].."_"..environment.REQUEST_METHOD

	-- build request
	local request = {
	  environment = environment,
          params = get_params(environment),
          cookies = get_cookies(environment) 
	}

        -- authenticate (check for token)
        if io.file_exists("./cms.sl3") then
          security.authenticate(request)
        end

        -- log
--	local l=table.new(environment):map(function(k,v) return "["..k.."]="..v end):join("\n")
--        io.file_write("./ws.log",l)

        if controller[methodName] ~= nil then
          r = controller[methodName](request)
        else
          error("Method: ["..methodName.."] not found for controller: ["..controllerName.."]")  
        end

        return r

      end
    end
  )

  if (status) then
    -- OK
    http_content = result:getHttpString() 
    if http_content then
      return http_content
    else
      return "content-type: text/html\n\nNull Content!"
    end
  else
    if result then
      if result.code == 403 then
          return dispatcher:unauthorised_response():getHttpString()
      else
        -- any server side error thrown will
        -- be stored in result var. This
        -- returned as status 501
        return "Status: 501"..result.."\n\n"..result 
      end
    else
      return "Status: 502 Null Content\n\nNull Content"
    end
  end

end

-- parses HTTP_COOKIE as well...
function get_cookies(environment)
  local out = {}
  local cookie_str=""
  if environment.HTTP_COOKIE ~= nil then cookie_str = environment.HTTP_COOKIE end
  local cookies = cookie_str:gmatch("[^;]+")
  for cookie in cookies do
    local key, value = cookie:match('([^=]+)=(.+)')
    value = dispatcher.url.unescape(value)
    if tonumber(value)~=nill then value = tonumber(value) end
    out[key] = value
  end
  return out
end
---------------------------------------------
-- get_params
--
-- parses query string in format:
-- a=b&c=d&e=f etc.
-- results put into table
---------------------------------------------
function get_params(environment)
  local out = {}
  local param_str=""

  -- get STDIN
  
  environment.STDIN = io.read("*a")

--  error(environment.STDIN)
  
  -- GET params in query string
  if environment.REQUEST_METHOD=="GET" and environment.QUERY_STRING ~= nil then
    param_str=environment.QUERY_STRING
  elseif environment.REQUEST_METHOD=="POST" and environment.CONTENT_TYPE=="application/x-www-form-urlencoded" then
    param_str=environment.STDIN
  end

  local params = param_str:gmatch("[^&]+")
  for param in params do
    local key, value = param:match('([^=]+)=([^=]+)')
    if value then
      value = string.gsub(value, "+", " ")
      value = dispatcher.url.unescape(value)
      if tonumber(value)~=nil then value = tonumber(value) end
      out[key] = value
    end
  end

  return out  
end

function bootstrap(arg)
  local environment = {}
  if #arg > 0 then
    environment.QUERY_STRING = arg[1]
  else
    environment.QUERY_STRING = os.getenv("QUERY_STRING") or ""
  end

  environment.REQUEST_METHOD = os.getenv("REQUEST_METHOD") or "GET"
  environment.CONTENT_TYPE = os.getenv("CONTENT_TYPE") or ""
  environment.HTTP_COOKIE = os.getenv("HTTP_COOKIE") or ""
  environment.HTTP_HOST = os.getenv("HTTP_HOST") or""
  environment.HTTP_REFERER = os.getenv("HTTP_REFERER") or ""
  environment.DOCUMENT_URI = os.getenv("DOCUMENT_URI") or ""
  environment.SCRIPT_NAME = os.getenv("SCRIPT_NAME") or ""

  -- modify environment variables to take into account url rewriting.
  local pos = environment.QUERY_STRING:find("?")
  if pos then
    environment.SCRIPT_NAME = "/"..string.sub(environment.QUERY_STRING,1,pos-1)
    environment.QUERY_STRING = string.sub(environment.QUERY_STRING,pos+1,9999)
  else
    environment.SCRIPT_NAME = "/"..environment.QUERY_STRING
    environment.QUERY_STRING = ""
  end

  return main(environment)
end

io.stdout:write(bootstrap(arg))
