local concat = require('mock_concat')
local lu = require('luaunit')

function test_concat()
  local c = concat:new()
  c:add("test")
  lu.assertEquals(c:dump(), "test")
end

function test_concat_multiple_strings()
  local c = concat:new()
  c:add("test")
  c:add("123")
  c:add("xyz")
  lu.assertEquals(c:dump(), "test123xyz")
end

function test_multiple_concats()
  local c1 = concat:new()
  c1:add("123")

  local c2 = concat:new()
  c2:add("abc")
  c2:add("xyz")

  local c3 = concat:new()
  c3:add("testing")

  lu.assertEquals(c1:dump(), "123")
  lu.assertEquals(c2:dump(), "abcxyz")
  lu.assertEquals(c3:dump(), "testing")
end

os.exit(lu.LuaUnit.run())