--[[
  Mocks the HAProxy http functions used in the Txn object.
]]

local mock_http = {}

function mock_http:new()
  local o = {}
  setmetatable(o, mock_http)
  self.__index = self

  -- The table that will store the HTTP headers.
  o.headers = {}

  return o
end

function mock_http:req_get_header(hdr_name)
  local hdr_value = self.headers[hdr_name]
  return hdr_value
end

function mock_http:req_set_header(hdr_name, hdr_value)
  self.headers[hdr_name] = hdr_value
end

function mock_http:req_add_header(hdr_name, hdr_value)
  self.headers[hdr_name] = hdr_value
end

function mock_http:req_get_headers()
  return self.headers
end

return mock_http