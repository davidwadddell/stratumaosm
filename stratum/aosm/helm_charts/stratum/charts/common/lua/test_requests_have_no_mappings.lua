--[[
    These tests will issue requests, some of which contain IMSI that do not match
    any of the site mappings. When we cannot map a request to a partition, then 
    we must route the request to the local partition so that the ILDs can decide
    what to do with it.
]]

lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')
stratum_backends = require('stratum_backends')

local test_mappings = "site_mapping_imsi_missing.txt"

function test_no_imsi_mapping()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  -- This IMSI won't have any mapping to a partition and should be routed to the local partition.
  local imsi = "610950111100456"

  test_common.run_txn(txn, imsi, "west-site1_west-site1-ingress-local")

  txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  -- This IMSI won't have any mapping to a partition and should be routed to the local partition.
  imsi = "00123"

  test_common.run_txn(txn, imsi, "west-site1_west-site1-ingress-local")
end

-- Requests that don't have any IMSI must be routed to the local partition.
function test_request_with_no_imsi()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local", true)
end

os.exit(lu.LuaUnit.run())
