--[[
    Mocks when the local partitions become unavailable. The requests should be routed to the backup sites.
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

function test_local_partition_becomes_unavailable()
  core:new()
  load_test_mappings(test_mappings)
  local uuid = "abcd-abcd-abcd"

  -- Disable the local backend.
  for _, be in pairs(core.backends) do
    if be:get_name() == "west-site1_west-site1-ingress-local" then
      -- Disable this one.
      print("Disabling backend " .. be:get_name())
      be:set_down()
    end
  end

  local txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  -- This request should be rejected.
  test_common.run_txn(txn, "610950111136456","stratum_west-site1-stratum-haproxy-ingress-no-partition_http")



  -- Re-enable the backend.
  for _, be in pairs(core.backends) do
    if be:get_name() == "west-site1_west-site1-ingress-local" then
      -- Disable this one.
      print("Enabling backend " .. be:get_name())
      be:set_up()
    end
  end

  txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  -- This request should be accepted now.
  test_common.run_txn(txn, "610950111136456","west-site1_west-site1-ingress-local")



  -- Disable the local backend (again).
  for _, be in pairs(core.backends) do
    if be:get_name() == "west-site1_west-site1-ingress-local" then
      -- Disable this one.
      print("Disabling backend " .. be:get_name())
      be:set_down()
    end
  end

  txn = txn:make("GET", "127.0.0.1",
      "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)

  -- This request should be rejected.
  test_common.run_txn(txn, "610950111136456","stratum_west-site1-stratum-haproxy-ingress-no-partition_http")

end

os.exit(lu.LuaUnit.run())

