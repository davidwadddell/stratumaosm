--require("luacov")

lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')
stratum_backends = require('stratum_backends')

local test_mappings = "site_mapping.txt"


--[[
    get_imsi_from_path tests
]]
test_get_imsi_from_path = {}

function test_get_imsi_from_path:test_empty_url()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1", "", "", "abc")
    get_imsi_from_url(txn)

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, nil)
end

function test_get_imsi_from_path:test_invalid_path()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "test",
            "http://stratum.com/test", "abc")

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, nil)
end

function test_get_imsi_from_path:test_invalid_imsi()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi310950111000045/authentication-data/authentication-subscription",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi310950111000045/authentication-data/authentication-subscription", "abc")

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, nil)
end

function test_get_imsi_from_path:test_valid_imsi()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-310950111000045/authentication-data/authentication-subscription",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi-310950111000045/authentication-data/authentication-subscription", "abc")

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950111000045")
end

function test_get_imsi_from_path:test_valid_imsi_case_insensitive()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/IMSI-310950111000045/authentication-data/authentication-subscription",
            "http://stratum.com/nudr-dr/v2/subscription-data/IMSI-310950111000045/authentication-data/authentication-subscription", "abc")

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950111000045")
end

--[[
    get_imsi_from_post tests
]]
test_get_imsi_from_post = {}

function test_get_imsi_from_post:test_body_is_missing()
    local txn = txn:create()
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.method", "POST")
    txn:set_var("req.body", nil)
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_post(txn, "POST")
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_get_imsi_from_post:test_body_is_empty()
    local txn = txn:create()
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.method", "POST")
    txn:set_var("req.body", "")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_post(txn, "POST")
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_get_imsi_from_post:test_body_missing_imsi()
    local txn = txn:create()
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.method", "POST")
    txn:set_var("req.body", "the imsi is missing")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_post(txn, "POST")
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_get_imsi_from_post:test_body_with_imsi()
    local txn = txn:create()
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.method", "POST")
    txn:set_var("req.body", '{"notificationUri":"http://107.121.220.128:80/callback/nudr-dr/smp/v2/policyDataChangeNotificationPost?recordId=a922edd1-1c09-4ffc-b152-567be4890c88","monitoredResourceUris":["http://107.121.220.112:8001/nudr-dr/v2/policy-data/ues/imsi-310950111000045/sm-data","http://107.121.220.112:8001/nudr-dr/v2/policy-data/ues/imsi-310950111000045/operator-specific-data"],"supportedFeatures":"1000"}')
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_post(txn, "POST")

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950111000045")
end

function test_get_imsi_from_post:test_body_with_imsi_case_insensitive()
    local txn = txn:create()
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.method", "POST")
    txn:set_var("req.body", '{"notificationUri":"http://107.121.220.128:80/callback/nudr-dr/smp/v2/policyDataChangeNotificationPost?recordId=a922edd1-1c09-4ffc-b152-567be4890c88","monitoredResourceUris":["http://107.121.220.112:8001/nudr-dr/v2/policy-data/ues/IMSI-310950111000045/sm-data","http://107.121.220.112:8001/nudr-dr/v2/policy-data/ues/IMSI-310950111000045/operator-specific-data"],"supportedFeatures":"1000"}')
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_post(txn, "POST")

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950111000045")
end


--[[
    scan_request_for_imsi tests
]]
test_subscriber_data_scan_request_for_imsi = {}

function test_subscriber_data_scan_request_for_imsi:test_method_is_not_delete_or_post()
    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_missing_path()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_encoded_string_missing()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_encoded_string_missing_2()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify/")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_encoded_string_is_nonsense()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify/aslkdfklajsdklfjajlsjffndvnskdrnwersdfgerjsdfglkjdfsglkjg")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_encoded_string_imsi_missing()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCMjM2RDdFRDMwMUE1NzQwMTAxMDNGMDAyIiwibmZJbnN0YW5jZUlkIjpbIjAwNTgzNGRmLWI2MWMtNDM5Ni1hMmY1LWQ3N2FlOWE4NzdiZCJdLCJtb25pdG9yZWRSZXNvdXJjZVVyaXMiOlsiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3RhdHVzIiwiL3N1YnNjcmlwdGlvbi1kYXRhL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3Vic2NyaXB0aW9uIl19")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_delete_with_encoded_imsi()
    local txn = txn:create()
    txn:set_var("req.method", "DELETE")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCMjM2RDdFRDMwMUE1NzQwMTAxMDNGMDAyIiwibmZJbnN0YW5jZUlkIjpbIjAwNTgzNGRmLWI2MWMtNDM5Ni1hMmY1LWQ3N2FlOWE4NzdiZCJdLCJtb25pdG9yZWRSZXNvdXJjZVVyaXMiOlsiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktMTE2MzEwOTUyMDAyL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3RhdHVzIiwiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktMTE2MzEwOTUyMDAyL2F1dGhlbnRpY2F0aW9uLWRhdGEvYXV0aGVudGljYXRpb24tc3Vic2NyaXB0aW9uIl19")
    txn:set_var("req.url", "http://stratum.com/")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "116310952002")
end

function test_subscriber_data_scan_request_for_imsi.test_get_with_imsi_in_query()
    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "116310952002")
end

