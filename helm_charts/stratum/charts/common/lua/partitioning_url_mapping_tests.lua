lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')

local test_mappings = "site_mapping.txt"

local function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

--[[
    Test the AT&T Call flows:
    https://enea.sharepoint.com/:x:/s/owm-eng/sdm/Ed7BfVEX5s1Hs5JTcM0SlyQBCa-OP5IvUkKMMaSDZ8obVw?e=udTJKR
]]
function test_subscription_data()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local paths = {
            --[[
                Subscription Data
            ]]
            "/subscription-data/{ueId}/authentication-data/authentication-subscription",
            "/subscription-data/{ueId}/authentication-data/authentication-status",
            "/subscription-data/{ueId}/authentication-data/authentication-status/{servingNetworkName}",
            "/subscription-data/{ueId}/ue-update-confirmation-data/sor-data",
            "/subscription-data/{ueId}/ue-update-confirmation-data/upu-data",
            "/subscription-data/{ueId}/ue-update-confirmation-data/subscribed-snssais",
            "/subscription-data/{ueId}/ue-update-confirmation-data/subscribed-cag",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/am-data",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/smf-selection-subscription-data",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/sm-data",
            "/subscription-data/{ueId}/context-data/amf-3gpp-access",
            "/subscription-data/{ueId}/context-data/amf-non-3gpp-access",
            "/subscription-data/{ueId}/context-data/smf-registrations",
            "/subscription-data/{ueId}/context-data/smf-registrations/{pduSessionId}",
            "/subscription-data/{ueId}/operator-specific-data",
            "/subscription-data/{ueId}/context-data/smsf-3gpp-access",
            "/subscription-data/{ueId}/context-data/smsf-non-3gpp-access",
            "/subscription-data/{ueId}/context-data/ip-sm-gw",
            "/subscription-data/{ueId}/context-data/mwd",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/sms-mng-data",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/sms-data",
            "/subscription-data/{ueId}/pp-data",
            "/subscription-data/{ueId}/pp-profile-data",
            "/subscription-data/{ueId}/pp-data-store/{afInstanceId}",
            "/subscription-data/{ueId}/pp-data-store",
            "/subscription-data/{ueId}/context-data/ee-subscriptions",
            "/subscription-data/{ueId}/context-data/ee-subscriptions/{subsId}",
            "/subscription-data/{ueId}/context-data/ee-subscriptions/{subsId}/amf-subscriptions",
            "/subscription-data/{ueId}/context-data/ee-subscriptions/{subsId}/smf-subscriptions",
            "/subscription-data/{ueId}/context-data/ee-subscriptions/{subsId}/hss-subscriptions",
            "/subscription-data/{ueId}/ee-profile-data",
            "/subscription-data/{ueId}/context-data/sdm-subscriptions",
            "/subscription-data/{ueId}/context-data/sdm-subscriptions/{subsId}",
            "/subscription-data/{ueId}/context-data/sdm-subscriptions/{subsId}/hss-sdm-subscriptions",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/trace-data",
            "/subscription-data/{ueId}/identity-data",
            "/subscription-data/{ueId}/operator-determined-barring-data",
            "/subscription-data/{ueId}/context-data",
            "/subscription-data/{ueId}/lcs-privacy-data",
            "/subscription-data/{ueId}/lcs-mo-data",
            "/subscription-data/{ueId}/nidd-authorization-data",
            "/subscription-data/{ueId}/coverage-restriction-data",
            "/subscription-data/{ueId}/context-data/location",
            "/subscription-data/{ueId}/v2x-data",
            "/subscription-data/{ueId}/prose-data",
            "/subscription-data/{ueId}/{servingPlmnId}/provisioned-data/lcs-bca-data",
            "/subscription-data/{ueId}/context-data/nidd-authorizations",
            "/subscription-data/{ueId}/5mbs-data",
            "/subscription-data/{ueId}",
            "/subscription-data/{ueId}/service-specific-authorization-data/{serviceType}",
            "/subscription-data/{ueId}/context-data/service-specific-authorizations/{serviceType}",
            "/subscription-data/{ueId}/context-data/roaming-information",
            "/subscription-data/{ueId}/context-data/pei-info",
            "/subscription-data/{ueId}/uc-data",
            "/subscription-data/{ueId}/roaming-plan",

            --[[
                Policy Data
            ]]
            "/policy-data/ues/{ueId}/am-data",
            "/policy-data/ues/{ueId}/ue-policy-set",
            "/policy-data/ues/{ueId}/sm-data",
            "/policy-data/ues/{ueId}/sm-data/{usageMonId}",
            "/policy-data/ues/{ueId}/operator-specific-data",
    }

    local imsi_mappings = {
        {"310950000062326", "west-site1_site3-ingress"},
        {"12345",           "west-site1_west-site1-ingress-local"}
    }

    for index, path in pairs(paths) do
        local nudr_path = "/nudr-dr/v2" .. path
        local url = "http://stratum.com" .. nudr_path

        nudr_path = nudr_path:gsub("{ueId}", "imsi-%%s")
        url = url:gsub("{ueId}", "imsi-%%s")

        print("")
        print("Test case: " .. index)
        print("  Path: " .. nudr_path)
        print("  URL:  " .. url)

        for _, mappings in pairs(imsi_mappings) do
            local imsi = mappings[1]
            local partition = mappings[2]
            print("\timsi = " .. imsi .. "  :  partition = " .. partition)

            local txn = txn:make("GET", "127.0.0.1", nudr_path, url, uuid)
            test_common.run_txn(txn, imsi, partition)
            local imsi_from_request = txn:get_var("req.imsi")
            lu.assertEquals(imsi_from_request, imsi)
        end
    end
