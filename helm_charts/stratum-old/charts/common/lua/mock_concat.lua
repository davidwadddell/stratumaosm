local concat = {}

function concat:new()
  local c = {}
  c.str = ""

  setmetatable(c, concat)
  self.__index = self

  return c
end

function concat:add(str)
  self.str = self.str .. str
end

function concat:dump()
  return self.str
end

return concat
