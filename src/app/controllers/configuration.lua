require "common"
require "response"
require "controller"

configuration = controller.new({name="configuration"})	-- create new table with base class of controller

function configuration.json_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local c = configuration
    .active_record
    :query("SELECT * FROM configuration")
  return configuration:json_response(c)
end

function configuration.index_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  return configuration:view_response("index","layout")
end

function configuration.delete_POST(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local key = request.params.key
  configuration.active_record:delete("configuration",{co_key=key})
  return configuration:content_response("ok")
end

function configuration.create_POST(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local c = configuration.active_record:create("configuration")
  c["co_key"] = request.params.key
  c["co_value"] = ''
  c["co_comment"] = ''
  c:save()
  return configuration:content_response("ok")
end

function configuration.edit_POST(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local key = request.params.key
  local c = configuration.active_record:read("configuration", {co_key = key}):first()
  c["co_value"] = request.params.value
  c["co_comment"] = request.params.comment
  c:save()
  return configuration:view_response("index","layout")
end

return configuration