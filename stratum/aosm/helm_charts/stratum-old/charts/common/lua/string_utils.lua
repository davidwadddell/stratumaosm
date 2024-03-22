local string_utils = {}

function string_utils.escape_pattern(p)
  return p:gsub("-", "%%-"):gsub("%.", "%%.")
end

return string_utils
