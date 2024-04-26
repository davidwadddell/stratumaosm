--[[
  Mocking the HAProxy applet API.

  https://www.arpalert.org/src/haproxy-lua-api/2.8/index.html
  https://www.arpalert.org/src/haproxy-lua-api/2.8/index.html#applethttp-class
]]

local mock_applet = {}

function mock_applet:create()
  local applet = {}

  self.__index = self
  setmetatable(applet, mock_applet)

  applet.vars = {}
  applet:set_var("req.method", nil)
  applet:set_var("req.client_ip", nil)
  applet:set_var("req.client_port", nil)
  applet:set_var("req.path", nil)
  applet:set_var("req.url", nil)
  applet:set_var("req.imsi", nil)
  applet:set_var("req.unavailable_partition", nil)

  -- For debugging
  applet:set_var("req.is_test", "true")
  applet:set_var("req.debug_txn", "true")
  applet:set_var("req.partition_trace_enabled", "true")
  applet:set_var("req.uuid", "abcd-1234-ffff")

  applet.status_code = 0
  applet.status_message = nil
  applet.headers = {}
  applet.body = nil

  return applet
end

function mock_applet:make(url, client_ip, client_port, imsi)
  local applet = mock_applet:create()

  applet:set_var("req.url", url)
  applet:set_var("req.client_ip", client_ip)
  applet:set_var("req.client_port", client_port)
  applet:set_var("req.imsi", imsi)

  return applet
end

function mock_applet:start_response()
end

function mock_applet:send(body)
  self.body = body
end

function mock_applet:get_body()
  return self.body
end

function mock_applet:add_header(name, value)
  self.headers[name] = name .. ": " .. value
end

function mock_applet:get_header(name)
  return self.headers[name]
end

function mock_applet:set_status(code, message)
  self.status_code = code
  self.status_message = message
end

function mock_applet:get_status_code()
  return self.status_code
end

function mock_applet:get_status_message()
  return self.status_message
end

function mock_applet:set_var(name, value)
  self.vars[name] = value
end

function mock_applet:get_var(name)
  return self.vars[name]
end

return mock_applet

