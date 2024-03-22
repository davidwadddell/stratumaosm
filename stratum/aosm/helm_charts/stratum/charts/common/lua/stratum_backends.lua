local stratum_logging = require('stratum_logging')
local string_utils = require('string_utils')

local stratum_backends = {}

------
-- Checks if the request should just be routed directly to the local backend.
-- This is determined by checking the 'req.proxy_origin' txn variable. This is
-- set if the 'stratum-partition-origin' header is set. This indicates that the
-- request has been forwarded from another HAProxy. We can only allow at most 1-hop
-- from one HAProxy instance to another, and then we must route directly to the
-- ILDs.
--
-- The exception to this is when the local backend is down, in which case we see if
-- there are other spares available to handle the request.
--
-- @param txn The HAProxy transaction context.
--
-- @param local_backend_obj The local HAProxy backend object that routes directly to the ILDs.
--
-- @param proxy_origin_site The site from where haproxy forwarded the request.
--
-- @return true If the local backend is available and can handle requests.
--
function stratum_backends.check_if_request_should_be_routed_to_local(txn, local_backend_obj, proxy_origin_site)
  if stratum_logging.is_tracing_enabled(txn) then
    local c = core.concat()
    c:add("The request has been routed from another ingress in site [")
    c:add(proxy_origin_site)
    c:add("]")
    stratum_logging.trace(txn, c:dump())
  end

  --[[
    We must route this request to the local backend, but first
    check if the local backend is available.
  ]]
  if stratum_backends.is_backend_available(txn, local_backend_obj) then
    if stratum_logging.is_tracing_enabled(txn) then
      local cn = core.concat()
      cn:add("The request will now be routed directly to the local backend [")
      cn:add(local_backend_obj:get_name())
      cn:add("]")
      stratum_logging.trace(txn, cn:dump())
    end

    -- The local backend is available, so we'll use it.
    return true
  else
    local url = txn:get_var("req.url")
    local client_ip = txn:get_var("req.client_ip")
    local client_port = txn:get_var("req.client_port")
    local http_method = txn:get_var("req.method")

    local cn = core.concat()
    cn:add("The [")
    cn:add(http_method)
    cn:add("] request [")
    cn:add(url)
    cn:add("] from client [")
    cn:add(client_ip)
    cn:add("]:")
    cn:add(client_port)
    cn:add(" cannot be routed to the local backend as it has no available servers.")

    stratum_logging.warning_log(txn, cn:dump())
  end

  return false
end

------
-- Checks the server stats to check if the server has state UP
--
-- @param txn The HAProxy transaction context.
--
-- @param backend The HAProxy backend.
--
-- @param server The server that belongs to the backend.
--
-- @return true If the server has state UP, otherwise false.
--
function stratum_backends.is_server_up(txn, backend, server)
  local server_stats = server:get_stats()
  if server_stats then
    local status = server_stats["status"]
    if status and status == "UP" then
      if stratum_logging.is_tracing_enabled(txn) then
        local c = core.concat()
        c:add("The server [")
        c:add(server:get_name())
        c:add("] in backend [")
        c:add(backend:get_name())
        c:add("] is available: [")
        c:add(status)
        c:add("]")

        stratum_logging.trace(txn, c:dump())
      end

      return true
    else
      if stratum_logging.is_tracing_enabled(txn) then
        -- Use trace logging to avoid log spamming.
        local c = core.concat()
        c:add("The server [")
        c:add(server:get_name())
        c:add("] in backend [")
        c:add(backend:get_name())
        c:add("] is not available: [")
        c:add(status)
        c:add("]")

        stratum_logging.trace(txn, c:dump())
      end
    end
  end

  return false
end

