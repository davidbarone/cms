require 'common'
require 'ext_table'
local builder = require 'builder'
local active_record = require 'active_record'

conf = {
  settings = {
    bitmap_cardinality_threshold=100
  },
  tables={
    order_details={key="", query="SELECT OrderID,ProductID,Quantity,UnitPrice,quantity*unitprice as Amt from [order details]"},
    orders={key="orderid", query="SELECT orderid,customerid,date(orderdate) as OrderDate FROM orders"},
    customer={key="customerid", query="SELECT customerid,companyname,country FROM customers"},
    product={key="productid", query="SELECT * FROM products"},
    category={key="categoryid", query="SELECT * FROM categories"},
    time={key="d", query="SELECT d, dn, ym, ymn, y FROM dates"}
  },
  joins={
    {t1="order_details", c1="OrderID", t2="orders", c2="OrderID", type="m1"},
    {t1="order_details", c1="ProductID", t2="product", c2="ProductID", type="m1"},
    {t1="orders", c1="CustomerID", t2="customer", c2="CustomerID", type="m1"},
    {t1="orders", c1="OrderDate", t2="time", c2="d", type="m1"}
  },
  dimensions={
    --date={key={t="time", c="d"},label={t="time", c="d"}},
    --month={key={t="time", c="ymn"}, label={t="time", c="ymn"}},
    --year={t="time", c="y"},
    order={t="orders", k="OrderID", v="OrderID"},
--    customer={t="customer", k="CustomerID", v="CompanyName"},
    country={t="customer", k="CustomerID", v="Country"},
    product={t="product", k="ProductID", v="ProductName"}
--    category={t="product", k="ProductID", v="CategoryName"}
  },
  measures={
    orderamt={t="order_details", c="Amt"}
  },
  calculations={}
}


function process(build, query)
  local cells = nil

  -- layout dimensions
  print("Laying out dimensions")
  for _,v in ipairs(query.dimensions) do
    local keys = build.dimensions[v]:map(function (k,v) return v.k end)
    print("Member count:"..keys:count())
    cells = table.dim_cross_join(cells, keys)
  end

  print("Loop through cells, calculating values")
  -- loop through dimensions, evaluating measures
  for k,cell in pairs(cells) do
    cell.value = 0
    cell.dimensions=query.dimensions
    cell.context = k
    process_cell(build, cell, "sum(amt)")
  end

  print("Printing Results")
  local results = {}
  for k,v in pairs(cells) do
    local formatted = format_cell(v, build)
    table.insert(results, formatted)
  end
  print(table.new(results):to_json())
end

function format_cell(cell, build)
  local out = {}
  for i=1, #cell.dimensions, 1 do
    local dim = cell.dimensions[i]
    out[dim]=build.dimensions[dim][cell.context[i]].v
  end
  out.value = cell.value
  return out
end

function binary_search(index, key, min, max)
  if (max<min) then
    -- not found
    return nil
  else
    local mid = (min+max)/2
    if index[math.floor(mid)].value > key then
      return binary_search(index, key, min, mid-1)
    elseif index[math.floor(mid)].value < key then
      return binary_search(index, key, mid+1, max)
    else
      return mid
    end     
  end
end


function process_cell(build, cell, calculation)
  -- for time being, assume calculation is sum(amt)
  local facts = build.measures["orderamt"]
  local seek_rows={}
  for i=1, #cell.dimensions, 1 do
    local dim_name = cell.dimensions[i]
    local key_value = cell.context[i]
    local index = build.indexes["order_details"][dim_name]
    local search_index = binary_search(index, key_value, 1, #index)
    if search_index then
      search_index = math.floor(search_index)
	    seek_rows[#seek_rows+1]=index[search_index].rowid
	    -- now get all rows up to this
	    local tmp = search_index
	    while true do
	      tmp=tmp-1
	      local val=index[tmp].rowid
	      if val~=key_value or tmp<=0 then break end
	      seek_rows[#seek_rows+1]=val
	    end
	    tmp = search_index
	    while true do
	      tmp=tmp+1
	      local val=index[tmp].rowid
	      if val~=key_value or tmp > #seek_rows then break end
	      seek_rows[#seek_rows+1]=val
	    end
      end
  
--    local sr = build.indexes["order_details"][dim_name]
--      :where(function(k,v) return v.value==key_value end)
--      :map(function(k,v) return v.rowid end)
--    if i==1 then seek_rows=sr else seek_rows=seek_rows:intersect(sr) end
  end

  for _,v in ipairs(seek_rows) do
    cell.value=(cell.value or 0) + (build.measures["orderamt"][v] or 0)    
  end

--  local rows = process_get_rows(cube, index)
--  local amt = process_eval(rows, "test")
--  context.value=amt	-- cell value
end






function table.dim_cross_join(dim1,dim2)
  if not dim1 then
    out=table.new()
    for k,v in pairs(dim2) do
      out[table.new({k})]={}
    end
    return out
  elseif not dim2 then
    out=table.new()
    for k,v in pairs(dim1) do
      out[table.new({k})]={}
    end
    return out
  end
  -- otherwise, do cross join
  local out = table.new()
  for k1,v1 in pairs(dim1) do
    for k2, v2 in pairs(dim2) do
      local key = {}
      local indexes = {}
      if type(k1)=="table" then
        for k3,v3 in pairs(k1) do
          table.insert(key,v3)
        end
        for k3,v3 in pairs(v1) do
          table.insert(indexes, v3)
        end
      else
        table.insert(key,k1)
        table.insert(indexes,v1)
      end
      table.insert(key, k2)
      table.insert(indexes, v2)
      out[key]=indexes
    end
  end
  return out
end

local start = os.time()
function stop_watch()

  local a = "Seconds: "..(os.time() - start)
  start=os.time()
  return a

end




function process_get_rows(cube, index)

  local facts = cube.source[conf.facts.table]
  local out = {}
  local read=false
  local c=1
  for i=1,#index,1 do
    if read then
      for j=1,index[i],1 do
        table.insert(out, facts[c+j-1])
      end
    end
    c=c+index[i]
    read = not read        
  end
  return out

end




function index_join(i1, i2)
  if #i1 == 0 then return i2 end
  if #i2 == 0 then return i1 end
  local p1 = 1
  local p2 = 1
  local cf = 1
  local state1=false
  local state2=false
  local state=false
  local next1 = i1[p1]
  local next2 = i2[p2]
  local index={}
  local current_jump=0
  while true do
    local min_jump = math.min(next1,next2)
    current_jump = current_jump + min_jump
    next1=next1-min_jump
    next2=next2-min_jump
    if next1==0 then
      p1=p1+1
      if p1>#i1 then break end
      next1=i1[p1]
      state1=not(state1)
    end
    if next2==0 then
      p2=p2+1
      if p2>#i2 then break end
      next2=i2[p2]
      state2=not(state2)
    end
    local new_state = state1 and state2
    if new_state~=state then
      table.insert(index,current_jump)
      state=new_state
      current_jump=0
    end
  end
  --final one
  table.insert(index,current_jump)
  return index
end


-- build database / cube
local build = builder.build(conf)

query={
  dimensions={
    "product","order"
  },
  measures={
    "amt"
  } 
}

print("about to start query")
io.read()

process(build, query)
