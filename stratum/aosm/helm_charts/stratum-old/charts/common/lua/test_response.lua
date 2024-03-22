lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
Txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')
stratum_backends = require('stratum_backends')

function test_log_response()
  local txn = Txn:create()
  txn:set_var("res.client_ip", "192.168.1.1")
  txn:set_var("res.client_port", "123")
  txn:set_var("res.uuid", "123456")
  txn:set_var("res.method", "GET")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=123456] Received response for GET request from [192.168.1.1]:123")
end

function test_log_response_with_rtt()
  core.set_time(1705676341, 0)

  local txn = Txn:create()
  txn:set_var("res.client_ip", "192.168.1.1")
  txn:set_var("res.client_port", "123")
  txn:set_var("res.uuid", "123456")
  txn:set_var("res.method", "GET")
  txn:set_var("res.start_time", "1705676340879000")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=123456] Received response for GET request from [192.168.1.1]:123 Ingress RTT 121000us")
end

function test_log_response_for_health_check()
  local txn = Txn:create()
  txn:set_var("res.client_ip", "192.168.1.1")
  txn:set_var("res.client_port", "123")
  txn:set_var("res.uuid", "123456")
  txn:set_var("res.method", "GET")
  txn:set_var("res.health_check", "true")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "")
  lu.assertEquals(txn:get_num_logs(), 0)
end

function test_log_response_client_ip_missing()
  local txn = Txn:create()
  txn:set_var("res.client_port", "123")
  txn:set_var("res.uuid", "123456")
  txn:set_var("res.method", "GET")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=123456] Received response for GET request from [Unknown IP]:123")
end

function test_log_response_client_port_missing()
  local txn = Txn:create()
  txn:set_var("res.uuid", "123456")
  txn:set_var("res.method", "GET")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=123456] Received response for GET request from [Unknown IP]:[Unknown Port]")
end

function test_log_response_uuid_missing()
  local txn = Txn:create()
  txn:set_var("res.method", "GET")

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=] Received response for GET request from [Unknown IP]:[Unknown Port]")
end

function test_log_response_method_missing()
  local txn = Txn:create()

  handle_response(txn)
  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=] Received response for [Unknown Method] request from [Unknown IP]:[Unknown Port]")
end

function test_response_with_all_params_missing()
  local txn = Txn:create()
  handle_response(txn)

  local msg = txn:get_last_log()
  lu.assertEquals(msg, "[uuid=] Received response for [Unknown Method] request from [Unknown IP]:[Unknown Port]")
end

os.exit(lu.LuaUnit.run())
