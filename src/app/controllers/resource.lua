require "common"
require "response"
require "controller"

resource = controller.new({name="resource"})

function resource.delete_GET(request)
  resource.active_record:delete('resource',{re_filename=request.params.filename})
  return resource:content_response('ok')
end

function resource.json_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local r = resource
            .active_record
            :read('resource')
            :map(
              function(k,v) return {filename=v.re_filename, thumbnail="<img style='width:20px; height:20px;' src='/resource/view?filename="..v.re_filename.."'></img>"} 
              end)

  return resource:json_response(r, request.params.page, request.params.size)
end

-- gets a resource
function resource.index_GET(request)
  if not security.is_in_role(request.user,"admin") then error({code=403}) end
  local r = resource.active_record:read('resource')
  return resource:view_response("index", "layout")
end

function resource.view_GET(request)
  local filename = request.params.filename
  local r = resource.active_record:query([[
SELECT *
FROM resource
WHERE re_id = (
  SELECT MAX(re_id) FROM resource where re_filename = :filename
)
]], {filename=filename}):first()
  return resource:file_response(r.re_media_type, r.re_data)
end

function resource.index_POST(request)

  if not security.is_in_role(request.user,"admin") then error({code=403}) end

  -- save file to resource table

  -- get file
  filename, media_type, data = resource._parse_input(request.environment.STDIN)

  -- see if record already exists?
  local row = resource.active_record:read('resource',{re_filename=filename}):first()
  if not row then
    row = resource.active_record:create('resource')
    row["re_filename"] = filename
  end

  -- save it
  row["re_data"] = data
  row["re_media_type"] = media_type
  row["re_updated_by"] = "system"
  row:save()  
  return resource:view_response("index", "layout", {message="Successfully loaded: "..filename.." as media type: "..media_type})

end

function resource._parse_input(input)
  -- multipart/form-data parser
  -- -----------------------------------------------------------------------
  -- The format of the message/ is:
  -- -----------------------------290161757304079827424649641
  -- Content-Disposition: form-data; name="uploader"; filename="emails.csv"
  -- Content-Type: text/csv
  --
  -- [content]
  --
  -- -----------------------------290161757304079827424649641

  -- get boundary
  local s,e = input:find("[^\r\n]+")
  local boundary = input:sub(s,e)

  -- get headers
  local t,u = input:find("\r\n\r\n", e+1)
  local header = input:sub(e+1, t-1)

  local x,y = input:find("\r\n"..boundary, u+1, true)
  local data = input:sub(u+1, x-1)

  -- parse headers
  _, _, filename, media_type = header:find(".*filename=\"(.+)\".*Content[-]Type[:]%s*(.*)")

  return filename, media_type, data

end


return resource
