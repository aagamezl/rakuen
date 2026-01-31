--- Fire a synthetic key event with the given key, modifiers, and tag
--- @param key string The key to fire
--- @param mods table The modifiers to apply
--- @param tag number The tag to use for the event
local function fireSyntheticKey(key, mods, tag)
  local evDown = hs.eventtap.event.newKeyEvent(mods, key, true)
  evDown:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, tag)
  evDown:post()

  local evUp = hs.eventtap.event.newKeyEvent(mods, key, false)
  -- evUp:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, tag)
  evUp:post()
end

return fireSyntheticKey
