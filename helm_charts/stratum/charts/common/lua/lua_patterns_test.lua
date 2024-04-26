require "socket"

lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')

local num_iterations = 100000

--[[
  Setup
]]
load_test_mappings("att_test_mappings.txt")
local site_mappings = get_site_mappings()
if site_mappings ~= nil then
  print("Site mappings loaded")
end

local function show_site_patterns(mappings)
  for site_name, regexes in pairs(mappings) do
    for _, regex in pairs(regexes) do
      print("\tSite Name = " .. site_name .. "  :  " .. regex)
    end
  end
end

--

function test_lua_patterns()
  core:new()

  local start_time = socket.gettime() * 1000

  for _ = 1,num_iterations do
    local partition = stratum.select_partition_for_imsi("912300000019000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000029000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000029000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000049000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000059000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000069000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000079000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000089000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000099000", site_mappings)
    lu.assertNotNil(partition)

    partition = stratum.select_partition_for_imsi("912300000000000", site_mappings)
    lu.assertNotNil(partition)
  end

  local end_time = socket.gettime() * 1000
  print("Lua Patterns Time taken = " .. (end_time - start_time) .. "(ms)")
  local num_matches = stratum.get_num_pattern_matches()
  print("Number of matches performed: " .. num_matches)
end

--

local function stratum_check_regex(imsi, mappings)
  for site_name, big_regex in pairs(mappings) do
    local m = rex_pcre2.match(imsi, big_regex)
    --local m = rex_pcre.match(imsi, big_regex)
    --local m = onig.match(imsi, big_regex)
    --local m = rex_tre.match(imsi, big_regex)
    if m and m == imsi then
      -- Get the site.
      return stratum.get_backend(site_name)
    end
  end

  return nil
end


os.exit(lu.LuaUnit.run())
