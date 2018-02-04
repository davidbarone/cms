require "common"
require "response"
require "controller"

comment = controller.new({name="comment"})	-- create new table with base class of controller

function comment.get_default_status()
  -- get default comment status
  local default_comment_status = comment
    .active_record
    :read("configuration")
    :where(function(k,v) return v.co_key=="default_comment_status" end)
    :first()
    .co_value
  return default_comment_status
end

function comment.get(no_id)
  -- only include published comments
  local comments = comment.active_record:read("comment", {no_id=no_id, co_status="P"})
  return comments
end

function comment.add_POST(request)
  local row = comment.active_record:create("comment")
  row["no_id"] = request.params.id
  row["co_updated_by"] = "anonymous user"
  row["co_name"] = request.params.name
  row["co_email"] = request.params.email
  row["co_url"] = request.params.url
  row["co_status"] = comment.get_default_status()
  row["co_comment"] = request.params.comment
  row:save()
  return comment:redirect_response('/node/view?id='..request.params.id)
end

function comment.json_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local c = comment
    .active_record
    :query("SELECT n.no_id, n.no_title, c.co_id, c.co_email, c.co_comment, c.co_status, c.co_updated_ts, c.co_updated_by FROM comment c INNER JOIN node n on n.no_id = c.no_id")
  return comment:json_response(c)
end

function comment.admin_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  return comment:view_response("admin","layout")
end

return comment