require "controller"
local md5 = require 'md5'
local mime = require("mime")

security = controller.new({name="security"})

function security.login_GET(request)
  return security:view_response("login")
end

function security.status_GET(request)
  if request.user==nil then
    return security:view_response("login")
  else
    return security:view_response("logout", nil, {name=request.user.us_name})
  end
end

function security.is_in_role(user, roles)
  local r={}
  if type(roles)=="string" then
    r = table.new(roles:split(","))
  else
    r = table.new(roles)
  end

  -- rules
  -- if request.user exists and has role 'admin' then true
  -- if request.user exists and contains one of the roles in 'roles' then true
  -- else false
  if user then
    local i = user.roles:intersect(r)
    if #i > 0 then return true
    else return false
    end
  else
    return false
  end
end

--------------------------------
-- function authenticate
--
-- called by dispatcher
--------------------------------
function security.authenticate(request)
  -- check token cookie present?
  if request.cookies.token~=nil then
    local f = {}
    f.us_token=request.cookies.token
    local u = security.active_record:read("user", f):first()
    if u then
      -- check expiry in future
      local r = security.active_record:query("SELECT datetime('now') < :token_exp exp",{token_exp=u.us_token_expiry_ts}):first()
      if r.exp == 1 then
        request.user = u
        -- advance token expiry to 20 mins from now
        --local exp = security.active_record:query("select datetime('now', '+20 minute') AS expiry_date"):first()
        --u.us_token_expiry_ts = exp.expiry_date
        --u:save()
        -- get roles
        request.user.roles = security
          .active_record
          :query("SELECT ro_name FROM role r INNER JOIN membership m ON m.ro_id = r.ro_id and m.us_id = :us_id",{us_id = u.us_id})
          :map(function(k,v) return v.ro_name end)
        return true
      else
        -- token expired. Not authenticated
        u.us_token=nil
        u.us_token_expiry_ts=nil
        u:save()
        return false   
      end
    end
  end
  return false
end

function security.logout_POST(request)
  local referer = request.environment.HTTP_REFERER
  local u = security.active_record:read("user",{us_email=request.user.us_email}):first()
  if u then
    -- log user out
    u.us_token=nil
    u.us_token_expiry_ts=nil
    u:save()    
  end
  return security:redirect_response(referer)
end

function security.login_POST(request)
  local referer = request.environment.HTTP_REFERER
  assert(not request.user, "Already logged in!")
  local result = false
  -- validate credentials
  local u = security.active_record:read("user", {us_email=request.params.email}):first()
  if u then
    if mime.b64(md5.sum(request.params.password.. u.us_salt))==u.us_hash then
      -- valid: get token
      local frandom = assert(io.open("/dev/random","r"))
      u.us_token = mime.b64(frandom:read(16))
      frandom:close()

      local exp = security.active_record:query("select datetime('now', '+60 minute') AS expiry_date"):first()
      u.us_token_expiry_ts = exp.expiry_date
      u:save()
      
      -- set user
      u = security.active_record:read("user",{us_email=request.params.email}):first()
      request.user = u
      result = true
    end
  end

  if result then
    local v = security:redirect_response(referer)
    v:set_cookie("token",u.us_token)
    return v
  else
    return security:redirect_response(referer)
  end
end

function security.create_user_GET(request)
  return security:view_response("create_user")
end

-- this function is also called by setup controller
function security.create_user(name, email, password)
  local user = security.active_record:create("user")
  -- salt
  local frandom = assert(io.open("/dev/random","r"))
  local salt = mime.b64(frandom:read(16))
  frandom:close()

  user["us_name"] = name
  user["us_email"] = email
  user["us_salt"] = salt
  user["us_algorithm"] = 'md5'
  user["us_hash"] = mime.b64(md5.sum(password..salt))
  user["us_status"] = 'P'
  user["us_updated_by"] = 'SYSTEM'
  user:save()
end

function security.create_user_POST(request)
  security.create_user(
    request.params.name,
    request.params.email,
    request.params.password);
  return security:content_response("user created")
end

return security