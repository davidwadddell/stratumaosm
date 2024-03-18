local mock_server = require('mock_server')

local mock_backend = {}

function mock_backend:create(name, cap, is_remote)
  local be = {}

  setmetatable(be, mock_backend)
  self.__index = self

  be.name = name
  be.cap = cap

  if is_remote then
    local server = mock_server:new("srv001")
    be.servers = { server }
  else
    local server1 = mock_server:new("srv001")
    local server2 = mock_server:new("srv002")
    local server3 = mock_server:new("srv003")
    local server4 = mock_server:new("srv004")
    be.servers = { server1, server2, server3, server4 }
  end

  return be
end

function mock_backend:get_cap()
  return self.cap
end

function mock_backend:get_name()
  return self.name
end

function mock_backend:get_srv_act()
  local num_active_servers = 0

  for _, server in pairs(self.servers) do
    if server:get_stats()["status"] == "UP" then
      num_active_servers = num_active_servers + 1
    end
  end

  return num_active_servers
end

-- Not a mocked function - testing only
function mock_backend:set_down()
  for _, server in pairs(self.servers) do
    print("Setting server " .. server:get_name() .. " into the DOWN state")
    server:set_down()
  end
end

-- Not a mocked function - testing only
function mock_backend:set_up()
  for _, server in pairs(self.servers) do
    print("Setting server " .. server:get_name() .. " into the UP state")
    server:set_up()
  end
end

return mock_backend
