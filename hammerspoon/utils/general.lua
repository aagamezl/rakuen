-- Deep copy table
local function deepCopy(orig)
  local orig_type = type(orig)
  local copy

  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end

    setmetatable(copy, deepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end

  return copy
end

-- Find index of value in array
local function findIndex(array, value)
  if type(array) ~= 'table' then return nil end

  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end

  return nil
end

-- Get next index with wrap-around
local function getNextIndex(index, size, direction)
  if direction == 'right' or direction == 'down' then
    return (index % size) + 1
  else
    return (index - 2) % size + 1
  end
end

-- Check if array contains value
local function hasValue(array, value)
  return findIndex(array, value) ~= nil
end

-- Load setting with default value
local function loadSetting(object, key, defaultValue)
  if not object or not object.name or not key then
    return defaultValue
  end

  local value = hs.settings.get(object.name .. '.' .. key)

  return value ~= nil and value or defaultValue
end

-- Save setting
local function saveSetting(object, key, value)
  if not object or not object.name or not key then
    return false
  end

  hs.settings.set(object.name .. '.' .. key, value)
  object[key] = value

  return true
end

-- Ternary operator
local function ternary(condition, valueOnTrue, valueOnFalse)
  return condition and valueOnTrue or valueOnFalse
end

-- Throttle function calls
local function throttle(func, wait)
  local timer = nil
  local last = 0

  return function(...)
    local args = { ... } -- Capture the varargs
    local now = hs.timer.secondsSinceEpoch()

    if not timer and (now - last) >= wait then
      last = now
      return func(table.unpack(args))
    elseif not timer then
      timer = hs.timer.doAfter(wait - (now - last), function()
        timer = nil
        last = hs.timer.secondsSinceEpoch()
        func(table.unpack(args))
      end)
    end
  end
end

return {
  name = 'utils:general',

  deepCopy = deepCopy,
  findIndex = findIndex,
  getNextIndex = getNextIndex,
  hasValue = hasValue,
  loadSetting = loadSetting,
  saveSetting = saveSetting,
  ternary = ternary,
  throttle = throttle,
}