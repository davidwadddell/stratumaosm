
local stratum_mappings = {}
local string_utils = require('string_utils')

------
-- Loads the partition mapping file and stores it as a table; mappings
--
-- @param mapping_file The mapping file to be loaded.
--
function stratum_mappings:new(mapping_file)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.mapping_file = mapping_file
  o.number_of_mappings = 0
  o.mappings = {}

  o:read_mapping_file()

  -- Count the number of partition mappings.
  for _, _ in pairs(o.mappings) do
    o.number_of_mappings = o.number_of_mappings + 1
  end

  return o
end

function stratum_mappings:get_mappings()
  return self.mappings
end

function stratum_mappings:read_mapping_file()
  core.Debug("Loading partition mapping file " .. self.mapping_file)

  local f = io.open(self.mapping_file, "rb")
  if f == nil then
    core.Alert("ERROR: Failed to open the IMSI mapping file: " .. self.mapping_file)
    return
  end

  for line in io.lines(self.mapping_file) do
    self:parse_partition_mapping_line(line)
  end

  f:close()
end

function stratum_mappings:parse_partition_mapping_line(line)
  -- Ignore lines starting with a comment.
  if line:match('^#') == nil then
    -- Match <site name>:<imsi pattern>:<priority number>
    local site_name, imsi_pattern, priority = line:match("^%s*(%g*)%s*:%s*(%g*)%s*:%s*(%d*)%s*$")
    if site_name and imsi_pattern and priority then

      local imsi_mapping = self.mappings[imsi_pattern]
      local site_priority = { priority, site_name }
      if imsi_mapping == nil then
        self.mappings[imsi_pattern] = {}
      end

      imsi_mapping = self.mappings[imsi_pattern]
      table.insert(imsi_mapping, site_priority)

      -- Order by priority
      table.sort(imsi_mapping, function(a, b)
        -- Comparing the priority values.
        return a[1] < b[1]
      end)

    end
  end
end

------
-- Logs all of the partition mappings.
--
-- @param mapping_file The mapping file that contains the partition mappings.
--
function stratum_mappings:log_mappings(mapping_file)
  core.Info("IMSI mappings from file: " .. mapping_file)
  for imsi_pattern, site_and_priority_mappings in pairs(self.mappings) do
    core.Info("IMSI pattern: " .. imsi_pattern)
    for _, site_and_priority in pairs(site_and_priority_mappings) do
      local priority = site_and_priority[1]
      local site_name = site_and_priority[2]
      core.Info("    Site = [" .. site_name .. "] - Priority = [" .. priority .. "]")
    end
  end
end

function stratum_mappings:find_matching_site(backend_name)
  for _, site_and_priority_mappings in pairs(self.mappings) do
    for _, site_and_priority in pairs(site_and_priority_mappings) do
      local site_name = site_and_priority[2]

      -- We're using the site name in a pattern search. Ensure that any reserved
      -- Lua 'magic characters' are escaped before applying the pattern.
      local site_pattern = string_utils.escape_pattern(site_name)

      if backend_name:match(site_pattern) then
        return site_name
      end
    end
  end

  return nil
end

function stratum_mappings:get_number_of_mappings()
  return self.number_of_mappings
end

return stratum_mappings