------
-- Checks if at least one server in the backend is reported as UP.
--
-- @param txn The HAProxy transaction context.
--
-- @param backend The HAProxy backend object containing the servers and their stats.
--
-- @return true if the backend has at least one server UP.
--
function stratum_backends.is_backend_available(txn, backend)
  local is_available = false

  local servers = backend.servers
  if servers then
    for _, server in pairs(servers) do
      if stratum_backends.is_server_up(txn, backend, server) then
        -- At least one server is available, so we can route to this backend.
        return true
      end
    end
  end

  return is_available
end

------
-- Check all the backends to find a matching site.
--
-- @param txn The HAProxy transaction context.
--
-- @param site_name The name of the site.
--
-- @param local_backend_obj The local HAProxy backend object that routes directly to the ILDs.
--
-- @param not_found_backend The backend to use when a valid backend cannot be used.
--
-- @return The backend to use, or nil if there is no match.
--
function stratum_backends.get_backend(txn, site_name, local_backend_obj, not_found_backend)
  for _, backend in pairs(core.backends) do
    local backend_name = backend:get_name()

    --[[
      Strip out the backend prefix so we're just left with the:
            <site_name>-ingress
      portion of the backend name. Then we can compare that against the site_name.
    ]]
    local ingress_concat = core.concat()
    local site_name_pattern = string_utils.escape_pattern(site_name)
    ingress_concat:add(site_name_pattern)
    ingress_concat:add("%-ingress")
    local ingress_backend = backend_name:match((ingress_concat:dump()))

    if ingress_backend then
      local site_pattern = string_utils.escape_pattern(site_name)
      if ingress_backend:match(site_pattern) then
        -- Found a matching backend.
        if stratum_logging.is_tracing_enabled(txn) then
          local c = core.concat()
          c:add("Found a matching backend [")
          c:add(backend_name)
          c:add("] for site [")
          c:add(site_name)
          c:add("]")
          stratum_logging.trace(txn, c:dump())
        end

        if stratum_backends.is_backend_available(txn, backend) then
          return backend_name
        else
          -- No servers listed in this backend
          local url = txn:get_var("req.url")
          local client_ip = txn:get_var("req.client_ip")
          local client_port = txn:get_var("req.client_port")
          local http_method = txn:get_var("req.method")

          local cn = core.concat()
          cn:add("The [")
          cn:add(http_method)
          cn:add("] request to URL [")
          cn:add(url)
          cn:add("] from client [")
          cn:add(client_ip)
          cn:add("]:")
          cn:add(client_port)
          cn:add(" cannot be routed to backend [")
          cn:add(backend:get_name())
          cn:add("] as it has no available servers. Check the haproxy container logs to determine why the backend is not available.")
          stratum_logging.warning_log(txn, cn:dump())

          -- Is this the local backend? If so we must reject the request.
          if backend_name == local_backend_obj:get_name() then
            txn:set_var("req.unavailable_partition", backend_name)
            return not_found_backend
          end
        end

      end
    end

  end

  return nil
end

------
-- Check the imsi against the pattern. The imsi must be a full match, not a
-- partial match. For example, the imsi
--    12345678
-- would partially match again the pattern:
--    %d%d%d
-- which just matches 3 digits. In this case the match would be 123, but since
-- 123 != 12345678 then it's only a partial match.
--
-- @param imsi The imsi number to match.
--
-- @param pattern The pattern to match the imsi against.
--
-- @return True or false
--
function stratum_backends.matches_imsi_pattern(imsi, pattern)
  local imsi_number = imsi:match(pattern)
  if imsi_number then
    -- We have a match, but we need to determine if it's an exact match.
    if imsi_number == imsi then
      -- This is an exact match.
      return true
    end
  end

  return false
end