end

-- No IMSI in this one.
function test_roaming_plan_profile()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/roaming-plan-profile"
    local url = "http://stratum.com" .. path

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)

    local json = readAll("roaming_plan_profile.json")
    txn:set_var("req.body", json)
    txn:set_var("req.local_partition_only", 1)

    test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)
end

--[[
    subs_to_notify tests
]]
test_subscriber_data_subs_to_notify = {}

function test_subscriber_data_subs_to_notify:test_method_is_not_delete_or_post()
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

function test_subscriber_data_subs_to_notify.test_delete_with_missing_path()
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

function test_subscriber_data_subs_to_notify.test_delete_with_encoded_string_missing()
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

function test_subscriber_data_subs_to_notify.test_delete_with_encoded_string_missing_2()
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

function test_subscriber_data_subs_to_notify.test_delete_with_encoded_string_is_nonsense()
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

function test_subscriber_data_subs_to_notify.test_delete_with_encoded_string_imsi_missing()
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

function test_subscriber_data_subs_to_notify.test_delete_with_encoded_imsi()
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

function test_subscriber_data_subs_to_notify.test_get_with_imsi_in_query()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002123")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002123")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "116310952002123")

    local partition = select_partition(txn)
    lu.assertEquals("west-site1_site3-ingress", partition)
end

function test_subscriber_data_subs_to_notify.test_get_with_imsi_in_query_imsi_missing()
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

function test_subscriber_data_subs_to_notify.test_get_with_imsi_in_query_with_many_query_params()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local txn = txn:create()
    txn:set_var("req.method", "GET")
    txn:set_var("req.client_ip", "127.0.0.1")
    txn:set_var("req.client_port", "55555")
    txn:set_var("req.path", "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-116310952002123")
    txn:set_var("req.url", "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?id=1234&name=brian&phone=999&ue-id=imsi-116310952002123&region=north")
    txn:set_var("req.uuid", "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6")

    scan_request_for_imsi(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "116310952002123")

    local partition = select_partition(txn)
    lu.assertEquals("west-site1_site3-ingress", partition)
end

function test_subscriber_data_subs_to_notify.test_post_with_no_body()
    core:new()
    load_test_mappings(test_mappings)
    local txn = txn:create()
    set_local_backend("west-site1_west-site1-ingress-local")
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
    lu.assertEquals("west-site1_west-site1-ingress-local", backend)
end

function test_subscriber_data_subs_to_notify.test_delete_with_imsi_in_query_params()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local path = "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-310950000062326&nf-instance-id=672a1a16-c26a-4491-ad2b-591055fd52ae&implicit-unsubscribe-indication=true"
    local url = "http://stratum.com" .. path
    local uuid = "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6"

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi)

    scan_request_for_imsi(txn)
    imsi = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi)

    local backend = select_partition(txn)
    lu.assertEquals(backend, "west-site1_site3-ingress")
end

