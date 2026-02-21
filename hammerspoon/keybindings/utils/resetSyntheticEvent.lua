--- Reset the synthetic event tag for the given event
--- @param event hs.eventtap.event The event to reset
local function resetSyntheticEvent(event)
  event:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, 0)
end

return resetSyntheticEvent