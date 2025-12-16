local function loadSetting(object, key, defaultValue)
  if not object or not object.name or not key then
    return defaultValue
  end

  local value = hs.settings.get(object.name .. '.' .. key)

  return value ~= nil and value or defaultValue
end

return loadSetting