function test_subscriber_data_subs_to_notify.test_delete_with_imsi_base64_encoded_in_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local path = "/nudr-dr/v2/subscription-data/subs-to-notify/eyJuZkluc3RhbmNlSWQiOiJiYTBlOGU3NC1iYjdiLTRlMjEtOTFjNC1lNmJkOTYwMWVhMzYiLCJtb25pdG9yZWRSZXNvdXJjZVVyaXMiOlsiL3N1YnNjcmlwdGlvbi1kYXRhL2ltc2ktMzEwOTUwMDAwMDYyMzI2LzMxMTE4MC9wcm92aXNpb25lZC1kYXRhL3Ntcy1tbmctZGF0YSJdfQ"
    local url = "http://stratum.com" .. path
    local uuid = "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6"

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)

    -- We won't have the imsi yet.
    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertNil(imsi)

    -- We should get the imsi here by base64 decoding the path.
    scan_request_for_imsi(txn)
    imsi = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi)

    local backend = select_partition(txn)
    lu.assertEquals(backend, "west-site1_site3-ingress")
end

function test_subscription_data_delete_with_imsi_in_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local path = "/nudr-dr/v2/subscription-data/imsi-310950000062326/context-data/smsf-3gpp-access"
    local url = "http://stratum.com" .. path
    local uuid = "a95cc82c-3ae8-4510-89e5-fe4a9be34ea6"

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)

    get_imsi_from_url(txn)
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi)

    scan_request_for_imsi(txn)
    imsi = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi)

    local backend = select_partition(txn)
    lu.assertEquals(backend, "west-site1_site3-ingress")
end

-- Testing the path /nudr-dr/v2/subscription-data
function test_subscription_data()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/subscription-data"
    local url = "http://stratum.com" .. path

    print("")
    print("  Path: " .. path)
    print("  URL:  " .. url)

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, nil, "west-site1_west-site1-ingress-local")
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

function test_delete_subscription_data()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/subscription-data/imsi-310950000062326/context-data/smf-registrations/2"
    local url = "http://stratum.com" .. path

    print("")
    print("  Path: " .. path)
    print("  URL:  " .. url)

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "310950000062326")
end

test_policy_data = {}

function test_policy_data.test_valid_posts()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local imsi_mappings = {
        -- IMSI,            expected partition
        {"123451234512345", "west-site1_west-site1-ingress-local"},
        {"22222",           "west-site1_site2-ingress"},
        {"100000000011000", "west-site1_site3-ingress"}
    }

    local http_methods = { "POST", "PUT" }

    for index, mappings in pairs(imsi_mappings) do
        local imsi = mappings[1]
        local partition = mappings[2]
        local path = "/nudr-dr/v2/policy-data/subs-to-notify"
        local url = "http://stratum.com" .. path
        local body = string.format('{{"notificationUri":"https://www.host.co.uk/nudr-dr/v2/policy-data/notify","monitoredResourceUris":["https://www.host.co.uk/nudr-dr/v2/policy-data/ues/imsi-%s/am-data"]}}', imsi)

        for _, http_method in pairs(http_methods) do
            print("")
            print("policy data subs to notify test: " .. index)
            print("\tPath:        " .. path)
            print("\tURL:         " .. url)
            print("\tBody:        " .. body)
            print("\tHTTP method: " .. http_method)

            local txn = txn:make(http_method, "127.0.0.1", path, url, uuid)
            txn:set_var("req.body", body)

            get_imsi_from_url(txn)
            local imsi_from_request = txn:get_var("req.imsi")
            lu.assertNil(imsi_from_request)

            scan_request_for_imsi(txn)
            imsi_from_request = txn:get_var("req.imsi")
            lu.assertEquals(imsi_from_request, imsi)

            local selected_partition = select_partition(txn)
            lu.assertEquals(selected_partition, partition)
        end
    end
end

function test_policy_data.test_post_with_msisdn_instead_of_imsi()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/policy-data/subs-to-notify"
    local url = "http://stratum.com" .. path
    local body = '{ "notificationUri":"http://mlu-pcf-api-gateway.mlu-pcf.svc/user-service/userservice/notification/msisdn-1871587819", "monitoredResourceUris":[ "https://localhost:9443/nudr-dr-prov/v1/policy-data/msisdn-1111111111/sm-data" ], "supportedFeatures":"f", "expires": "2022-04-23T18:25:43.511Z" }'

    print("")
    print("\tPath: " .. path)
    print("\tURL:  " .. url)
    print("\tBody: " .. body)

    local txn = txn:make("POST", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    -- Should go to the local backend if there's no IMSI.
    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "west-site1_west-site1-ingress-local")
end

function test_policy_data.test_put_with_msisdn_instead_of_imsi()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/policy-data/subs-to-notify"
    local url = "http://stratum.com" .. path
    local body = '{ "notificationUri":"http://mlu-pcf-api-gateway.mlu-pcf.svc/user-service/userservice/notification/msisdn-1871587819", "monitoredResourceUris":[ "https://localhost:9443/nudr-dr-prov/v1/policy-data/msisdn-1111111111/sm-data" ], "supportedFeatures":"f", "expires": "2022-04-23T18:25:43.511Z" }'

    print("")
    print("\tPath: " .. path)
    print("\tURL:  " .. url)
    print("\tBody: " .. body)

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    -- Should go to the local backend if there's no IMSI.
    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "west-site1_west-site1-ingress-local")
