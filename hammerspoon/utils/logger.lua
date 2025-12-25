local logger = {
  name = 'Logger',
  isEnabled = true
}

function logger.log(message, scope)
  if logger.isEnabled then
    print("LOG[" .. scope .. "]: " .. message)
  end
end

function logger.info(message, scope)
  if logger.isEnabled then
    print("INFO[" .. scope .. "]: " .. message)
  end
end

function logger.warning(message, scope)
  if logger.isEnabled then
    print("WARNING[" .. scope .. "]: " .. message)
  end
end

function logger.error(message, scope)
  if logger.isEnabled then
    print("ERROR[" .. scope .. "]: " .. message)
  end
end


return logger
