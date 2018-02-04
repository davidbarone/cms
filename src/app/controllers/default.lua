require "common"
require "response"
require "controller"

default = controller.new({name="default"})	-- create new table with base class of controller

function default.index(request)
  return default:view_response("index", "layout")
end

return default