end

function test_policy_data.test_delete_with_imsi_base64_encoded()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudr-dr/v2/policy-data/subs-to-notify/eyJpZCI6IjAwMDAwMTg4MzBCRTBERDQwMUU0OEIwMTAxMDUyODAwIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvdWUtcG9saWN5LXNldCIsIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvb3BlcmF0b3Itc3BlY2lmaWMtZGF0YSJdfQ"
    local url = "http://stratum.com" .. path

    print("")
    print("\tPath: " .. path)
    print("\tURL:  " .. url)

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals("310950000062326", imsi_from_request)

    -- Should go to the local backend if there's no IMSI.
    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "west-site1_site3-ingress")
end

-- /policy-data/ues/{ueId}
function test_policy_data.test_policy_data_ues_for_put()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"

    local imsi = "123451234512345"
    local path = string.format("/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set", imsi)
    local url = "http://stratum.com" .. path
    local body = '{"subscCats":["category1","category2"],"suppFeat":"AF"}'

    print("")
    print("\tPath: " .. path)
    print("\tURL:  " .. url)

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, imsi)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, imsi)

    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "west-site1_west-site1-ingress-local")
end

-- /policy-data/ues/{ueId}
function test_policy_data.test_policy_data_ues_for_get()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("west-site1_west-site1-ingress-local")

    local uuid = "abcd-abcd-abcd"
    local imsi = "123451234512345"
    local path = string.format("/nudr-dr/v2/policy-data/ues/imsi-%s/am-data", imsi)
    local url = "http://stratum.com" .. path

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, imsi)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, imsi)

    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "west-site1_west-site1-ingress-local")
end

-- /policy-data
-- Should go to the local partition.
function test_policy_data.test_policy_data_custom_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-partition")

    local uuid = "abcd-abcd-abcd"
    local path = "/policy-data/brian?query=value&abc=123"
    local url = "http://stratum.com" .. path

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)

    get_imsi_from_url(txn)
    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    scan_request_for_imsi(txn)
    imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)

    local selected_partition = select_partition(txn)
    lu.assertEquals(selected_partition, "local-partition")
end


--[[
    Testing UDSF requests - they should all go to the local partition.
]]
test_udsf = {}

function test_udsf.test_udsf_put_with_imsi_in_body()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"

    local path = "/nudsf-dr/v1/authentication/authCtx/records/d6f93d58-5327-435d-b199-e7fc2164ea26LYzcduTW"
    local url = "http://stratum.com" .. path
    local body = "{'meta': [{'Content-ID': '9c46bde1-0321-4e1d-9c75-c82de26a87ab', 'Content-Type': 'application/json', 'content': {}}], 'blocks': [{'Content-ID': '2b90eede-cd28-4e3e-a331-94f9bd383399', 'Content-Type': 'application/json', 'Content-Transfer-Encoding': 'binary', 'content': '\"22CC391E38042F76872B04CDA53B1F49;CB8AD71F92BC51E7C18ECFEE81785F434916F4F5218EE2A6FD4B87ABA6940E91;imsi-310950111000045;5G:mnc180.mcc311.3gppnetwork.org;false\"'}]}"

    print("")
    print("  Path: " .. path)
    print("  URL:  " .. url)

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)

    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

function test_udsf.test_udsf_delete()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudsf-dr/v1/authentication/authCtx/records/d6f93d58-5327-435d-b199-e7fc2164ea26LYzcduTW"
    local url = "http://stratum.com" .. path

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)
    txn:set_var("req.local_partition_only", 1)
    txn:set_var("req.is_udsf", 1)

    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

function test_nudr_with_no_imsi()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data?fields=ueId"
    local url = "http://stratum.com" .. path

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

--[[
    Application Data
]]
test_application_data = {}

-- /application-data/influenceData
function test_application_data.test_application_data_with_put()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/application-data/influenceData/123"
    local url = "http://stratum.com" .. path
    local body = '{{"supi":"imsi-123451234512345"}}'

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)
    test_common.run_txn(txn, "123451234512345", "west-site1_west-site1-ingress-local")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "123451234512345")
end

-- /application-data/influenceData
function test_application_data.test_application_data_with_put_with_no_body()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/application-data/influenceData/123"
    local url = "http://stratum.com" .. path

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

