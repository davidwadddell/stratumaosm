local lu = require('luaunit')
local mock_backend = require('mock_backend')

function test_mock_backends()
  local be1 = mock_backend:create("ild1", "backend", false)
  local be2 = mock_backend:create("ild2", "backend", false)
  local be3 = mock_backend:create("ild3", "backend", false)

  lu.assertEquals(be1:get_name(), "ild1")
  lu.assertEquals(be2:get_name(), "ild2")
  lu.assertEquals(be3:get_name(), "ild3")
end

function test_get_srv_act()
  local be1 = mock_backend:create("ild1", "backend", false)
  lu.assertEquals(be1:get_srv_act(), 4)

  local be2 = mock_backend:create("ild1", "backend", true)
  lu.assertEquals(be2:get_srv_act(), 1)
end

os.exit(lu.LuaUnit.run())
