stratum_mappings = require('stratum_mappings')
lu = require('luaunit')
core = require('mock_core')

function test_load_missing_file()
  lu.assertEquals(core.alert_called, 0)
  local mapping = stratum_mappings:new('missing.txt')
  lu.assertEquals(core.alert_called, 1)
  lu.assertNotNil(mapping)
end

function test_load_mapping_files()
  local mapping = stratum_mappings:new('site_mapping.txt')
  lu.assertNotNil(mapping)
end


os.exit(lu.LuaUnit.run())