require 'ext_table'
active_record = require 'active_record'

------------------------------------------
-- dijkstra
--
-- Implementation of dijkstra algorithm
-- to find shortest path between 2 nodes.
-- Used to get joins between 2 tables
------------------------------------------
local dijkstra = {}

------------------------------------------------
-- find_shortest_path
--
-- calculates which joins required to navigate
-- from table 1 to table 2
-- adaptation of Dijkstra's algorithm
-------------------------------------------------
function dijkstra.find_shortest_path(joins, start, finish)
  local joins=table.new(joins)
  local nodes = table.new()
  local j = table.new()
  -- get all the nodes
  for i,join in ipairs(joins) do
    nodes[join.t1]={}
    nodes[join.t1].name=join.t1
    nodes[join.t1].visited=false
    if join.t1==start then nodes[join.t1].distance = 0 else nodes[join.t1].distance=99999999 end
    nodes[join.t2]={}
    nodes[join.t2].name=join.t2
    nodes[join.t2].visited=false
    if join.t2==start then nodes[join.t2].distance = 0 else nodes[join.t2].distance=99999999 end
  end
  nodes = nodes:values() -- convert dict to list

  -- calculate neighbors of each node
  for k, node in pairs(nodes) do
    node.neighbors = joins
      :where(function(k,v) return v.t1==node.name end)
      :map(function(k,v) return v.t2 end)
      :iunion(
        joins
          :where(function(k,v) return v.t2==node.name end)
          :map(function(k,v) return v.t1 end)
      )
      :values()
  end
  local start_node = nodes:where(function(_,v) return v.name==start end):first()
  start_node.path=table.new({start}) -- stores list of nodes that give final path
  dijkstra.evaluate_shortest_path_node(nodes, start_node)
  
  -- get finish node path
  local finish_node = nodes:first(function(_,v) return v.name==finish end)
  return finish_node.path
end

function dijkstra.evaluate_shortest_path_node(nodes, node)
  local node_distance=1	-- assume path between all nodes is 1
  for _,neighbor in pairs(node.neighbors) do
    local neighbor_node = nodes:first(function(k,v) return v.name==neighbor end)
    if (node.distance+node_distance) < neighbor_node.distance then
      neighbor_node.distance=node.distance+node_distance
      neighbor_node.path=table.new()
      node.path:clone(neighbor_node.path)
      table.insert(neighbor_node.path, neighbor)
    end
  end
  node.visited=true
  -- get the next node to process
  local next = nodes:where(function(k,v) return v.visited==false end):order(function(a,b) return a.distance<b.distance end):first()
  if next then
    dijkstra.evaluate_shortest_path_node(nodes, next)
  else
    return
  end
end

local function build(conf)
  local ar = active_record.new({connection_string="./nw.sl3"})
  build=table.new()
  -- source tables
  build.source=table.new() -- holds source tables
  for k,v in pairs(conf.tables) do
    print(" - processing table:"..k)
    build.source[k]=ar:query(v.query)
  end

  -- measures
  -- build separate table for each measure
  build.measures=table.new()
  for measure_name, measure in pairs(conf.measures) do
    print(" - processing measure:"..measure_name)
    build.measures[measure_name] = {}
    local results = build.source[measure.t]
    for k,v in pairs(results) do
      local key = v["__row_id"]
      build.measures[measure_name][key] = v.Amt  -- h/code for time being
    end
  end

  -- index is built for each dimension, for each table that has a measure
  -- get the index structures ready
  local tables_with_measures = table.new(conf.measures):map(function(k,v) return v.t end):distinct()
  build.indexes=table.new()
  for _,v in pairs(tables_with_measures) do
    build.indexes[v] = table.new()
  end

  -- dimensions
  -- A dimension is a single column used for slicing/dicing
  -- build table for each dimension
  build.dimensions=table.new()
  for dimension_name,dimension in pairs(conf.dimensions) do
    print(" - processing dimension:"..dimension_name)
    local sql="SELECT DISTINCT "..dimension.k.." k,"..dimension.v.." v FROM ("..conf.tables[dimension.t].query..") T"
    local results=ar:query(sql)
    build.dimensions[dimension_name]=table.new()
    for k,v in pairs(results) do
      build.dimensions[dimension_name][k]=v
    end
    print(build.dimensions[dimension_name]:count().." rows.")

    -- process index for each measure table
    print(" - processing index for dimension:"..dimension_name)
    for k,v in pairs(build.indexes) do
      -- see if path exists between measure table and dimension
      local path = dijkstra.find_shortest_path(conf.joins, k, dimension.t)
      if path then
	-- work out path from measure table to dimension table
        local join_rules={}
        for i=1,#path-1,1 do
          local jr={}
          jr.fk_table=path[i]
          jr.pk_table=path[i+1]
          local j = conf.joins
          local join_rule = j:first(function(k,v) return v.t1==jr.fk_table and v.t2==jr.pk_table end)
          jr.fk_column=join_rule.c1
          jr.pk_column=join_rule.c2
          table.insert(join_rules, jr)
        end        
        -- loop through all rows in measure table
        local out = table.new()
        for _,row in pairs(build.source[k]) do
          local key=-1
          for i,jr in ipairs(join_rules) do
            if i==1 then
              key=row[jr.fk_column]
            elseif i<#join_rules then
              print("should not be here yet too complicated !")
              -- for time being assume ALWAYS join dimension
              -- tables on their primary key (hash key) column
              key=table.new(build.source[pk_table])[key][fk_column]
            end
          end
          table.insert(out, {rowid=row.__row_id, value=key})
        end
        table.sort(out, function(a,b) return a.value<b.value end)
        build.indexes[k][dimension_name] = out
      end
    end
  end    
  return build
end

return {
  build = build
}