------
-- Picks a partition for the request by checking the IMSI against the configured
-- partition mappings.
--
-- @param txn The HAProxy transaction context.
--
-- @param imsi The IMSI that has been extracted from the request.
--
-- @param mappings The configured partition mappings to check the IMSI against.
--
-- @param proxy_origin_site The name of the remote site that has forwarded the request,
--                          or nil if the request comes directly from the client.
--
-- @param local_backend_obj The local HAProxy backend object that routes directly to the ILDs.
--
-- @param not_found_backend The backend to use when a valid backend cannot be used.
--
-- @return (num_partitions, backend) where
--        num_partitions - Is the number of partitions that were matched and checked.
--        backend - The backend to route the request to, or nil if there are no available backends.
--
function stratum_backends.check_mappings(txn, imsi, mappings, proxy_origin_site, local_backend_obj, not_found_backend)
  -- Record the number of partitions that mapped to the IMSI and that were checked.
  local num_partitions_checked = 0

  for pattern, sites_and_priorities in pairs(mappings) do

    if stratum_backends.matches_imsi_pattern(imsi, pattern) then
      --[[
        We found a matching pattern. Check all associated sites, which
        have been ordered by priority.
      ]]
      for _, sites in pairs(sites_and_priorities) do
        local priority = sites[1]
        local site_name = sites[2]

        if stratum_logging.is_tracing_enabled(txn) then
          local c = core.concat()
          c:add("Checking site [")
          c:add(site_name)
          c:add("] with priority [")
          c:add(priority)
          c:add("]")
          stratum_logging.trace(txn, c:dump())
        end

        local site_name_pattern = string_utils.escape_pattern(site_name)
        if proxy_origin_site ~= nil and proxy_origin_site:match(site_name_pattern) then
          -- The request came from this site, so don't send it back!
          -- Check the next site.
          if stratum_logging.is_tracing_enabled(txn) then
            local c = core.concat()
            c:add("We cannot route the request back to ")
            c:add(site_name)
            c:add(" as this is where we received it from")
            stratum_logging.trace(txn, c:dump())
          end
        else

          num_partitions_checked = num_partitions_checked + 1

          -- Is the backend for this site available?
          local backend = stratum_backends.get_backend(txn, site_name, local_backend_obj, not_found_backend)
          if backend then
            return num_partitions_checked, backend
          end
        end

      end
    end
  end

  -- No backend found!
  return num_partitions_checked, nil
end

------
-- This function will:
--
--  1. Try to match the imsi against one of the configured patterns.
--  2. If a match is found then select the priority backend and
--     determine if it is available for requests.
--  3. If the request has been forwarded from another HAProxy instance,
--     then the local partition must be selected if it is available.
--
-- @param txn The HAProxy transaction context.
--
-- @param local_backend_obj The local HAProxy backend object that routes directly to the ILDs.
--
-- @param imsi The IMSI that has been extracted from the request.
--
-- @param mappings The configured partition mappings to check the IMSI against.
--
-- @param not_found_backend The backend to use when a valid backend cannot be used.
--
-- @return (num_partitions, backend) where
--        num_partitions - Is the number of partitions that were matched and checked.
--        backend - The backend to route the request to, or nil if:
--                  1. The request does not map to any partition.
--                  2. The partition(s) is unavailable (down).
--
function stratum_backends.get_active_backend(txn, local_backend_obj, imsi, mappings, not_found_backend)
  --[[
    Tracks if we received this request from a haproxy in another site.
    If set:
      1. then we can never route back to that site.
      2. We must now route directly to the local partition.
  ]]
  local proxy_origin_site = txn:get_var("req.proxy_origin")

  if proxy_origin_site ~= nil then
    local should_route_directly_to_local = stratum_backends.check_if_request_should_be_routed_to_local(
        txn, local_backend_obj, proxy_origin_site)

    if should_route_directly_to_local then
      -- The local backend is available, so we'll use it.
      return 1, local_backend_obj:get_name()
    else
      -- The local backend is not available, so reject the request.
      txn:set_var("req.unavailable_partition", not_found_backend)
      return 0, not_found_backend
    end
  end

  -- Find a backend that has available servers.
  local num_partitions_checked, backend = stratum_backends.check_mappings(txn, imsi, mappings, proxy_origin_site,
      local_backend_obj, not_found_backend)

  return num_partitions_checked, backend
end

return stratum_backends
