local lu = require'luaunit'
local regex_converter = require'regex_converter'

local regexes = {}
local test_file = "imsi_regexes.txt"

local function split(s, token)
    local fields = {}

    local sep = token or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

local function load_regexes()
    local file = io.open(test_file, "rb")
    if not file then
        print("Failed to load the test regexes file: " .. test_file)
        os.exit(1)
    end

    print("Loading the test regexes from: " .. test_file)
    for line in io.lines(test_file) do
        -- Ignore comments.
        if not line:match("^#") then
            local fields = split(line, ":")
            if #fields == 2 then
                local regex = fields[1]
                regex = regex:gsub("%s+", "")

                local expected_pattern = fields[2]
                expected_pattern = expected_pattern:gsub("%s+", "")

                if regex and expected_pattern then
                    regexes[regex] = expected_pattern
                end
            end
        end
    end

    file:close()
end

--

load_regexes()

local function do_percent_conversion(value, expected)
    local token = regex_converter.convert_backslash(value)
    local pattern = regex_converter.percent_digit_converter_expansion(token)
    lu.assertEquals(expected, pattern)
end

function test_percent_conversion()
    do_percent_conversion("\\d{1}", "%d")
    do_percent_conversion("\\d{2}", "%d%d")

    -- Should we allow {0}?
    do_percent_conversion("\\d{0}", "%d")

    do_percent_conversion("123\\d{2}", "123%d%d")
    do_percent_conversion("123\\d{3}456", "123%d%d%d456")
    do_percent_conversion("123\\d{3}456\\d{2}", "123%d%d%d456%d%d")
    do_percent_conversion("123\\d{3}456\\d{2}1212\\d{1}", "123%d%d%d456%d%d1212%d")

    do_percent_conversion("\\d", "%d")
    do_percent_conversion("\\d\\d\\d", "%d%d%d")
    do_percent_conversion("\\d1\\d2\\d3", "%d1%d2%d3")

    do_percent_conversion("1234", "1234")
    do_percent_conversion("", "")
    do_percent_conversion("\\s", "%s")
    do_percent_conversion("[1-2]{3}", "[1-2]{3}")

    do_percent_conversion("imsi-1234%d{4}567%d{4}", "imsi-1234%d%d%d%d567%d%d%d%d")
    do_percent_conversion("imsi-12341234", "imsi-12341234")
end

function test_convert_backslash()
    local pattern = regex_converter.convert_backslash("\\d")
    lu.assertEquals(pattern, "%d")

    pattern = regex_converter.convert_backslash("\\d\\d")
    lu.assertEquals(pattern, "%d%d")

    pattern = regex_converter.convert_backslash("\\d\\d%d\\s")
    lu.assertEquals(pattern, "%d%d%d%s")

    pattern = regex_converter.convert_backslash("")
    lu.assertEquals(pattern, "")

    pattern = regex_converter.convert_backslash("1234")
    lu.assertEquals(pattern, "1234")

    pattern = regex_converter.convert_backslash("1234\\d{2}")
    lu.assertEquals(pattern, "1234%d{2}")

    pattern = regex_converter.convert_backslash("1234\\d{2}\\d")
    lu.assertEquals(pattern, "1234%d{2}%d")
end

function test_convert_ranges()
    local pattern = regex_converter.expand_range("[0-9]")
    lu.assertEquals(pattern, "[0-9]")

    pattern = regex_converter.expand_range("[0-9]{1}")
    lu.assertEquals(pattern, "[0-9]")

    pattern = regex_converter.expand_range("[0-9]{2}")
    lu.assertEquals(pattern, "[0-9][0-9]")

    pattern = regex_converter.expand_range("123[0-9]{2}")
    lu.assertEquals(pattern, "123[0-9][0-9]")

    pattern = regex_converter.expand_range("123[0-9]{2}123")
    lu.assertEquals(pattern, "123[0-9][0-9]123")

    pattern = regex_converter.expand_range("123[0-9]{2}123[0-9]{3}")
    lu.assertEquals(pattern, "123[0-9][0-9]123[0-9][0-9][0-9]")

    pattern = regex_converter.expand_range("123[0-9]{2}123[0-9]{3}456")
    lu.assertEquals(pattern, "123[0-9][0-9]123[0-9][0-9][0-9]456")

    pattern = regex_converter.expand_range("123[0-9]{2}123[0-9]{3}456\\d+")
    lu.assertEquals(pattern, "123[0-9][0-9]123[0-9][0-9][0-9]456\\d+")
end

local function verify_att_regexes(regex, expected_pattern, imsi)
    local pattern = regex_converter.convert(regex)
    print("Regex   = " .. regex)
    print("Pattern = " .. pattern)
    print("Expected Pattern = " .. expected_pattern)
    print("Test IMSI        = " .. imsi)
    lu.assertEquals(pattern, expected_pattern)

    -- Verify that the pattern works:
    local m = imsi:match(pattern)
    lu.assertEquals(m, imsi)
end

function test_att_partitioning_regexes()
    local att_regex = "^imsi-[0-9]{10}00[0-9]{3}$"
    local expected_pattern = "^imsi%-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]00[0-9][0-9][0-9]$"
    local imsi = "imsi-121212121200321"
    verify_att_regexes(att_regex, expected_pattern, imsi)
end

os.exit(lu.LuaUnit.run())
