local concat = require('mock_concat')
local mock_backend = require('mock_backend')
require('socket')

-- stub the 'core' global variable that HAProxy creates
local Core = {}

local t = {}
t["sec"] = 0
t["usec"] = 0
Core.tm = t

Core.register_action = function(name, handlers, fn, num_args)end
Core.register_init = function(fn) end
Core.register_fetches = function(name, fn)end
Core.register_converters = function()end
Core.register_service = function(name, protocol, fn)end
Core.alert_called = 0

local local_backend = "west-site1_west-site1-ingress-local"

function Core:new()
    local core = {}
    setmetatable(core, Core)
    self.__index = self

    local be1 = mock_backend:create(local_backend, "backend", false)
    local be2 = mock_backend:create("west-site1_site2-ingress", "backend", true)
    local be3 = mock_backend:create("west-site1_site3-ingress", "backend", true)
    local be4 = mock_backend:create("stratum_west-site1-stratum-haproxy-ingress-no-partition_http", "backend", false)

    self.backends = { be1, be2, be3, be4 }

    for _, backend in pairs(self.backends) do
        local backend_name = backend:get_name()
        Core.Debug("Mock Core: Loading backend: " .. backend_name)
    end

    Core.Debug("Mock Core: Local backend is: " .. local_backend)

    return core
end

function Core.Debug(s)
    print(s)
end

function Core.Info(s)
    print(s)
end

function Core.Warn(s)
    print(s)
end

function Core.Alert(s)
    Core.alert_called = Core.alert_called + 1
    print(s)
end

function Core.concat()
    return concat:new()
end

-- This is a test function, not a Core API being mocked.
function  Core.get_local_backend()
    return local_backend
end

function Core.done()
end

function Core.set_time(sec, usec)
    Core.tm["sec"] = sec
    Core.tm["usec"] = usec
end

function Core.now()
    return Core.tm
end

return Core
