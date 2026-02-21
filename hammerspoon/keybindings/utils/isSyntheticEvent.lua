--- Check if the given event is a synthetic event
--- @param event hs.eventtap.event The event to check
--- @param tag number The tag to use to define synthetic events
local function isSyntheticEvent(event, tag)
  local property = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)

  return property == tag
end

return isSyntheticEvent