-- /application-data/influenceData
function test_application_data.test_application_data_with_put_imsi_missing()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/application-data/influenceData/123"
    local url = "http://stratum.com" .. path
    local body = '{{"supi":"missing"}}'

    local txn = txn:make("PUT", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)
    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

-- /application-data/influenceData/subs-to-notify
function test_application_data.test_application_data_with_post()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/application-data/influenceData/subs-to-notify"
    local url = "http://stratum.com" .. path
    local body = '{{"notificationUri":"https://www.enea.com/notify","dnns":["dnn1"],"supis":["imsi-123451234512345"]}}'

    local txn = txn:make("POST", "127.0.0.1", path, url, uuid)
    txn:set_var("req.body", body)
    test_common.run_txn(txn, "123451234512345", "west-site1_west-site1-ingress-local")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "123451234512345")
end

function test_application_data.test_application_data_with_delete_imsi_base64_encoded()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"

    -- A base64 encoded string that contains the IMSI. THis decodes as:
    -- {"id":"0000018BCE22B746007238010103EB01","monitoredResourceUris":["application-data/iptvConfigData/imsi-743284865475714"],"name":["supi"]}
    local encoded_sub_id = "eyJpZCI6IjAwMDAwMThCQ0UyMkI3NDYwMDcyMzgwMTAxMDNFQjAxIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbImFwcGxpY2F0aW9uLWRhdGEvaXB0dkNvbmZpZ0RhdGEvaW1zaS03NDMyODQ4NjU0NzU3MTQiXSwibmFtZSI6WyJzdXBpIl19"
    local path = "/nudr-dr/v2/application-data/subs-to-notify/" .. encoded_sub_id
    local url = "http://stratum.com" .. path

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "743284865475714", "west-site1_west-site1-ingress-local")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "743284865475714")
end

function test_application_data.test_application_data_with_delete()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-740495817948783"
    local url = "http://stratum.com" .. path

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "740495817948783", "west-site1_west-site1-ingress-local")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "740495817948783")
end

function test_exposure_data_with_delete()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/exposure-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCQ0U5MkJGNDUwMTUwRUEwMTAxMDNFQjAxIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9leHBvc3VyZS1kYXRhL2ltc2ktOTkyMDAzNTk0NDA5ODcwL2FjY2Vzcy1hbmQtbW9iaWxpdHktZGF0YSJdfQ"
    local url = "http://stratum.com" .. path

    local txn = txn:make("DELETE", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "992003594409870", "west-site1_west-site1-ingress-local")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "992003594409870")
end

function test_get_with_base64_encoded_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCQ0VCNTlDRkQwMDExOEEwMTAxMDNFQzAxIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9zdWJzY3JpcHRpb24tZGF0YS9pbXNpLTU0MDQwMTc0NjgxMDUwMi91ZS11cGRhdGUtY29uZmlybWF0aW9uLWRhdGEvc3Vic2NyaWJlZC1zbnNzYWlzIl19"
    local url = "http://stratum.com" .. path

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "540401746810502", "west-site1_site2-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "540401746810502")
end

function test_patch_with_base64_encoded_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCQ0VCNTlDRkQwMDExOEEwMTAxMDNFQzAxIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9zdWJzY3JpcHRpb24tZGF0YS9pbXNpLTU0MDQwMTc0NjgxMDUwMi91ZS11cGRhdGUtY29uZmlybWF0aW9uLWRhdGEvc3Vic2NyaWJlZC1zbnNzYWlzIl19"
    local url = "http://stratum.com" .. path

    local txn = txn:make("PATCH", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, "540401746810502", "west-site1_site2-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_request, "540401746810502")
end

function test_get_with_malformed_base64_encoded_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCQ0VCNTlDRkQwMDExOEEwMTAxM"
    local url = "http://stratum.com" .. path

    local txn = txn:make("GET", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

function test_patch_with_malformed_base64_encoded_path()
    core:new()
    load_test_mappings(test_mappings)
    set_local_backend("local-ingress")

    local uuid = "abcd-abcd-abcd"
    local path = "/nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDAwMThCQ0VCNTlDRkQwMDExOEEwMTAxM"
    local url = "http://stratum.com" .. path

    local txn = txn:make("PATCH", "127.0.0.1", path, url, uuid)
    test_common.run_txn(txn, nil, "local-ingress")

    local imsi_from_request = txn:get_var("req.imsi")
    lu.assertNil(imsi_from_request)
end

os.exit(lu.LuaUnit.run())
