--[[

  The Stratum HAProxy plugin.

]]

local base64 = require('base64')
local stratum_logging = require('stratum_logging')
local stratum_mappings = require('stratum_mappings')
local stratum_backends = require('stratum_backends')

--[[
  The partition mappings file.
]]
local mapping_file = "/etc/opwv/site_mapping.txt"

local stratum = {}

-- For testing so we can check the number of imsi matches required.
local num_pattern_matches = 0

--[[
  The name of the backend service that we use when an IMSI is not matched
  against any of the available partitions.
]]
local not_found_backend = ""

--[[
  The key is the site name, and the value is an array of IMSI patterns.
]]
local site_mappings = {}

--[[
  The mappings object that holds the partition mappings.
]]
local mappings

--[[
  We store the name of the local backend here, so that we can route requests
  directly to the local backend/partition.
]]
local local_backend_name = ""

-- The local backend object
local local_backend_obj = nil

local local_site = ""

------
-- Get the IMSI from the POST body. The IMSI will be stored in the
-- 'req.imsi' field in the txn object.
--
-- @param txn The HAProxy transaction context.
--
function stratum.get_imsi_from_post(txn, http_method)
  local body = txn:get_var("req.body")

  if body ~= nil and body:len() ~= 0 then

    local imsi = string.match(body, "imsi%-(%d+)")
    if imsi == nil then
      -- Convert the entire body to lowercase and try the match again.
      body = body:lower()
      imsi = string.match(body, "imsi%-(%d+)")
    end

    if imsi ~= nil then
      --[[
        Store the IMSI in req.imsi so that we can use it in the
        HAProxy frontend rules to select the correct backend.
      ]]
      stratum.store_imsi(txn, imsi)
    else
        local client_ip = txn:get_var("req.client_ip")
        local client_port = txn:get_var("req.client_port")
        local url = txn.get_var(txn, "req.url")
        if client_ip ~= nil and url ~= nil then
          local c = core.concat()
          c:add("The IMSI cannot be found in the body of the [")
          c:add(http_method)
          c:add("] request for [")
          c:add(url)
          c:add("] from client [")
          c:add(client_ip)
          c:add("]:")
          c:add(client_port)

          stratum_logging.warning_log(txn, c:dump())
        end
    end

  else

    if stratum_logging.is_tracing_enabled(txn) then
      local client_ip = txn:get_var("req.client_ip")
      local client_port = txn:get_var("req.client_port")
      local url = txn.get_var(txn, "req.url")
      if client_ip ~= nil and url ~= nil then
        local c = core.concat()
        c:add("The [")
        c:add(http_method)
        c:add("] request for [")
        c:add(url)
        c:add("] from client [")
        c:add(client_ip)
        c:add("]:")
        c:add(client_port)
        c:add(" contains no body. The IMSI cannot be determined.")

        stratum_logging.trace(txn, c:dump())
      end
    end

  end
end

------
-- This function will try to extract a base64 encoded string at the end of a request path.
-- We assume that the encoded string is in the last part of the path, so we look for the
-- last '/' character and extract the string to the right of it. For example:path
--      /nudr-dr/v2/subscription-data/subs-to-notify/eyJpZCI6IjAwMDA
-- where the encoded string here is:
--     eyJpZCI6IjAwMDA
-- (note the above is truncated for brevity).
--
-- When the encoded string is extracted, then we attempt a base64 decode on it. When decoded
-- we then extract the IMSI and store it in 'req.imsi'.
--
-- @param txn The HAProxy transaction context.
--
function stratum.get_imsi_from_base64_encoded_path(txn)
  -- Get the path provided by HAProxy.
  local path = txn.get_var(txn, "req.path")
  if path == nil then
    stratum_logging.log_imsi_missing(txn)
    return
  end

  -- Find the index of the last '/' character in the URL path.
  local index = path:find("/[^/]*$")
  if index == nil then
    stratum_logging.log_imsi_missing(txn)
    return
  end

  -- Extract the string after the last '/'
  local encoded_path = path:sub(index + 1)
  if encoded_path:len() == 0 or encoded_path == "" then
    stratum_logging.log_imsi_missing(txn)
    return
  end

  -- The string should be base64 encoded and contain the IMSI, so we must decode it.
  local decoded_path = base64.decode(encoded_path, nil, nil)

  local imsi = stratum.get_imsi_from_path(txn, decoded_path)
  if imsi ~= nil then
    stratum.store_imsi(txn, imsi)
  else
    stratum_logging.log_imsi_missing(txn)
  end
