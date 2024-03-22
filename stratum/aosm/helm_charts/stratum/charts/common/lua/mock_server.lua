local mock_server = {}

function mock_server:new(name)
  local server = {}

  self.__index = self

  server.name = name
  server.stats = {
  }

  server.stats["status"] = "UP"

  setmetatable(server, mock_server)

  return server
end

function mock_server:get_stats()
  return self.stats
end

function mock_server:get_name()
  return self.name
end

-- For testing.
function mock_server:set_down()
  self.stats["status"] = "DOWN"
end

-- For testing.
function mock_server:set_up()
  self.stats["status"] = "UP"
end

return mock_server
