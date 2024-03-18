lu = require('luaunit')
core = require('mock_core')
base64 = require('base64')
txn = require('mock_txn')
stratum = require('stratum')

local test_common = {}

function test_common.run_txn(txn, imsi, expected_partition, imsi_is_missing)
    local http_method = txn:get_var("req.method")

    -- Update any tokens in the path and URL
    local path = txn:get_var("req.path")
    path = string.format(path, imsi)
    txn:set_var("req.path", path)

    local url = txn:get_var("req.url")
    url = string.format(url, imsi)
    txn:set_var("req.url", url)

    local test_case = string.format("\nTesting %s %s", http_method, path)
    print(test_case)
    print("\tPath = " .. path)
    print("\tURL  = " .. url)

    local operational_status = path:match("/oam/v1/operational_status")
        or path:match("/builtin/v1/operationalstatus")
    if operational_status then
        txn:set_var("req.is_health_check", 1)
    end

    local check_path = url:match("imsi%-")
    if check_path then
        print("\tChecking get_imsi_from_path")
        get_imsi_from_url(txn)

        if imsi_is_missing == nil or imsi_is_missing == false then
            local imsi_from_url = txn:get_var("req.imsi")
            print("\tIMSI = " .. imsi)
            lu.assertEquals(imsi_from_url, imsi)
        end
    end

    local check_body_for_imsi = path:match("subs%-to%-notify")
            or path:match("subs%-to%-notify")
            or path:match("^/nudr%-dr/v.*/application%-data")

    if check_body_for_imsi then
        print("\tChecking check_body_for_imsi")
        scan_request_for_imsi(txn)
    end

    local partition = select_partition(txn)
    lu.assertEquals(partition, expected_partition)

    local imsi_from_test = txn:get_var("req.imsi")
    if imsi_is_missing and imsi_is_missing == true then
       lu.assertIsNil(imsi_from_test, "The IMSI was expected to the nil")
    else
        lu.assertEquals(imsi_from_test, imsi)
    end
end

return test_common
