local stratum_logging = {}

------
-- Get the UUID from the current request. It's either an existing uuid sent
-- from a remote haproxy instance, or a new uuid set by the current haproxy
-- instance.
--
-- @param txn The HAProxy transaction context.
--
-- @return The uuid
--
local function get_uuid(txn)
  -- Try to use an existing uuid if one has already been defined.
  local uuid = txn:get_var("req.existing_uuid")
  if uuid == nil or uuid == "" then
    uuid = txn:get_var("req.uuid")
  end
  return uuid
end

------
-- Generates a debug log prefixed with the UUID
--
-- @param txn The HAProxy transaction context.
-- @param message The debug message.
--
function stratum_logging.debug_log(txn, message)
  local uuid = get_uuid(txn)

  local c = core.concat()
  c:add("[uuid=")
  c:add(uuid)
  c:add("] ")
  c:add(message)

  txn:Debug(c:dump())
end

------
-- Generates an alert log prefixed with the UUID
--
-- @param txn The HAProxy transaction context.
-- @param message The debug message.
--
function stratum_logging.alert_log(txn, message)
  local uuid = get_uuid(txn)

  local c = core.concat()
  c:add("[uuid=")
  c:add(uuid)
  c:add("] ")
  c:add(message)

  txn:Alert(c:dump())
end

------
-- Generates a warning log prefixed with the UUID
--
-- @param txn The HAProxy transaction context.
-- @param message The debug message.
--
function stratum_logging.warning_log(txn, message)
  local uuid = get_uuid(txn)

  local c = core.concat()
  c:add("[uuid=")
  c:add(uuid)
  c:add("] ")
  c:add(message)

  txn:Warning(c:dump())
end

------
-- Logs a warning if the IMSI cannot be found within the request.
--
-- @param txn The HAProxy transaction context.
--
function stratum_logging.log_imsi_missing(txn)
  if stratum_logging.is_tracing_enabled(txn) then
    local url = txn:get_var("req.url")
    local client_ip = txn:get_var("req.client_ip")
    local client_port = txn:get_var("req.client_port")
    local http_method = txn:get_var("req.method")
    local uuid = get_uuid(txn)

    if url and client_ip and http_method then
      local c = core.concat()
      c:add("[uuid=")
      c:add(uuid)
      c:add("] No IMSI found within the [")
      c:add(http_method)
      c:add("] request for URL [")
      c:add(url)
      c:add("] from client [")
      c:add(client_ip)
      c:add("]:")
      c:add(client_port)

      stratum_logging.trace(txn, c:dump())
    end
  end
end

function stratum_logging.trace(txn, message)
  local trace_enabled = txn:get_var("req.partition_trace_enabled")
  if trace_enabled then
    local uuid = get_uuid(txn)

    local c = core.concat()
    c:add("[uuid=")
    c:add(uuid)
    c:add("] [TRACE] ")
    c:add(message)

    txn:Info(c:dump())
  end
end

function stratum_logging.is_tracing_enabled(txn)
  local trace_enabled = txn:get_var("req.partition_trace_enabled")
  if trace_enabled then
    return true
  end
  return false
end

return stratum_logging
