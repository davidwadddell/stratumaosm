local regex_converter = {}

local imsi_prefix = "imsi%-.*"

--[[
    Convert fragments of a regex in the form:
        %d{N}
    to:
        %d%d%d...%d
    where there are N %d tokens.

    Note:
    The convert_backslash function should be called first to replace any
    special characters such as \d to %d first.

    @param regex The string to be converted.

    @return The converted regex.
]]
function regex_converter.percent_digit_converter_expansion(regex)
    local luaPattern = string.gsub(regex, "\\d", "%%d") -- Replace \d with %d
    luaPattern = string.gsub(luaPattern, "%%d{(%d+)}", function(count)
        return "%d" .. string.rep("%d", tonumber(count) - 1)
    end)
    return luaPattern
end

--[[
    Converts backslash characters \ to percent characters % so they can be used in Lua.
    For example:
        \\d\\d
    is converted to:
        %d%d

    @param regex The tokens to be converted.

    @return The regex with \ symbols replaced with % symbols.
]]
function regex_converter.convert_backslash(regex)
    local converted = regex:gsub("\\", "%%")
    return converted
end

function regex_converter.expand_range(input)
    local pattern = string.gsub(input, "%[(%d+)%-(%d+)%]{(%d+)}", function(lower, upper, count)
        local token = string.format("[%s-%s]", lower, upper)
        return token .. string.rep(token, tonumber(count) - 1)
    end)

    return pattern
end

function regex_converter.convert(regex)
    local pattern = regex_converter.percent_digit_converter_expansion(regex)
    pattern = regex_converter.convert_backslash(pattern)
    pattern = regex_converter.expand_range(pattern)

    -- '-' symbols in Lua patterns must be represented as %-
    pattern = pattern:gsub("imsi%-" , "imsi%%-")

    return pattern
end

return regex_converter