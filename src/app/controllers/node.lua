require "common"
require "response"
require "controller"
require "comment"

node = controller.new({name="node"})	-- create new table with base class of controller

function node.index_GET(request)

  local page_size = node
    .active_record
    :read("configuration")
    :where(function(k,v) return v.co_key=="page_size" end)
    :first()
    .co_value

  local published_filter = "no_status = 'P'"
  local page = request.params.page or 0
  local offset = page * page_size
  local limit = page_size + 1 -- we grab one more to check for last page
  local category = request.params.category
  local archive = request.params.archive
  local nodes = nil

  if security.is_in_role(request.user, "admin") then
    published_filter = "1=1"
  end

  if type(archive)~='nil' then
    nodes = node.active_record:query([[
      SELECT
        n.*
      FROM
        node n
      WHERE
        no_parent_id IS NULL AND
        CASE strftime('%m', no_updated_ts)
        WHEN '01' THEN 'Jan'
        WHEN '02' THEN 'Feb'
        WHEN '03' THEN 'Mar'
        WHEN '04' THEN 'Apr'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'Jun'
        WHEN '07' THEN 'Jul'
        WHEN '08' THEN 'Aug'
        WHEN '09' THEN 'Sep'
        WHEN '10' THEN 'Oct'
        WHEN '11' THEN 'Nov'
        WHEN '12' THEN 'Dec'
        END || '-' || strftime('%Y', no_updated_ts) = $archive AND
        ]]..published_filter..[[
      ORDER BY no_updated_ts DESC
      LIMIT $limit OFFSET $offset
    ]], {archive = archive, limit = limit, offset = offset})
   elseif type(category) ~= "nil" then
    nodes = node.active_record:query([[
      SELECT
        n.*
      FROM
        node n
      INNER JOIN
        node_category nc
      ON
        n.no_id = nc.no_id AND
        nc.nc_category = $category
      WHERE
        no_parent_id IS NULL AND -- exclude child pages
        ]]..published_filter..[[
      ORDER BY no_updated_ts DESC
      LIMIT $limit OFFSET $offset
    ]], {category = category, limit = limit, offset = offset})
  else
    nodes = node.active_record:query("select * from node WHERE no_parent_id IS NULL AND "..published_filter.." ORDER BY no_updated_ts DESC LIMIT "..limit.." OFFSET "..offset)
  end

  -- loop through each node adding category string
  for _,n in ipairs(nodes) do
    local categories = node.get_categories(n.no_id)
    if categories then
      n.category_links = categories
        :map(function(k,v) return string.format("<a class='button small' href='/node/index?category=%s'>%s</a>", v.nc_category, v.nc_category) end)
        :join("&nbsp;")
    end  
  end

  local eof = 0
  if #nodes < limit then eof = 1 end

  -- remove extra 'last page' checking item
  if #nodes == limit then
    nodes[#nodes-1]=nil
  end

  return node:view_response("index", "layout", {nodes = nodes, table=table, string=string, category=category, page=page, eof=eof})
end

function node.admin_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  return node:view_response("admin", "layout")
end

function node.json_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local r = node.active_record:read('node')
--  for _,n in pairs(r) do
--    n.no_content = nil
--  end
  return node:json_response(r)
end

function node.edit_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local id = request.params.id
  local r = node.active_record:read("node", {no_id=id}, true):first()

  local categories = node.get_categories(r.no_id)
  if categories then
    r.category_string = categories
      :map(function(k,v) return v.nc_category end)
      :join(", ")
  end
  return node:view_response("edit", "layout", {action="edit", node=r})

end

function node.edit_POST(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local id = request.params.id
  local row = node.active_record:read("node",{no_id = id}):first()
  row["no_parent_id"] = request.params.parent
  row["no_title"] = request.params.title
  row["no_type"] = request.params.node_type
  row["no_content_type"] = request.params.content_type
  row["no_status"] = request.params.status
  row["no_teaser"] = request.params.teaser
  row["no_content"] = request.params.content
  row["no_head"] = request.params.head
  row["no_code"] = request.params.code
  row["no_style"] = request.params.style

  if request.user then
    row["no_updated_by"] = request.user.us_name
  end
  row:save()
  node.save_categories(id, request.params.categories)
  row = node.active_record:read("node",{no_id=id}):first()
  return node:redirect_response("/node/view?id="..id)
end

function node.view_GET(request)
  local id = request.params.id
  local r = node.active_record:read("node", {no_id=id})

  if not security.is_in_role(request.user, "admin") then
    r = r:where(function(k,v) return v.no_status=="P" end)
  end

  r = r:first()

  if not r then
    return node:not_found_response()
  end

  local comments = comment.get(id)
  local comments_days = node.active_record:read("configuration", {co_key="comments_days"}):first().co_value;
  local comments_enabled = node
    .active_record:query("select date(no_updated_ts, '"..comments_days.." days') > date('now') comments_enabled from node where no_id = "..r.no_id):first().comments_enabled

  -- categories
  local categories = node.get_categories(id)

  -- walk up chain from node to root, adding in parent content
  local parent_id = r.no_parent_id
  while parent_id ~= nil do
    -- categories obtained from parent node.
    categories = node.get_categories(parent_id)
    local parent = node.active_record:read("node",{no_id="10"}):first()
    parent_id = parent.no_parent_id 
    r.no_title = (parent.no_title).." - "..(r.no_title)
    r.no_content = (("<p>"..parent.no_content.."</p>") or "")..(r.no_content or "")
    r.no_style = (parent.no_style or "").." "..(r.no_style or "")
    r.no_head = (parent.no_head or "").." "..(r.no_head or "")
    r.no_code = (parent.no_code or "").." "..(r.no_code or "")
  end

  if categories then
    r.category_links = categories
      :map(function(k,v) return string.format("<a class='button small' href='/node/index?category=%s'>%s</a>", v.nc_category, v.nc_category) end)
      :join("&nbsp;")
  end  

  return node:view_response("view", "layout", {node=r, comments=comments, comments_enabled=comments_enabled, table=table, string=string})
end

function node.create_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local r = node.active_record:create("node") -- doesn't actually create. just placeholder
  r.no_title=nil
  r.no_parent_id = request.params.parent
  return node:view_response("edit", "layout", {action="create", node=r})
end

function node.create_POST(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local row = node.active_record:create("node")
  row["no_parent_id"] = request.params.parent
  row["no_title"] = request.params.title
  row["no_type"] = request.params.node_type
  row["no_content_type"] = request.params.content_type
  row["no_status"] = request.params.status
  row["no_teaser"] = request.params.teaser
  row["no_content"] = request.params.content
  row["no_head"] = request.params.head
  row["no_code"] = request.params.code
  row["no_style"] = request.params.style

  if request.user then
    row["no_updated_by"] = request.user.us_name
  else
    row["no_updated_by"] = "unknown"
  end
  local id = row:save()
  row = node.active_record:read("node",{no_id=id}):first()
  node.save_categories(id, request.params.categories)
  return node:redirect_response("/node/view?id="..id)
end

function node.categories_GET()
  local c = node
    .active_record
    :query("SELECT DISTINCT nc_category FROM node_category")
    :map(function(k,v) return v.nc_category end)
  return node:json_response(c)
end

function node.archives_GET()
  local a = node
    .active_record
    :query([[
SELECT DISTINCT
  strftime('%m%Y', no_updated_ts) month_key,
  CASE strftime('%m', no_updated_ts)
  WHEN '01' THEN 'Jan'
  WHEN '02' THEN 'Feb'
  WHEN '03' THEN 'Mar'
  WHEN '04' THEN 'Apr'
  WHEN '05' THEN 'May'
  WHEN '06' THEN 'Jun'
  WHEN '07' THEN 'Jul'
  WHEN '08' THEN 'Aug'
  WHEN '09' THEN 'Sep'
  WHEN '10' THEN 'Oct'
  WHEN '11' THEN 'Nov'
  WHEN '12' THEN 'Dec'
  END || '-' || strftime('%Y', no_updated_ts) month_desc
FROM node
ORDER BY
  no_updated_ts DESC;]])

  return node:json_response(a)

end


function node.save_categories(id, c)
  if type(c)=="string" or type(c)=="nil" then
    node.active_record:exec('delete from node_category where no_id = :id',{id=id})
  end

  if type(c)=="string" then
    local arr = c:split(',')
    for _, cat in pairs(arr) do
      local category = node.active_record:create('node_category')
      category['no_id'] = id
      category['nc_category'] = cat:trim()
      category:save()
    end
  end
end

function node.get_categories(id)
  return node.active_record:read("node_category",{no_id=id})
end

function node.get_siblings_GET(request)
  local id = request.params.id
  local n = node.active_record:read("node", {no_id=id}):first()
  local siblings = {}
  if n.no_parent_id then
    siblings = node
      .active_record
      :read("node", {no_parent_id = n.no_parent_id})
      :where(function(k,v) return v.no_id~=id and v.no_parent_id ~= nil end)
      :map(function(k,v) return {key=v.no_id, value=v.no_title} end)
  end
  return node:json_response(siblings)
end

function node.get_children_GET(request)
  local children = node
    .active_record
    :read("node", {no_parent_id = request.params.id})
    :where(function(k,v) return v.no_parent_id ~= nil end)
    :map(function(k,v) return {key=v.no_id, value=v.no_title} end)

  return node:json_response(children)
end

return node
