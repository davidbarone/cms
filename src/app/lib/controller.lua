local common = require "common"
require "response"
local ajax = require 'json'
local active_record = require("active_record")
local slt2 = require("./lib/slt2/slt2")

controller = {}
common.class(controller)

controller.active_record = active_record.new({connection_string="./cms.sl3"})

-- used to send error back to ajax call
function controller:error_response()
  local r = self:content_response("Whoops")
  r.headers["Status"]="500 Server Error"
  return r 
end

function controller:unauthorised_response()
  local r = self:content_response("@section content{<div class='panel'><h1>Forbidden</h1>Access to this resource is forbidden.</div>}@", "layout")
  r.headers["Status"]="403 Forbidden"
  return r 
end

function controller:not_found_response()
  local r = self:content_response("<div class='panel'><h1>Not Found</h1>The requested resource was not found.</div>", "layout")
  r.headers["Status"]="404 Not Found"
  return r 
end

function controller:redirect_response(url)
  local r = self:content_response("")
  r.headers["Location"]=url
  r.status=302
  return r 
end

------------------------------------
-- render_template()
-- wrapper for slt2
--
-- if data is a string, then 
-- looks for @section name {...}@
------------------------------------
function controller:render_template(template, data)
  if type(template)~="string" then
    error "template must be a string value"
  end

  if type(data)=="table" then
    -- data is table, just apply template
    tmpl = slt2.loadstring(template)
    return slt2.render(tmpl, data)
  elseif type(data)=="string" then
    -- data is a string - look for sections
    local sections = {}
    -- look for sections marked @section name { ... }@
    local i,j,name,content = string.find(data, "@section%s*(%a+)%s*{(.-)}@")

    while i ~= nil do
      sections[name]=content
      i,j,name,content = string.find(data, "@section%s*(%a+)%s*{(.-)}@", i+1)
    end
    -- replace @rendersection... with #{= }# syntax for slt2
    template = string.gsub(template, '@rendersection%s*{%s*(%a+)%s*}@', '#{= %1}#')
    tmpl = slt2.loadstring(template)
    return slt2.render(tmpl, sections)
  end

end

-- views are in separate folder at same level as controllers.
function controller:view_response(view, layout, data)
  assert(view~=nil, "No view specified")
  data = data or {}
  local r = response.new()

  local str = io.file_read("./views/"..self.name.."/"..view..".vw")

  local pass1 = controller:render_template(str, data)
  local pass2 = pass1
  if layout~=nil then
    str = io.file_read("./views/"..layout..".vw")
    pass2 = controller:render_template(str, pass1)
  end
  r.content = pass2
  return r
end

function controller:content_response(content, layout)
  local r = response.new()
  r.content = content
  if layout~=nil then
    str = io.file_read("./views/"..layout..".vw")
    content = controller:render_template(str, content)
  end
  r.content = content
  return r
end

function controller:file_response(mime_type, data)
  local r = response.new()
  r.content = data
  r.headers["Content-Type"] = mime_type
  r.headers["Content-Length"] = #data
  return r
end

--------------------------------------
-- json_response
--
-- outputs to json format. Includes
-- optional page/size params to do 
-- paged output.
--------------------------------------
function controller:json_response(obj, page, size)
  local r = response.new()
  r.content = ajax.encode(obj, page, size)
  r.headers["Content-Type"] = "application/json"
  return r
end

return controller