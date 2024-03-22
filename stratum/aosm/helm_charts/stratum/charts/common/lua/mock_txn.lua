--[[
    Stubbing the HAProxy txn class.
]]

local mock_http = require('mock_http')

local Txn = {}

function Txn:create()
    local txn = {}

    self.__index = self
    setmetatable(txn, Txn)

    txn.vars = {}
    txn:set_var("req.method", nil)
    txn:set_var("req.client_ip", nil)
    txn:set_var("req.client_port", nil)
    txn:set_var("req.path", nil)
    txn:set_var("req.url", nil)
    txn:set_var("req.uuid", nil)
    txn:set_var("req.is_test", "true")
    txn:set_var("req.debug_txn", "true")
    txn:set_var("req.partition_trace_enabled", "true")

    -- Mock the http functions.
    local http = mock_http:new()
    txn.http = http
    txn.num_logs = 0
    txn.last_log = ""

    return txn
end

function Txn:make(method, client_ip, path, url, uuid)
    local txn = Txn:create()

    txn:set_var("req.method", method)
    txn:set_var("req.client_ip", client_ip)
    txn:set_var("req.client_port", "12345")
    txn:set_var("req.path", path)
    txn:set_var("req.url", url)
    txn:set_var("req.uuid", uuid)
    txn:set_var("req.is_test", "true")
    txn:set_var("req.debug_txn", "true")
    txn:set_var("req.partition_trace_enabled", "true")

    return txn
end

function Txn:Debug(s)
    self.num_logs = self.num_logs + 1
    self.last_log = s
    print("[Debug] " .. s)
end

function Txn:Info(s)
    self.num_logs = self.num_logs + 1
    self.last_log = s
    print("[Info] " .. s)
end

function Txn:Warning(s)
    self.num_logs = self.num_logs + 1
    self.last_log = s
    print("[Warning] " .. s)
end

function Txn:Alert(s)
    self.num_logs = self.num_logs + 1
    self.last_log = s
    print("[Alert] " .. s)
end

function Txn:get_var(name)
    local value = self.vars[name]
    return value
end

function Txn:set_var(name, value)
    self.vars[name] = value
end

function Txn:get_num_logs()
    return self.num_logs
end

function Txn:get_last_log()
    return self.last_log
end

return Txn