function test_subscriber_data_scan_request_for_imsi.test_get_with_imsi_in_query_imsi_missing()
    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-missing")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_subscriber_data_scan_request_for_imsi.test_get_with_imsi_in_query_with_many_query_params()
    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "116310952002")
end

function test_subscriber_data_scan_request_for_imsi.test_post_with_no_body()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:create()
    txn:set_var("req.method", "POST")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/policy-data/subs-to-notify")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/policy-data/subs-to-notify")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)

    local backend = select_partition(txn)
    lu.assertEquals(backend, "west-site1_west-site1-ingress-local")
end

test_select_partition = {}

function test_select_partition.test_partitions_site1()
    core:new()

    load_test_mappings(test_mappings)
    local mappings = get_site_mappings()

    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    -- The pattern to match is: 310950211%d%d%d%d%d%d
    local imsi = "310950211123456"
    local num_partitions, partition = stratum.select_partition_for_imsi(txn, imsi, mappings)
    lu.assertEquals(num_partitions, 1)
    lu.assertEquals(partition, "west-site1_site3-ingress")
end

function test_select_partition.test_partition_lookup_fails()
    core:new()

    load_test_mappings(test_mappings)

    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    -- The pattern to match is: 310950211%d%d%d%d%d%d
    local imsi = "310850211123456"

    local mappings = get_site_mappings()
    local num_partitions, partition = stratum.select_partition_for_imsi(txn, imsi, mappings)
    lu.assertEquals(num_partitions, 1)
    lu.assertEquals(partition, "west-site1_site3-ingress")

    imsi = "3108502111234"
    num_partitions, partition = stratum.select_partition_for_imsi(txn, imsi, mappings)
    lu.assertEquals(num_partitions, 0)
    lu.assertNil(partition)
end

function test_select_partition.test_head_request()
    core:new()

    load_test_mappings(test_mappings)

    local txn = txn:create()
    txn:set_var("req.method", "HEAD")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end


test_stratum_module = {}

function test_stratum_module.test_get_imsi_from_base64_encoded_path__path_is_missing()
    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    stratum.get_imsi_from_base64_encoded_path(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

function test_stratum_module.test_load_missing_mapping_file()
    core:new()
    lu.assertEquals(0, core.alert_called)
    load_test_mappings("missing")
    lu.assertEquals(2, core.alert_called)
end

function test_stratum_module.test_get_port_from_ipv4_addr()
    local addr = "127.0.0.1:1234"
    local port = stratum.get_port_from_addr(addr)
    lu.assertEquals("1234", port)
end

function test_stratum_module.test_get_port_from_ipv6_addr()
    local addr = "[2001:db8::1]:80"
    local port = stratum.get_port_from_addr(addr)
    lu.assertEquals("80", port)
end

function test_stratum_module.test_get_port_from_addr_port_missing()
    local addr = "[2001:db8::1]"
    local port = stratum.get_port_from_addr(addr)
    lu.assertNil(port)
end

function test_stratum_module.test_policy_no_imsi()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/policy-data/ues/",
            "http://192.168.1.1/nudr-dr/v2/policy-data/ues/", "abc")

    get_imsi_from_url(txn)

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, nil)
end

function test_stratum_module.test_subscription_data_no_imsi()
    core:new()
    load_test_mappings(test_mappings)

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/",
            "http://stratum.com/nudr-dr/v2/subscription-data/", "abc")

    get_imsi_from_url(txn)

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, nil)
end

function test_stratum_module.test_requests()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    --[[
        Group 1 operations
    ]]

    -- 1. GET /nudr-dr/v2/subscription-data/imsi-%d/authentication-data/authentication-subscription
    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 2. PATCH /nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription
    txn = txn:make("PATCH", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("PATCH", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("PATCH", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-subscription", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 3. PUT /nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status
    txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/authentication-data/authentication-status", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    --[[
        Group 2 operations
    ]]

    -- 1. GET /nudr-dr/v2/subscription-data/imsi-%s/%s/provisioned-data/am-data
    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/12345/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/12345/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/54123/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/54123/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/610950111123456/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/610950111123456/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 2. GET /nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access
    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 3. GET /nudr-dr/v2/subscription-data/imsi-%s/%s/provisioned-data/am-data
    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/12345/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/12345/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/54123/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/54123/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/610950111123456/provisioned-data/am-data",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/610950111123456/provisioned-data/am-data", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 4. PUT /nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access
    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/amf-3gpp-access", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")


    -- 5. GET /nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%2CEE_SUBSCRIPTIONS
    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)
    test_common.run_txn(txn, "12345", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data?context-dataset-names=SMSF_3GPP%%2CEE_SUBSCRIPTIONS", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")
end

--[[
    Requests for/oam/v1/operational_status should be sent to the local partition.
]]
function test_send_health_check()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("GET", "127.0.0.1",
        "/oam/v1/operational_status",
        "http://192.168.1.1/oam/v1/operational_status", uuid)
    test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
end

--[[
    Requests for /builtin/v1/operationalstatus should be sent to the local partition.
]]
function test_operational_status()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("GET", "127.0.0.1",
        "/builtin/v1/operationalstatus",
        "http://192.168.1.1/builtin/v1/operationalstatus", uuid)
    test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
end

os.exit(lu.LuaUnit.run())
