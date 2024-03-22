lu = require('luaunit')
mock_applet = require('mock_applet')
core = require('mock_core')
stratum = require('stratum')

-- The test file with no mappings.
local test_mappings = "site_mapping.txt"

function test_ilds_not_available()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
      "192.168.1.1",
      "1234",
      "12345")

  applet:set_var("req.unavailable_partition", "site3")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [192.168.1.1]:1234 to URL: <pre>http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS</pre>
          with IMSI [12345] cannot be routed to the local partition [site3] - All ILDs are unavailable.</p>
          <pre>uuid: abcd-1234-ffff</pre>
          </body></html>
          ]]

  lu.assertEquals(applet:get_body(), expected_response)

  local uuid_header = applet:get_header("stratum-partition-uuid")
  lu.assertEquals(uuid_header, "stratum-partition-uuid: abcd-1234-ffff")
end

function test_ilds_not_available_client_ip_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          "1234",
          "12345")

  applet:set_var("req.unavailable_partition", "site3")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to the partition [site3] - All ILDs are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_ilds_not_available_client_port_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          nil,
          "12345")

  applet:set_var("req.unavailable_partition", "site3")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to the partition [site3] - All ILDs are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_ilds_not_available_client_ip_port_and_imsi_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          nil,
          nil)

  applet:set_var("req.unavailable_partition", "site3")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to the partition [site3] - All ILDs are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_partition_not_available()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          "192.168.1.1",
          "1234",
          "12345")

  applet:set_var("req.unavailable_partition", "site3")
  applet:set_var("req.partitions_not_available", "true")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [192.168.1.1]:1234 to URL: <pre>http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS</pre>
          with IMSI [12345] cannot be routed to any partition - the partitions are unavailable.</p>
          <pre>uuid: abcd-1234-ffff</pre>
          </body></html>
          ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_partition_not_available_imsi_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          "192.168.1.1",
          "1234",
          nil)

  applet:set_var("req.unavailable_partition", "site3")
  applet:set_var("req.partitions_not_available", "true")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [192.168.1.1]:1234 to URL: <pre>http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS</pre>
          cannot be routed to any partition - the partitions are unavailable.</p>
          <pre>uuid: abcd-1234-ffff</pre>
          </body></html>
          ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_partition_not_available_client_ip_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          "1234",
          "12345")

  applet:set_var("req.unavailable_partition", "site3")
  applet:set_var("req.partitions_not_available", "true")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to any partition - the partitions are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_partition_not_available_client_ip_and_port_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          nil,
          "12345")

  applet:set_var("req.unavailable_partition", "site3")
  applet:set_var("req.partitions_not_available", "true")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to any partition - the partitions are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

function test_partition_not_available_client_ip_and_port_and_imsi_missing()
  core:new()
  load_test_mappings(test_mappings)

  local applet = mock_applet:make("http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-12345/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
          nil,
          nil,
          nil)

  applet:set_var("req.unavailable_partition", "site3")
  applet:set_var("req.partitions_not_available", "true")

  partition_not_found(applet)

  lu.assertEquals(applet:get_status_code(), 503)
  lu.assertEquals(applet:get_status_message(), "Service Unavailable")

  local expected_response = [[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to any partition - the partitions are unavailable.</p>
        <pre>uuid: abcd-1234-ffff</pre>
        </body></html>
        ]]

  lu.assertEquals(applet:get_body(), expected_response)
end

os.exit(lu.LuaUnit.run())
