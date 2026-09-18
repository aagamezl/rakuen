local logger = require('utils/logger')

local SYNTHETIC_EVENT_PROPERTY = hs.eventtap.event.properties.keyboardEventAutorepeat
--- @type number
local SYNTHETIC_EVENT_TAG = 9999

local MODIFIER_KEYS = { cmd = true, alt = true, shift = true, ctrl = true, fn = true }
local ALL_MODS = { "cmd", "alt", "shift", "ctrl" --[[ , "fn" ]] }

--- Checks if the given modifiers match the event flags
--- @param mods table The modifiers to check
--- @param eventFlags table The event flags to check
--- @param key string The key being pressed
--- @return boolean
local function isShortcutModsMatching(mods, eventFlags, key)
  -- Rules keyed on a modifier itself (e.g. tapping `ctrl`) cannot require an
  -- empty flag set, since pressing the key inherently sets that flag. For
  -- those we match on the key alone.
  if MODIFIER_KEYS[key] then
    return true
  end

  -- No modifiers required: match only when no modifier is currently held, so a
  -- plain `f3` rule does not swallow `shift+f3`.
  if not mods or #mods == 0 then
    for _, m in ipairs(ALL_MODS) do
      if eventFlags[m] then
        return false
      end
    end

    return true
  end

  if not eventFlags:contain(mods) then
    return false
  end

  for _, m in ipairs(ALL_MODS) do
    local required = false

    for _, req in ipairs(mods) do
      if req == m then
        required = true
        break
      end
    end

    if eventFlags[m] and not required then
      return false
    end
  end

  return true
end

--- Checks if a keyboard shortcut matches
---
--- 1. The pressed key must match shortcut.from.key
--- 2. The modifier keys must match shortcut.from.mods (using modsMatch)
--- 3. If shortcut.only exists, the bundleId must be in that list
--- 4. If shortcut.except exists, the bundleId must not be in that list
--- @param shortcut table The shortcut to check
--- @param key string The key to check
--- @param eventFlags table The event flags to check
--- @param bundleId string The bundle ID of the application
--- @return boolean
local function isShortcutMatching(shortcut, key, eventFlags, bundleId)
  return key == shortcut.from.key
      and isShortcutModsMatching(shortcut.from.mods, eventFlags, key)
      and (not shortcut.only or hs.fnutils.contains(shortcut.only, bundleId))
      and (not shortcut.except or not hs.fnutils.contains(shortcut.except, bundleId))
end

--- Fire a synthetic key event with the given key, modifiers, and tag
--- @param key string The key to fire
--- @param mods table The modifiers to apply
--- @param tag number The tag to use for the event
local function fireSyntheticKey(key, mods, tag)
  local evDown = hs.eventtap.event.newKeyEvent(mods, key, true)
  evDown:setProperty(SYNTHETIC_EVENT_PROPERTY, tag)
  evDown:post()

  local evUp = hs.eventtap.event.newKeyEvent(mods, key, false)
  evUp:setProperty(SYNTHETIC_EVENT_PROPERTY, tag)
  evUp:post()
end

--- Check if the given event is a synthetic event
--- @param event hs.eventtap.event The event to check
--- @param tag number The tag to use to define synthetic events
local function isSyntheticEvent(event, tag)
  local property = event:getProperty(SYNTHETIC_EVENT_PROPERTY)

  return property == tag
end

--- Reset the synthetic event tag for the given event
--- @param event hs.eventtap.event The event to reset
local function resetSyntheticEvent(event)
  event:setProperty(SYNTHETIC_EVENT_PROPERTY, 0)
end

local function getBundleId()
  local app = hs.application.frontmostApplication()

  return app and app:bundleID() or ""
end

--- Attach the given keybindings to the event tap
--- @param shortcuts table The shortcuts to attach
--- @return hs.eventtap The event tap
local function keyEventListener(shortcuts)
  _G.tap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged,
  }, function(event)
    local key = hs.keycodes.map[event:getKeyCode()]
    local eventFlags = event:getFlags()

    if isSyntheticEvent(event, SYNTHETIC_EVENT_TAG) then
      logger.info("Event is synthetic, allowing original action", "keyEventListener")

      resetSyntheticEvent(event)

      return false
    end

    local bundleId = getBundleId()

    for _, shortcut in ipairs(shortcuts) do
      if not isShortcutMatching(shortcut, key, eventFlags, bundleId) then
        goto continue
      end

      if shortcut.condition then
        local ok, metCondition = pcall(shortcut.condition)

        if not ok then
          logger.error("Condition errored: " .. tostring(metCondition), "keyEventListener")

          return false
        end

        if not metCondition then
          return false
        end
      end

      if shortcut.to.handler then
        local ok, err = pcall(shortcut.to.handler)

        if not ok then
          logger.error("Handler errored: " .. tostring(err), "keyEventListener")
        end

        return true
      end

      if shortcut.to.app then
        hs.application.launchOrFocus(shortcut.to.app)

        return true
      else
        fireSyntheticKey(shortcut.to.key, shortcut.to.mods, SYNTHETIC_EVENT_TAG)

        return true
      end

      ::continue::
    end

    return false
  end)

  _G.tap:start()

  return _G.tap
end

return {
  version = "1.0.0",
  name = "key-event-listener",
  description = "A module for handling key events",
  author = {
    name = "Álvaro José Agámez Licha",
    email = "alvaroagamez@outlook.com"
  },
  keyEventListener = keyEventListener,
  isEnabled = function() return _G.tap:isEnabled() end,
}
