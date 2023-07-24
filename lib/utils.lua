-- luacheck: ignore 142 112
local log = hs.logger.new('utils', 'info')
log.i('Loading module: utils')

-- === Extend builtins ===
function string:split(p) -- {{{
  -- Splits the string [s] into substrings wherever pattern [p] occurs.
  -- Returns: a table of substrings or, a table with the string as the only element
  p = p or '%s' -- split on space by default
  local temp = {}
  local index = 0
  local last_index = self:len()

  while true do
    local i, e = self:find(p, index)

    if i and e then
      local next_index = e + 1
      local word_bound = i - 1
      table.insert(temp, self:sub(index, word_bound))
      index = next_index
    else
      if index > 0 and index <= last_index then
        table.insert(temp, self:sub(index, last_index))
      elseif index == 0 then
        temp = { self }
      end
      break
    end
  end

  return temp
end                               -- }}}

function string:trim()            -- {{{
  return self
      :gsub('^%s+', '')           -- trim leading whitespace
      :gsub('%s+$', '')           -- trim trailing whitespace
end                               -- }}}

function table.slice(t, from, to) -- {{{
  -- Returns a partial table sliced from t, equivalent to t[x:y] in certain languages.
  -- Negative indices will be used to access the table from the other end.
  local n = #t
  to = to or n
  from = from or 1

  -- Modulo the negative index, to get it back into range.
  if from < 0 then from = (from % n) + 1 end


  -- Modulo the negative index, to get it back into range.-- Modulo the negative index, to get it back into range.-- Modulo the negative index, to get it back into range.
  if to < 0 then to = (to % n) + 1 end

  -- Copy relevant elements into a blank T-Table.
  local res, key = {}, 1

  for i = from, to do
    res[key] = t[i]
    key = key + 1
  end

  return res
end -- }}}

-- === utils module ===
local M        = {}

-- Alias hs.fnutils methods
M.map          = hs.fnutils.map
M.filter       = hs.fnutils.filter
M.reduce       = hs.fnutils.reduce
M.partial      = hs.fnutils.partial
M.each         = hs.fnutils.each
M.contains     = hs.fnutils.contains
M.some         = hs.fnutils.some
M.any          = hs.fnutils.some  -- alias 'some()' as 'any()'
M.all          = hs.fnutils.every -- alias 'every()' as 'all()'
M.concat       = hs.fnutils.concat
M.copy         = hs.fnutils.copy
M.sortByKeys   = hs.fnutils.sortByKeys
M.sortByValues = hs.fnutils.sortByKeyValues

function M.length(t) -- {{{
  if type(t) ~= 'table' then return 0 end
  local count = 0
  for _ in next, t do
    count = count + 1
  end
  return count
end                     -- }}}

