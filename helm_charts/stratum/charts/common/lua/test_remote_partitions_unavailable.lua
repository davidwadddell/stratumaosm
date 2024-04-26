--[[
    Mocks when the remote partitions become unavailable. The requests should then go to the local partition (ILDs).
]]

lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')
stratum_backends = require('stratum_backends')

-- The test file with no mappings.
local test_mappings = "site_mapping.txt"

function test_with_all_partitions_available()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)
  test_common.run_txn(txn, "610950111123456","west-site1_site3-ingress")
end

function test_with_site3_unavailable()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  test_common.run_txn(txn, "610950111123456","west-site1_site3-ingress")

  -- Now disable site3 and try again.
  for _, be in pairs(core.backends) do
    if be:get_name() == "west-site1_site3-ingress" then
      -- Disable this one.
      print("Disabling backend " .. be:get_name())
      be:set_down()
    end
  end

  -- The request will be rejected as the IMSI matches to a partition, but it is unavailable.
  txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  test_common.run_txn(txn, "610950111123456","stratum_west-site1-stratum-haproxy-ingress-no-partition_http")
end

function test_with_site2_unavailable()
  core:new()
  load_test_mappings(test_mappings)

  local uuid = "abcd-abcd-abcd"

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  test_common.run_txn(txn, "610950111125456","west-site1_site2-ingress")

  -- Disable site2 now.
  for _, be in pairs(core.backends) do
    if be:get_name() == "west-site1_site2-ingress" then
      -- Disable this one.
      print("Disabling backend " .. be:get_name())
      be:set_down()
    end
  end

  -- The request will be rejected as the IMSI matches to a partition, but it is unavailable.
  txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  test_common.run_txn(txn, "610950111125456","stratum_west-site1-stratum-haproxy-ingress-no-partition_http")
end

os.exit(lu.LuaUnit.run())
