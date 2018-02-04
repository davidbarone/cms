require "lsqlite3"
require "common"
require "response"
require "controller"
local security = require "security"

setup = controller.new({name="setup"})	-- create new table with base class of controller

function setup.index_GET(request)
  if io.file_exists("./cms.sl3") then
    error({code=403})
  else
    return setup:view_response("setup")
  end
end

function setup.index_POST(request)
  if io.file_exists("./cms.sl3") then
    error({code=403})
  end

  r = response.new()  
  
  if not io.file_exists("./cms.sl3") then
    local db = sqlite3.open("./cms.sl3")
    db:close()

    --------------
    -- holds configuration
    --------------
    setup.active_record:exec [[
      CREATE TABLE configuration (
        co_key TEXT NOT NULL PRIMARY KEY,
        co_value TEXT NOT NULL,
        co_comment TEXT NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_configuration_co_key on configuration (co_key);
    ]]

    setup.active_record:exec [[INSERT INTO configuration (co_key, co_value, co_comment) SELECT 'comments_days','0', 'Number of days for which comments can be entered';]]
    setup.active_record:exec [[INSERT INTO configuration (co_key, co_value, co_comment) SELECT 'page_size','5', 'Page size';]]
    setup.active_record:exec [[INSERT INTO configuration (co_key, co_value, co_comment) SELECT 'default_comment_status','D', 'Default comment status';]]
 
    --------------
    -- holds users
    --------------
    setup.active_record:exec [[
      CREATE TABLE user (
        us_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        us_email TEXT NOT NULL,
        us_name TEXT NOT NULL,
        us_salt TEXT NOT NULL,
        us_hash TEXT NOT NULL,
        us_algorithm TEXT NOT NULL,
        us_token TEXT,
        us_token_expiry_ts INTEGER,
        us_status TEXT NOT NULL,  -- D/P/X
        us_updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
        us_updated_by TEXT NOT NULL DEFAULT 'SYSTEM'
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_user_us_name on user (us_name);
    ]]

    -- add administrator
    security.create_user(request.params.name, request.params.email, request.params.password)

    ---------------
    -- holds roles
    ---------------
    setup.active_record:exec [[
      CREATE TABLE role (
        ro_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        ro_name TEXT NOT NULL,
        ro_updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        ro_updated_by TEXT NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_role_ro_name on role (ro_name);
    ]]

    setup.active_record:exec [[INSERT INTO role (ro_name, ro_updated_by) VALUES ('admin','system');]]

    --------------------
    -- holds memberships
    --------------------
    setup.active_record:exec [[
      CREATE TABLE membership (
        me_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        us_id INTEGER NOT NULL,
        ro_id INTEGER NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_membership_us_id_ro_id on membership (us_id,ro_id);
    ]]

    -- add admin user to admin group
    setup.active_record:exec([[
      INSERT INTO membership (us_id, ro_id)
      SELECT  
        (SELECT us_id FROM user WHERE us_email = :email),
        (SELECT ro_id FROM role WHERE ro_name = 'admin')
    ]], {email=request.params.email})

    -----------------------------------
    -- holds creation dates for objects
    -----------------------------------
    setup.active_record:exec [[
      CREATE TABLE creation (
        cr_table TEXT NOT NULL,
        cr_id INTEGER NOT NULL,
        cr_created_by TEXT NOT NULL,
        cr_created_ts TIMESTAMP NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_creation_cr_table_cr_id on creation (cr_table,cr_id);
    ]]

    --------------
    -- holds nodes
    --------------
    setup.active_record:exec [[
      CREATE TABLE node (
        no_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, -- acts as version field as well.
        no_title TEXT NOT NULL,
        no_content TEXT NOT NULL,
        no_content_type TEXT NOT NULL,	-- HTML or MARKDOWN
        no_status TEXT NOT NULL,  -- D,P,X (Draft, Published, Deleted)
        no_updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        no_updated_by TEXT NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_node_no_title on node (no_title);
    ]]

    setup.active_record:exec [[
      CREATE TABLE node_category (
        nc_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        no_id TEXT NOT NULL,
        nc_category TEXT NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_node_category_no_id_nc_category on node_category (no_id,nc_category);
    ]]

    -----------------------------------------------------
    -- resources store all static files (js,jpeg,css etc)
    -----------------------------------------------------
    setup.active_record:exec [[
      CREATE TABLE resource (
        re_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, -- also acts as version field
        re_data BLOB NOT NULL,
        re_filename TEXT NOT NULL,
        re_media_type TEXT NOT NULL,
        re_status TEXT DEFAULT 'D',  -- D,P,X (Draft, Published, Deleted)
        re_updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        re_updated_by TEXT NOT NULL DEFAULT 'SYSTEM'
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_resource_re_filename on resource (re_filename);
    ]]

    --------------
    -- holds comments
    --------------
    setup.active_record:exec [[
      CREATE TABLE comment (
        co_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        no_id INT NOT NULL,
        co_email TEXT,
        co_url TEXT,
        co_comment TEXT NOT NULL,
        co_status TEXT NOT NULL,  -- D,P,X (Draft, Published, Deleted)
        co_updated_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        co_updated_by TEXT NOT NULL
      );
    ]]

    setup.active_record:exec [[
      CREATE UNIQUE INDEX idx_comment_no_id_co_updated_by_co_updated_ts on comment (no_id,co_updated_by,co_updated_ts);
    ]]

    -- get any default files in ./www folder and add as resources
    local resource_path = './/www//'
    local media_types = {
      js="application/javascript",
      html="text/html",
      jpg="image/jpg",
      gif="image/gif",
      css="text/css",
      png="image/png"
    }

    for _, file_name in ipairs(io.files_in_dir(resource_path)) do
      local file_path = string.lower(resource_path..file_name)
      local ext = io.file_ext(file_path)
      if io.file_exists(file_path) then
        local contents = io.file_read(file_path)
        if (contents) then
          local row = setup.active_record:create('resource')
          row["re_filename"] = file_name
          row["re_data"] = contents
          row["re_media_type"] = media_types[ext]
          row["re_updated_by"] = "SYSTEM"
          row:save()  
        end
      end
    end

    return setup:redirect_response("/node/admin")
--    return setup:content_response("The database has been created!")
  else
    return setup:view_response("setup")
  end

end

return setup