end

------
-- Store the IMSI in the txn object.
--
-- @param txn The HAProxy transaction context.
--
-- @param imsi The client IMSI.
--
function stratum.store_imsi(txn, imsi)
  txn:set_var("req.imsi", imsi)
end

------
-- Check the IMSI mappings to select the correct partition for the
-- provided IMSI.
--
-- @param txn The HAProxy transaction context.
--
-- @param imsi The client IMSI.
--
-- @param mapping_patterns The site mapping patterns.
--
-- @return (num_partitions, backend) where
--    num_partitions - Is the number of partitions that were matched and checked.
--    backend - The backend to use, or nil if there is no match.
--
function stratum.select_partition_for_imsi(txn, imsi, mapping_patterns)
  if imsi:len() == 5 then
    -- Pad out the IMSI with the leading zero's
    local c = core.concat()
    c:add("0000000000")
    c:add(imsi)
    imsi = c:dump()
  end

  local num_partitions, backend = stratum_backends.get_active_backend(
      txn, local_backend_obj, imsi, mapping_patterns, not_found_backend)

  return num_partitions, backend
end

--[[ testing only
function stratum.get_num_pattern_matches()
  return num_pattern_matches
end
]]

------
-- Get the port number from an address. For IPv4 the address will be in the format:
--    127.0.0.1:<port>
-- For IPv6:
--    [::1]:<port>
--
-- @param addr The IP and port.
--
-- @return The port number
--
function stratum.get_port_from_addr(addr)
  local index = addr:match('^.*:(%d+)$')
  return index
end

------
-- Determine the backend that maps to the local partition.
--
-- @param txn The HAProxy transaction context.
--
-- @return message The local backend.
--
function stratum.route_to_local_partition(txn)
  local is_health_check = txn:get_var("req.is_health_check")
  if is_health_check then
    -- Do not log the health checks as they can spam the logs.
    return local_backend_name
  end

  local http_method = txn:get_var("req.method")
  local url = txn:get_var("req.url")
  local client_ip = txn:get_var("req.client_ip")
  local client_port = txn:get_var("req.client_port")

  if stratum_logging.is_tracing_enabled(txn) then
    local c = core.concat()
    c:add("Routing [")
    c:add(http_method)
    c:add("] request [")
    c:add(url)
    c:add("] from client [")
    c:add(client_ip)
    c:add("]:")
    c:add(client_port)
    c:add(" to the local partition [")
    c:add(local_backend_name)
    c:add("].")
    stratum_logging.trace(txn, c:dump())
  end

  return local_backend_name
end

function stratum.get_imsi_from_path(txn, path)
  local lower_path = path:lower()

  local imsi = string.match(lower_path, "imsi%-(%d+)")
  if imsi then
    if stratum_logging.is_tracing_enabled(txn) then
      local c = core.concat()
      c:add("IMSI ")
      c:add(imsi)
      c:add(" found in path ")
      c:add(path)

      stratum_logging.trace(txn, c:dump())
    end

    return imsi
  end

  return nil
end

