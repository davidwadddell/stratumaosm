local imsi = "310950211123456"
local pattern = "310950211%d%d%d%d%d%d"

local num_found = 0
local num_missing = 0

function find_imsi(imsi)
    for i = 1, 1000000 do
        if imsi:match(pattern) then
            num_found = num_found + 1
        else
            num_missing = num_missing + 1
        end
    end
end


local imsi = "310950211123456"
local pattern = "310950211%d%d%d%d%d%d"
find_imsi(imsi)

imsi = "310650211123456"
find_imsi(imsi)

pattern = "31095%d211%d%d%d%d%d[4-7]"
find_imsi(imsi)

imsi = "310950211123456"
find_imsi(imsi)

print("num_found = " .. num_found)
print("num_missing = " .. num_missing)
