lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')
test_common = require('test_common')

local test_mappings = "site_mapping.txt"

--[[
    Test the AT&T Call flows:
    https://owm-jira.atlassian.net/wiki/spaces/SCD/pages/4122476557/ATT+Call+Flow
]]

--[[
    https://owm-jira.atlassian.net/wiki/spaces/SCD/pages/4122476557/ATT+Call+Flow#Deregistration-flow%3A
]]
test_att_deregistration_call_flow = {}

function test_att_deregistration_call_flow.test_request1()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/policy-data/subs-to-notify/eyJpZCI6IjAwMDAwMTg4MzBCRTBERDQwMUU0OEIwMTAxMDUyODAwIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvdWUtcG9saWN5LXNldCIsIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvb3BlcmF0b3Itc3BlY2lmaWMtZGF0YSJdfQ",
            "http://192.168.1.1/nudr-dr/v2/policy-data/subs-to-notify/eyJpZCI6IjAwMDAwMTg4MzBCRTBERDQwMUU0OEIwMTAxMDUyODAwIiwibW9uaXRvcmVkUmVzb3VyY2VVcmlzIjpbIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvdWUtcG9saWN5LXNldCIsIi9wb2xpY3ktZGF0YS91ZXMvaW1zaS0zMTA5NTAwMDAwNjIzMjYvb3BlcmF0b3Itc3BlY2lmaWMtZGF0YSJdfQ", uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")

    local imsi_from_encoded_path = txn:get_var("req.imsi")
    lu.assertEquals(imsi_from_encoded_path, "310950000062326")
end

function test_att_deregistration_call_flow.test_request2()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            "http://192.168.1.1/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950000062326")


    txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            "http://192.168.1.1/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "54123")


    txn = txn:make("PUT", "127.0.0.1",
            "/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            "http://192.168.1.1/nudr-dr/v2/policy-data/ues/imsi-%s/ue-policy-set",
            uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")

    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "610950111123456")
end

function test_att_deregistration_call_flow.test_request3()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            "http://127.0.0.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            uuid)
    test_common.run_txn(txn, "310950000062327", "west-site1_site3-ingress")

    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950000062327")

    txn = txn:make("GET", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            "http://127.0.0.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")

    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "610950111123456")
end

function test_att_deregistration_call_flow.test_request4()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    local txn = txn:make("DELETE",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/2",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/2",
            uuid)
    test_common.run_txn(txn, "310950000062328", "west-site1_site3-ingress")
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950000062328")


    txn = txn:make("DELETE",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/2",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/2",
            uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")
    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "610950111123456")
end

function test_att_deregistration_call_flow.test_request5()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    --

    local txn = txn:make("DELETE",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=672a1a16-c26a-4491-ad2b-591055fd52ae&implicit-unsubscribe-indication=true",
            "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=672a1a16-c26a-4491-ad2b-591055fd52ae&implicit-unsubscribe-indication=true",
            uuid)

    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950000062326")

    --

    txn = txn:make("DELETE",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=672a1a16-c26a-4491-ad2b-591055fd52ae&implicit-unsubscribe-indication=true",
            "http://stratum.com/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=672a1a16-c26a-4491-ad2b-591055fd52ae&implicit-unsubscribe-indication=true",
            uuid)

    test_common.run_txn(txn, "510950000061320", "west-site1_site2-ingress")
    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "510950000061320")
end

function test_att_deregistration_call_flow.test_request6()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    --

    local txn = txn:make("GET",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            uuid)

    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")
    local imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "310950000062326")

    --

    txn = txn:make("GET",
            "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            "http://stratum.com/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations",
            uuid)

    test_common.run_txn(txn, "510950000061320", "west-site1_site2-ingress")
    imsi = txn:get_var("req.imsi")
    lu.assertEquals(imsi, "510950000061320")
end

function test_att_deregistration_call_flow.test_request7()
    core:new()
    local mappings = get_site_mappings()
    load_test_mappings(test_mappings, mappings)

    local uuid = "abcd-abcd-abcd"

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1", uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")


    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smf-registrations/1", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")
end

function test_att_deregistration_call_flow.test_request8()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/subs-to-notify",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=e750b72f-07d6-56a0-abb9-1c4aabddd390&implicit-unsubscribe-indication=true", uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/subs-to-notify",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=e750b72f-07d6-56a0-abb9-1c4aabddd390&implicit-unsubscribe-indication=true", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/subs-to-notify",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-%s&nf-instance-id=e750b72f-07d6-56a0-abb9-1c4aabddd390&implicit-unsubscribe-indication=true", uuid)
    test_common.run_txn(txn, "610950111123456", "west-site1_site3-ingress")
end

function test_att_deregistration_call_flow.test_request9()
    core:new()
    load_test_mappings(test_mappings)

    local uuid = "abcd-abcd-abcd"

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access", uuid)
    test_common.run_txn(txn, "310950000062326", "west-site1_site3-ingress")

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access", uuid)
    test_common.run_txn(txn, "54123", "west-site1_west-site1-ingress-local")

    txn = txn:make("DELETE", "127.0.0.1",
            "/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access",
            "http://192.168.1.1/nudr-dr/v2/subscription-data/imsi-%s/context-data/smsf-3gpp-access", uuid)
    test_common.run_txn(txn, "610950111125456", "west-site1_site2-ingress")
end


os.exit(lu.LuaUnit.run())