function stratum.trace_sending_to_local_partition(txn, http_method, url, client_ip, client_port)
  if stratum_logging.is_tracing_enabled(txn) then
    local is_udsf = txn:get_var("req.is_udsf")
    local is_health_check = txn:get_var("req.is_health_check")
    local is_msisdn = txn:get_var("req.is_msisdn")

    local c = core.concat()

    if is_udsf ~= nil then
      c:add("The UDSF [")
      c:add(http_method)
      c:add("] request [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" will be routed to the local partition.")
      stratum_logging.trace(txn, c:dump())
    elseif is_health_check ~= nil then
      -- A health check request.
      c:add("The health check request [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" will be routed to the local partition.")
      stratum_logging.trace(txn, c:dump())
    elseif is_msisdn ~= nil then
      -- A MSISDN request.
      c:add("The MSISDN [")
      c:add(http_method)
      c:add("] request [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" will be routed to the local partition.")
      stratum_logging.trace(txn, c:dump())
    else
      c:add("The [")
      c:add(http_method)
      c:add("] request [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" will be routed to the local partition.")
      stratum_logging.trace(txn, c:dump())
    end
  end
end

function stratum.update_partition_hdr(txn)
  local hdrs = txn.http:req_get_headers()
  local origins_hdrs = hdrs["stratum-partition-origin"]
  local hdr_set = false

  if origins_hdrs then
    local existing_origin = origins_hdrs[0]
    if existing_origin then
      local c = core.concat()
      c:add(existing_origin)
      c:add(";") -- Delimited by a semi-colon.
      c:add(local_site)
      txn.http:req_set_header("stratum-partition-origin", c:dump())
      hdr_set = true
    end
  end

  if not hdr_set then
    txn.http:req_set_header("stratum-partition-origin", local_site)
  end

end

--[[
  Public functions registered with HAProxy
]]

------
-- Extracts the IMSI from a URL.
-- The IMSI will be stored in:
--    'req.imsi'
--
-- @param URL The URL path passed in by HAProxy
--
function get_imsi_from_url(txn)
  -- Convert the URL to lowercase first.
  local url = txn:get_var("req.url")
  local lower_url = url:lower()

  local http_method = txn:get_var("req.method")
  local client_ip = txn:get_var("req.client_ip")
  local client_port = txn:get_var("req.client_port")

  --[[ Check for IMSI's contained within the path or query parameters. For example:
        /nudr-dr/v2/subscription-data/imsi-310950111000045/context-data
        /nudr-dr/v2/subscription-data/imsi-310950111000045
        /nudr-dr/v2/subscription-data/subs-to-notify?ue-id=imsi-310950111000045
  ]]
  local imsi = string.match(lower_url, "imsi%-(%d+)")
  if imsi then
    if stratum_logging.is_tracing_enabled(txn) then
      local c = core.concat()
      c:add("IMSI [")
      c:add(imsi)
      c:add("] found in [")
      c:add(http_method)
      c:add("] request to URL ")
      c:add(url)
      c:add(" from [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      stratum_logging.trace(txn, c:dump())
    end
    stratum.store_imsi(txn, imsi)
  else
    if stratum_logging.is_tracing_enabled(txn) then
      local c = core.concat()
      c:add("No IMSI detected in the [")
      c:add(http_method)
      c:add("] request to URL [")
      c:add(url)
      c:add("] from [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      stratum_logging.trace(txn, c:dump())
    end
  end

end

------
-- Selects a partition based on the IMSI.
-- The IMSI is stored as 'req.imsi'
--
-- @param txn The HAProxy transaction context.
--            This MUST contain the req.imsi entry.
--
function find_partition(txn)
  local http_method = txn:get_var("req.method")
  local url = txn:get_var("req.url")
  local client_ip = txn:get_var("req.client_ip")
  local client_port = txn:get_var("req.client_port")

  local num_mappings = mappings:get_number_of_mappings()
  if num_mappings == 0 then
    -- There's no partition mapping at all, so all requests must go to the local backend.
    return stratum.route_to_local_partition(txn)
  end

  -- Decide if we need to route to the local partition first.
  local local_partition_only = txn:get_var("req.local_partition_only")
  local is_msisdn = txn:get_var("req.is_msisdn")
  if local_partition_only ~= nil or is_msisdn ~= nil then
    stratum.trace_sending_to_local_partition(txn, http_method, url, client_ip, client_port)
    return stratum.route_to_local_partition(txn)
  end

  -- If there's no IMSI in the request (path or body), then we route to the local partition.
  local imsi = txn:get_var("req.imsi")
  if imsi == nil then
    -- Check the PATH to determine if the IMSI is base64 encoded in the path.
    stratum.get_imsi_from_base64_encoded_path(txn)

    imsi = txn:get_var("req.imsi")
    if imsi == nil then
      if stratum_logging.is_tracing_enabled(txn) then
        local c = core.concat()
        c:add("The [")
        c:add(http_method)
        c:add("] request [")
        c:add(url)
        c:add("] from client [")
        c:add(client_ip)
        c:add("]:")
        c:add(client_port)
        c:add(" does not contain an IMSI, and will be sent to the local partition only.")

        stratum_logging.trace(txn, c:dump())
      end

      -- No IMSI found, so we go to the local partition/backend.
      return stratum.route_to_local_partition(txn)
    end
  end

  if stratum_logging.is_tracing_enabled(txn) then
    local c = core.concat()
    c:add("Using IMSI [")
    c:add(imsi)
    c:add("] for [")
    c:add(http_method)
    c:add("] request [")
    c:add(url)
    c:add("] from client [")
    c:add(client_ip)
    c:add("]:")
    c:add(client_port)
    stratum_logging.trace(txn, c:dump())
  end

  -- Find a backend/partition for this IMSI.
  local num_partitions, backend = stratum.select_partition_for_imsi(txn, imsi, site_mappings)
  if backend ~= nil then

    if stratum_logging.is_tracing_enabled(txn) then
      local c = core.concat()
      c:add("Selecting partition [")
      c:add(backend)
      c:add("] for [")
      c:add(http_method)
      c:add("] request to URL [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" with IMSI [")
      c:add(imsi)
      c:add("]")
      stratum_logging.trace(txn, c:dump())
    end

  else
    --[[
      If this request maps to partitions, but they are all offline then we should
      reject the request.

      If the request does not map to any partitions then we send it to the local
      ILDs and let them decide what to do with it.
    ]]
    if num_partitions > 0 then
      -- We matched at least one partition and they are not available, return a 503.
      local c = core.concat()
      c:add("The [")
      c:add(http_method)
      c:add("] request to URL [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)
      c:add(" cannot be routed to its defined partition or backup as they are unavailable.")
      stratum_logging.alert_log(txn, c:dump())

      -- Set the backend to the 503 backend service.
      backend = not_found_backend

      -- Record that the partitions are not available. This will be made available to
      -- the partition not found service that is handled by the partition_not_found function.
      txn:set_var("req.partitions_not_available", "true")
    else
      --[[
        If there's no mapping for a request then we should send to the local backend.
        The Stratum ILDs can then determine how the request should be handled.
      ]]
      backend = stratum.route_to_local_partition(txn)

      if stratum_logging.is_tracing_enabled(txn) then
        local c = core.concat()
        c:add("The [")
        c:add(http_method)
        c:add("] request to URL [")
        c:add(url)
        c:add("] from client [")
        c:add(client_ip)
        c:add("]:")
        c:add(client_port)
        c:add(" does not map to any partition and will be sent to the local backend.")
        stratum_logging.trace(txn, c:dump())
      end
    end

  end

  return backend
end

function select_partition(txn)
  local is_health_check = txn:get_var("req.is_health_check")

  local backend = find_partition(txn)
  if backend then
    if not is_health_check then
      -- Record the backend that we're sending the request to.
      txn.http:req_add_header("stratum-partition-site", backend)
    end
  end

  -- Record where the proxy request originates from.
  if not is_health_check then
    stratum.update_partition_hdr(txn)
  end

  return backend
end

------
-- For GET requests we extract the IMSI from the path/query. If the IMSI still
-- isn't found in the GET request, then we check the last part of the path for
-- a base64 encoded subscriber id.
--
-- For DELETE requests the IMSI is base64 encoded in the path. The encoded path
-- fragment must be extracted and decoded so that we can determine the IMSI.
--
-- For POST requests the IMSI is in the request body.
--
-- @param txn The HAProxy transaction context.
--
function scan_request_for_imsi(txn)
  -- Do we already have the IMSI?
  local imsi = txn:get_var("req.imsi")
  if imsi ~= nil  and stratum_logging.is_tracing_enabled(txn) then
    local c = core.concat()
    c:add("Skipping scan_request_for_imsi as we already have the IMSI: ")
    c:add(imsi)
    stratum_logging.trace(txn, c:dump())
    return
  end

  local is_msisdn = txn:get_var("req.is_msisdn")
  if is_msisdn then
    -- Go straight to the local partition.
    return
  end

  local http_method = txn:get_var("req.method")
  http_method = http_method:upper()

  if http_method == "DELETE" then
    -- Try to get the IMSI from the base64 encoded path.
    stratum.get_imsi_from_base64_encoded_path(txn)
  elseif http_method == "POST" or http_method == "PUT" then
    -- Get the IMSI from the POST body.
    stratum.get_imsi_from_post(txn, http_method)
  elseif http_method == "GET" or http_method == "PATCH" then
    -- Get the IMSI from the URL path.
    get_imsi_from_url(txn)
  else
    local url = txn:get_var("req.url")
    local client_ip = txn:get_var("req.client_ip")
    local client_port = txn:get_var("req.client_port")

    local c = core.concat()
    c:add("Unsupported HTTP method [")
    c:add(http_method)
    c:add("] in scan_request_for_imsi for URL [")
    c:add(url)
    c:add("] from client [")
    c:add(client_ip)
    c:add("]:")
    c:add(client_port)
    stratum_logging.warning_log(txn, c:dump())
  end
end

--[[
  Loads the site and IMSI mappings.
]]
function load_imsi_mappings()
  site_mappings = {}

  core.Info("Available backends:")
  for _, backend in pairs(core.backends) do
    local backend_type = backend:get_cap()
    if backend ~= nil then
      local backend_name = backend:get_name()
      if backend_type and backend_type == "backend" then
        core.Info(string.format("  Backend: %s", backend_name))
      end

      -- Find the backend name for the 'no-partition' service.
      if backend_name:match("no%-partition") then
        not_found_backend = backend_name
      end
    end
  end

  if not_found_backend ~= "" then
    core.Info(string.format("Partition not found service backend: %s", not_found_backend))
  else
    core.Alert("The backend for the partition not found service could not be found in haproxy.cfg")
  end

  core.Info("Loading the IMSI partition mappings from file: " .. mapping_file)
  mappings = stratum_mappings:new(mapping_file)
  site_mappings = mappings:get_mappings()
  mappings:log_mappings(mapping_file)

  local number_of_mappings =  mappings:get_number_of_mappings()
  if number_of_mappings == 0 then
    core.Info("No Stratum partition mappings have been configured. All requests will be sent to the local partition.")
  else
    core.Info("All Stratum partition mappings loaded.")
  end

  core.Info("ENEA Stratum HAProxy Lua plugin loaded.")
end

------
-- Examines all the configured backends to determine which is the local one.
-- We select the backend that has 'ingress-local' in its name.
--
local function determine_local_partition()
  for _, backend in pairs(core.backends) do
    local backend_name = backend:get_name()
    local backend_type = backend:get_cap()

    if backend_type and backend_type == "backend" then
      if backend_name:match("ingress%-local") then
        local_backend_name = backend_name
        local_backend_obj = backend
        core.Debug("Detecting the local backend/partition [" .. local_backend_name .. "]")
        break
      end
    end
  end

  if local_backend_name == ""  or local_backend_name == nil then
    core.Alert("Failed to detect a local backend")
  end

  -- Determine the local site.
  local_site = mappings:find_matching_site(local_backend_name)
  if local_site then
    core.Debug("Detecting the local site as [" .. local_site .. "]")
  else
    core.Alert("Failed to determine the local site.")
  end

end

local function create_partitions_not_available_message(client_ip, client_port, url, imsi, uuid)
  local response

  if url and client_ip then
    if imsi then
      response = [==[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [%s]:%s to URL: <pre>%s</pre>
          with IMSI [%d] cannot be routed to any partition - the partitions are unavailable.</p>
          <pre>uuid: %s</pre>
          </body></html>
          ]==]
      response = string.format(response, client_ip, client_port, url, imsi, uuid)
    else
      response = [==[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [%s]:%s to URL: <pre>%s</pre>
          cannot be routed to any partition - the partitions are unavailable.</p>
          <pre>uuid: %s</pre>
          </body></html>
          ]==]
      response = string.format(response, client_ip, client_port, url, uuid)
    end
  else
    response = [==[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to any partition - the partitions are unavailable.</p>
        <pre>uuid: %s</pre>
        </body></html>
        ]==]
    response = string.format(response, uuid)
  end

  return response
end

local function create_ilds_not_available_message(client_ip, client_port, url, imsi, be, uuid)
  local response

  if url and client_ip then
    if imsi then
      response = [==[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [%s]:%s to URL: <pre>%s</pre>
          with IMSI [%d] cannot be routed to the local partition [%s] - All ILDs are unavailable.</p>
          <pre>uuid: %s</pre>
          </body></html>
          ]==]
      response = string.format(response, client_ip, client_port, url, imsi, be, uuid)
    else
      response = [==[
          <html><head><title>Stratum</title></head>
          <body><h1>503 Service Unavailable</h1>
          <p>The request from client [%s]:%s to URL: <pre>%s</pre>
          cannot be routed to the local partition [%s] - All ILDs are unavailable.</p>
          <pre>uuid: %s</pre>
          </body></html>
          ]==]
      response = string.format(response, client_ip, client_port, url, be, uuid)
    end
  else
    response = [==[
        <html><title>Stratum</title>
        <head><title>Stratum</title></head>
        <body><h1>503 Service Unavailable</h1>
        <p>Invalid request: The request could not be routed to the partition [%s] - All ILDs are unavailable.</p>
        <pre>uuid: %s</pre>
        </body></html>
        ]==]
    response = string.format(response, be, uuid)
  end

  return response
end

------
-- A HAProxy service that sends back an error message and status code
-- when a request is made that:
--    1. The local partition is not available - all ILDs are down.
--
-- @param applet The HAProxy applet.
--
function partition_not_found(applet)
  local url = applet:get_var("req.url")
  local client_ip = applet:get_var("req.client_ip")
  local client_port = applet:get_var("req.client_port")
  local imsi = applet:get_var("req.imsi")

  local be = applet:get_var("req.unavailable_partition")
  if be == nil then
    be = ""
  end

  local uuid = applet:get_var("req.existing_uuid")
  if uuid == nil or uuid == "" then
    uuid = applet:get_var("req.uuid")
  end

  if uuid == nil then
    uuid = ""
  end

  local partitions_not_available = applet:get_var("req.partitions_not_available")

  local response
  if partitions_not_available ~= nil and partitions_not_available == "true" then
    response = create_partitions_not_available_message(client_ip, client_port, url, imsi, uuid)
  else
    response = create_ilds_not_available_message(client_ip, client_port, url, imsi, be, uuid)
  end

  applet:set_status(503, "Service Unavailable")
  applet:add_header("Content-Length", string.len(response))
  applet:add_header("Content-Type", "text/html")
  applet:add_header("Cache-Control", "no-cache")

  if uuid ~= nil then
    applet:add_header("stratum-partition-uuid", uuid)
  end

  applet:start_response()
  applet:send(response)
end

--[[
  Register our functions with HAProxy.
]]
core.register_init(load_imsi_mappings)
core.register_init(determine_local_partition)
core.register_fetches("select_partition", select_partition)
core.register_action("get_imsi_from_url", {"http-req"}, get_imsi_from_url, 0)
core.register_action("scan_request_for_imsi", {"http-req"}, scan_request_for_imsi, 0)
core.register_service("partition_not_found", "http", partition_not_found)


--[[
  For testing only.
]]
function load_test_mappings(site_mapping_file)
  mappings = stratum_mappings:new(site_mapping_file)
  site_mappings = mappings:get_mappings()
  determine_local_partition()
  local number_of_mappings =  mappings:get_number_of_mappings()

  core.Info("Available backends:")
  for _, backend in pairs(core.backends) do
    local backend_type = backend:get_cap()
    if backend ~= nil then
      local backend_name = backend:get_name()
      if backend_type and backend_type == "backend" then
        core.Info(string.format("  Backend: %s", backend_name))
      end

      -- Find the backend name for the 'no-partition' service.
      if backend_name:match("no%-partition") then
        not_found_backend = backend_name
      end
    end
  end

  if not_found_backend ~= "" then
    core.Info(string.format("Partition not found service backend: %s", not_found_backend))
  else
    core.Alert("The backend for the partition not found service could not be found in haproxy.cfg")
  end

  if number_of_mappings == 0 then
    core.Info("No Stratum partition mappings have been configured. All requests will be sent to the local partition.")
  else
    core.Info("All Stratum partition mappings loaded.")
  end

  core.Info("ENEA Stratum HAProxy Lua plugin loaded.")
end

function get_site_mappings()
  return site_mappings
end

function set_local_backend(backend)
  local_backend_name = backend
end

return stratum

-- END
