local logger = {
  name = 'Logger',
  isEnabled = true
}

function logger.debug(message, scope)
  if logger.isEnabled then
    print("DEBUG[" .. scope .. "]: " .. hs.inspect(message))
  end
end

--- Logs a message
--- @param message string The message to log
--- @param scope string The scope of the logger
function logger.log(message, scope)
  if logger.isEnabled then
    print("LOG[" .. scope .. "]: " .. message)
  end
end

--- Logs a message with INFO level
--- @param message string The message to log
--- @param scope string The scope of the logger
function logger.info(message, scope)
  if logger.isEnabled then
    print("INFO[" .. scope .. "]: " .. message)
  end
end

--- Logs a warning message
--- @param message string The warning message to log
--- @param scope string The scope of the logger
function logger.warning(message, scope)
  if logger.isEnabled then
    print("WARNING[" .. scope .. "]: " .. message)
  end
end

--- Logs an error message
--- @param message string The error message to log
--- @param scope string The scope of the logger
function logger.error(message, scope)
  if logger.isEnabled then
    print("ERROR[" .. scope .. "]: " .. message)
  end
end

--- Enables or disables logging
--- @param enabled boolean Whether logging should be enabled
function logger.setEnabled(enabled)
  logger.isEnabled = enabled
end

--- Gets the current logging status
--- @return boolean Whether logging is currently enabled
function logger.getEnabled()
  return logger.isEnabled
end

return logger