function M.reverse(tbl) -- {{{
  -- Reverses values in a given array. The passed-in array should not be sparse.
  local res = {}
  for i = #tbl, 1, -1 do
    res[#res + 1] = tbl[i]
  end
  return res
end                   -- }}}

function M.flip(func) -- {{{
  -- Flips the order of parameters passed to a function
  return function(...)
    return func(table.unpack(M.reverse({ ... })))
  end
end                        -- }}}

function M.pipe(f, g, ...) -- {{{
  local function simpleCompose(f1, g1)
    return function(...)
      return f1(g1(...))
    end
  end

  if (g == nil) then return f or M.identity end
  local nextFn = simpleCompose(g, f)

  return M.pipe(nextFn, ...)
end                    -- }}}

function M.isnum(x)    -- {{{
  return type(x) == 'number'
end                    -- }}}

function M.istable(x)  -- {{{
  return type(x) == 'table'
end                    -- }}}

function M.isstring(x) -- {{{
  return type(x) == 'string'
end                    -- }}}

function M.isbool(x)   -- {{{
  return type(x) == 'boolean'
end                    -- }}}

function M.isfunc(x)   -- {{{
  return type(x) == 'function'
end                    -- }}}

function M.isarray(x)  -- {{{
  return M.istable(x) and x[1] ~= nil and x[M.length(x)] ~= nil
end                    -- }}}

function M.isjson(x)   -- {{{
  return M.isstring(x) and x:find('{') and x:find('}')
end                    -- }}}

function M.getiter(x)  -- {{{
  if M.isarray(x) then
    return ipairs(x)
  elseif type(x) == "table" then
    return pairs(x)
  end
  error("expected table", 3)
end                -- }}}

function M.keys(t) -- {{{
  local rtn = {}
  for k in M.getiter(t) do
    rtn[#rtn + 1] = k
  end
  return rtn
end                     -- }}}

function M.find(t, val) -- {{{
  result = nil
  for k, v in M.getiter(t) do
    if k == val then
      result = v
    end
  end
  return result
end                      -- }}}

function M.identity(val) -- {{{
  return val
end                      -- }}}

function M.values(t)     -- {{{
  local values = {}
  for _k, v in pairs(t) do
    values[#values + 1] = v
  end
  return values
end                      -- }}}

function M.from_iter(it) -- {{{
  if M.istable(it) then
    return it
  end
  local res = {}
  for item in it do
    table.insert(res, item)
  end
  return res
end                  -- }}}

function M.uniq(tbl) -- {{{
  local res = {}
  for _, v in ipairs(tbl) do
    res[v] = true
  end
  return M.keys(res)
end                          -- }}}

function table.merge(t1, t2) -- {{{
  --[[ TEST
    y = {blocks = { 'adam', 1, 2,'3', 99, 3 }, 7, 8, 9}
    z = {'a', 'b', 'c', name = 'JohnDoe', blocks = { 'test',2,3} }
    a = table.merge(y, z)
    ]]

  for k, v in pairs(t2) do
    local target = t1[k]
    local all_tbl = M.all({ v, target }, M.istable)
    local all_array = M.all({ v, target }, M.isarray)

    if all_array then
      t1[k] = M.concat(t1[k], v)     --luacheck: ignore 143
    elseif all_tbl then
      t1[k] = table.merge(target, v) --luacheck: ignore 143
    else
      t1[k] = v
    end
  end
  return t1
end                       -- }}}

function M.extend(t1, t2) -- {{{
  for k, v in M.getiter(t2) do
    t1[k] = v
  end
  return t1
end                          -- }}}

function M.include(tbl, val) -- {{{
  for _k, v in ipairs(tbl) do
    if M.equal(v, val) then
      return true
    end
  end
  return false
end               -- }}}

function M.cb(fn) -- {{{
  return function()
    return fn
  end
end                    -- }}}

function M.json_cb(fn) -- {{{
  -- wrap fn to decode json arg
  return function(...)
    return M.pipe(hs.json.decode, fn, ...)
  end
end                    -- }}}

function M.task_cb(fn) -- {{{
  -- wrap callback given to hs.task
  return function(...)
    local out = { ... }

    local is_hstask = function(x) -- {{{
      return #x == 3
          and tonumber(x[1])
          and M.isstring(x[2])
    end -- }}}

    if is_hstask(out) then
      local stdout = out[2]

      if M.isjson(stdout) then
        -- NOTE: hs.json.decode cannot parse "inf" values
        -- yabai response may have "inf" values: e.g., frame":{"x":inf,"y":inf,"w":0.0000,"h":0.0000}
        -- So, we must replace ":inf," with ":0,"
        local clean = stdout:gsub(':inf,', ':0,')
        stdout = hs.json.decode(clean)
      end

      return fn(stdout)
    end

    -- fallback if 'out' is not from hs.task
    return fn(out)
  end
end                                 -- }}}

function M.setfield(path, val, tbl) -- {{{
  log.d(('M.setfield: %s, val: %s'):format(path, val))

  tbl = tbl or _G           -- start with the table of globals
  for w, d in path:gmatch('([%w_]+)(.?)') do
    if d == '.' then        -- not last field?
      tbl[w] = tbl[w] or {} -- create table if absent
      tbl = tbl[w]          -- get the table
    else                    -- last field
      tbl[w] = val          -- do the assignment
    end
  end
end                                    -- }}}

function M.getfield(path, tbl, isSafe) -- {{{
  -- NOTE: isSafe defaults to false
  log.d(('M.getfield: %s (isSafe = %s)'):format(path, isSafe))

  local val = tbl or _G -- start with the table of globals
  local res = nil

  for path_seg in path:gmatch('[%w_]+') do
    if not M.istable(val) then return val end -- if v isn't table, return immediately
    val = val[path_seg]                       -- lookup next val
    if (val ~= nil) then res = val end        -- only update safe result if v not null
  end

  return isSafe and val == nil
      and res          -- return last non-nil value found
      or val           -- else return last value found, even if nil
end                    -- }}}

function M.toBool(val) -- {{{
  local t = type(val)

  if t == 'boolean' then
    return val
  elseif t == 'number' or tonumber(val) then
    return tonumber(val) >= 1 and true or false
  elseif t == 'string' then
    val = val:trim():lower()
    local lookup = {
      ['t'] = true,
      ['true'] = true,
      ['f'] = false,
      ['false'] = false,
    }
    return lookup[val]
  end

  print(string.format('toBool(val): Cannot convert %q to boolean. Returning "false"', val))
  return false
end                       -- }}}

function M.greaterThan(n) -- {{{
  return function(t)
    return #t > n
  end
end                                            -- }}}

function M.roundToNearest(roundTo, numToRound) -- {{{
  return numToRound - numToRound % roundTo
end                                            -- }}}

function M.print(data, howDeep)                    -- {{{
  -- local logger = hs.logger.new('inspect', 'debug')
  local depth = howDeep or 3
  if type(data) == 'table' then
    print(hs.inspect(data, { depth = depth }))
  else
    print(hs.inspect(data, { depth = depth }))
  end
end                     -- }}}

function M.pheader(str) -- {{{
  print('\n\n\n')
  print("========================================")
  print(string.upper(str), '==========')
  print("========================================")
end                      -- }}}

function M.groupBy(t, f) -- {{{
  -- FROM: https://github.com/pyrodogg/AdventOfCode/blob/1ff5baa57c0a6a86c40f685ba6ab590bd50c2148/2019/lua/util.lua#L149
  local res = {}
  for _k, v in pairs(t) do
    local g
    if type(f) == 'function' then
      g = f(v)
    elseif type(f) == 'string' and v[f] ~= nil then
      g = v[f]
    else
      error('Invalid group parameter [' .. f .. ']')
    end

    if res[g] == nil then
      res[g] = {}
    end
    table.insert(res[g], v)
  end
  return res
end                  -- }}}

function M.zip(a, b) -- {{{
  local rv = {}
  local idx = 1
  local len = math.min(#a, #b)
  while idx <= len do
    rv[idx] = { a[idx], b[idx] }
    idx = idx + 1
  end
  return rv
end                       -- }}}

function M.copyShallow(t) -- {{{
  -- FROM: https://github.com/XavierCHN/go/blob/master/game/go/scripts/vscripts/utils/table.lua
  local copy

  if not M.istable(t) then
    copy = t
    return copy
  end

  for k, v in M.getiter(t) do
    copy[k] = v
  end
  return copy
end                            -- }}}

function M.deepCopy(obj, seen) -- {{{
  -- from https://gist.githubusercontent.com/tylerneylon/81333721109155b2d244/raw/5d610d32f493939e56efa6bebbcd2018873fb38c/copy.lua
  -- The issue here is that the following code will call itself
  -- indefinitely and ultimately cause a stack overflow:
  --
  -- local my_t = {}
  -- my_t.a = my_t
  -- local t_copy = copy2(my_t)
  --
  -- This happens to both copy1 and copy2, which each try to make
  -- a copy of my_t.a, which involves making a copy of my_t.a.a,
  -- which involves making a copy of my_t.a.a.a, etc. The
  -- recursive table my_t is perfectly legal, and it's possible to
  -- make a deep_copy function that can handle this by tracking
  -- which tables it has already started to copy.
  --
  -- Thanks to @mnemnion for pointing out that we should not call
  -- setmetatable() until we're doing copying values; otherwise we
  -- may accidentally trigger a custom __index() or __newindex()!

  -- Handle non-tables and previously-seen tables.
  if not M.istable(obj) then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen and copy recursively.
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in M.getiter(obj) do
    res[M.deepCopy(k, s)] = M.deepCopy(v, s)
  end
  return setmetatable(res, getmetatable(obj))
end                          -- }}}

function M.safeSort(tbl, fn) -- {{{
  -- WANRING: Sorting mutates table
  fn = fn or function(x, y) return x < y end
  if M.isarray(tbl) then
    table.sort(tbl, fn)
  end
  return tbl
end                    -- }}}

function M.equal(a, b) -- {{{
  if a == b then
    return true
  end

  local all_tbls = M.all({ a, b }, M.istable)

  if all_tbls and (M.length(a) ~= M.length(b))
      or a == nil
      or b == nil
  then
    return false
  end

  M.each({ a, b }, M.safeSort)

  for k in M.getiter(a) do
    if b[k] ~= a[k] then
      return false
    end
  end

  return true
end                                        -- }}}

function M.levenshteinDistance(str1, str2) -- {{{
  str1, str2 = str1:lower(), str2:lower()
  local len1, len2 = #str1, #str2
  local c1, c2, dist = {}, {}, {}

  str1:gsub('.', function(c) table.insert(c1, c) end)
  str2:gsub('.', function(c) table.insert(c2, c) end)
  for i = 0, len1 do dist[i] = {} end
  for i = 0, len1 do dist[i][0] = i end
  for i = 0, len2 do dist[0][i] = i end

  for i = 1, len1 do
    for j = 1, len2 do
      dist[i][j] =
          math.min(dist[i - 1][j] + 1,
            dist[i][j - 1] + 1, dist[i - 1][j - 1] + (c1[i] == c2[j] and 0 or 1))
    end
  end
  return dist[len1][len2] / #str2
end                   -- }}}

function M.flatten(t) -- {{{
  if not M.isarray(t) then
    log.i('M.flatten expects array-type tbl, given dict-type tbl')
    return t
  end

  local ret = {}
  for _, v in ipairs(t) do
    if M.istable(v) then
      for _, fv in ipairs(M.flatten(v)) do
        ret[#ret + 1] = fv
      end
    else
      ret[#ret + 1] = v
    end
  end
  return ret
end                                                               -- }}}

function M.flattenPath(tbl)                                       -- {{{
  local function flatten(input, mdepth, depth, prefix, res, circ) -- {{{
    local k, v = next(input)
    while k do
      local pk = prefix .. k
      if not M.istable(v) then
        res[pk] = v
      else
        local ref = tostring(v)
        if not circ[ref] then
          if mdepth > 0 and depth >= mdepth then
            res[pk] = v
          else -- set value except circular referenced value
            circ[ref] = true
            local nextPrefix = pk .. '.'
            flatten(v, mdepth, depth + 1, nextPrefix, res, circ)
            circ[ref] = nil
          end
        end
      end
      k, v = next(input, k)
    end
    return res
  end -- }}}

  local maxdepth = 0
  local prefix = ''
  local result = {}
  local circularRef = { [tostring(tbl)] = true }

  return flatten(tbl, maxdepth, 1, prefix, result, circularRef)
end -- }}}

return M
