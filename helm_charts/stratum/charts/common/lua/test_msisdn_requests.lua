lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')
stratum_backends = require('stratum_backends')

-- The test file with no mappings.
local test_mappings = "site_mapping.txt"


function test_request_with_msisdn()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/subscription-data/msisdn-12345/",
      "http://192.168.1.1/subscription-data/msisdn-12345/", uuid)

  -- This will be set by HAProxy itself via an ACL.
  txn:set_var("req.is_msisdn", 1)

  -- Should be only routed to the local partition.
  test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")


  -- Ensure that the check is case-insensitive.
  txn = txn:make("GET", "127.0.0.1",
      "/SUBSCRIPTION-DATA/MSISDN-12345/",
      "http://192.168.1.1/SUBSCRIPTION-DATA/MSISDN-12345/", uuid)

  txn:set_var("req.is_msisdn", 1)

  test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
end

function test_request_with_wrong_msisdn()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/subscription-data/msisdn-/",
      "http://192.168.1.1/subscription-data/msisdn-/", uuid)

  -- Should be only routed to the local partition.
  test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
end


os.exit(lu.LuaUnit.run())