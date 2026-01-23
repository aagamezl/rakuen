local logger = require('utils/logger')

local SYNTHETIC_EVENT_TAG = 9999
local isEnabled = true
local nonStandardKeyCodes = {
  [160] = "f3",
  [129] = "f4",
  [176] = "f5",
  [161] = "f6"
}

--- Check if the given event flags match the given modifiers
--- @param eventFlags table The event flags to check
--- @param mods table The modifiers to check
--- @return boolean True if the event flags match the modifiers, false otherwise
local function modsMatch(eventFlags, mods)
  -- print("Event Flags: " .. hs.inspect(eventFlags))
  -- print("Mods: " .. hs.inspect(mods))
  -- print("eventFlags containing: " .. hs.inspect(eventFlags:contain(mods)))

  -- if not mods or empty return true (no modifiers, match only key)
  if not mods or #mods == 0 then
    print("No modifiers, matching only key")
    return true
  end

  if not eventFlags:contain(mods) then
    print("Event Flags do not match")
    return false
  end

  local allMods = { "cmd", "alt", "shift", "ctrl" --[[ , "fn" ]] }
  for _, m in ipairs(allMods) do
    local required = false

    for _, req in ipairs(mods) do
      if req == m then
        required = true

        -- print("Found required mod: " .. m)
        break
      end
    end

    if eventFlags[m] and not required then
      -- print("Event Flags do not match")
      return false
    end
  end

  -- print("Event Flags match")
  return true
end

--- Fire a synthetic key event with the given key, modifiers, and tag
--- @param key string The key to fire
--- @param mods table The modifiers to apply
--- @param tag number The tag to use for the event
local function fireSyntheticKey(key, mods, tag)
  -- logger.info("Firing synthetic key: " .. key .. " " .. hs.inspect(mods), "attachEvents")

  local evDown = hs.eventtap.event.newKeyEvent(mods, key, true)
  evDown:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, tag)
  evDown:post()

  local evUp = hs.eventtap.event.newKeyEvent(mods, key, false)
  evUp:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, tag)
  evUp:post()
end

--- Check if the given event is a synthetic event
--- @param event hs.eventtap.event The event to check
--- @param tag number The tag to use to define synthetic events
local function isSyntheticEvent(event, tag)
  local property = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat)

  return property == tag
end

--- Reset the synthetic event tag for the given event
--- @param event hs.eventtap.event The event to reset
local function resetSyntheticEvent(event)
  event:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, 0)
end

--- Checks if a keyboard shortcut matches
---
--- 1. The pressed key must match shortcut.from.key
--- 2. The modifier keys must match shortcut.from.mods (using modsMatch)
--- 3. If shortcut.only exists, the bundleId must be in that list
--- 4. If shortcut.except exists, the bundleId must not be in that list
--- @param key string The key to check
--- @param shortcut table The shortcut to check
--- @param eventFlags table The event flags to check
--- @param bundleId string The bundle ID of the application
--- @return boolean
local function isShortcutMatching(key, shortcut, eventFlags, bundleId)
  return key == shortcut.from.key
    and modsMatch(eventFlags, shortcut.from.mods)
    and (not shortcut.only or hs.fnutils.contains(shortcut.only, bundleId))
    and (not shortcut.except or not hs.fnutils.contains(shortcut.except, bundleId))
end

--- Attach the given keybindings to the event tap
--- @param keybindings table The keybindings to attach
--- @return hs.eventtap The event tap
local function keyEventListener(keybindings)
  _G.tap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged,
  }, function(event)
    -- logger.info("EVENT TRAPPED", "attachEvents")

    local key = hs.keycodes.map[event:getKeyCode()]
    local keyCode = event:getKeyCode()
    local eventFlags = event:getFlags()

    logger.log("key: " .. hs.inspect(key), "attachEvents")
    logger.log("keyCode: " .. keyCode, "attachEvents")
    logger.log("eventFlags: " .. hs.inspect(eventFlags), "attachEvents")

    if isSyntheticEvent(event, SYNTHETIC_EVENT_TAG) then
      -- logger.info("Event is synthetic, allowing original action", "attachEvents")

      resetSyntheticEvent(event)

      return false
    end

    for _, shortcut in ipairs(keybindings) do
      local bundleId = hs.application.frontmostApplication():bundleID() or ""

      if not isShortcutMatching(key, shortcut, eventFlags, bundleId) then
        goto continue
      end

      if shortcut.condition then
        local metCondition = shortcut.condition()

        if not metCondition then
          return false
        end
      end

      if shortcut.to.handler then
        shortcut.to.handler()

        return true
      end

      -- Block original
      event:setFlags({})

      if shortcut.to.app then
        hs.application.launchOrFocus(shortcut.to.app)
      else
        if not shortcut.to.key then
          return false
        end

        logger.info(
          string.format(
            "Remap key: %s => [%s + %s] to [%s + %s]",
            shortcut.action,
            table.concat(shortcut.from.mods, ", "), shortcut.from.key,
            table.concat(shortcut.to.mods, ", "), shortcut.to.key
          ), "attachEvents"
        )

        fireSyntheticKey(shortcut.to.key, shortcut.to.mods, SYNTHETIC_EVENT_TAG)

        return true
      end

      ::continue::
    end
  end)

  _G.tap:start()

  return _G.tap
end

-- local function keyEventListener(keybindings)
--   -- local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
--   _G.tap = hs.eventtap.new({
--     hs.eventtap.event.types.keyDown,
--     hs.eventtap.event.types.flagsChanged,
--   }, function(event)
--     -- print("event: " .. hs.inspect(hs.eventtap.event.types))
--     -- print("event type: " .. event:getType())

--     local key = ""
--     local keyCode = event:getKeyCode()

--     if nonStandardKeyCodes[keyCode] then
--       print("Found non-standard key code: " .. keyCode)
--       key = nonStandardKeyCodes[keyCode]
--     else
--       key = hs.keycodes.map[event:getKeyCode()]
--     end

--     local eventFlags = event:getFlags()

--     for _, map in ipairs(keybindings) do
--       if key == map.from.key and modsMatch(eventFlags, map.from.mods) then
--         -- If a condition function is provided, check it, if condition function
--         -- returns false, do not remap
--         if map.condition then
--           local metCondition, result = pcall(map.condition)

--           logger.info("Condition met: " .. hs.inspect(result), "attachEvents")

--           if not metCondition or not result then
--             return false
--           end
--         end

--         if map.to.handler then
--           -- print("Handler: " .. map.action)
--           map.to.handler()

--           return true
--         end

--         -- If an except list is provided, check if the current app is in the list
--         if map.except then
--           local app = hs.application.frontmostApplication()
--           local bundleId = app and app:bundleID() or ""

--           -- print("Current app bundle ID: " .. bundleId)

--           for _, exceptApp in ipairs(map.except) do
--             if bundleId == exceptApp then
--               print("App in except list, skipping remap")
--               return false
--             end
--           end
--         end

--         -- If an only list is provided, check if the current app is in the list
--         if map.only then
--           local app = hs.application.frontmostApplication()
--           local bundleId = app and app:bundleID() or ""

--           print("Current app bundle ID: " .. bundleId)

--           local allowed = false
--           for _, allowedApp in ipairs(map.only) do
--             if bundleId == allowedApp then
--               allowed = true
--               break
--             end
--           end

--           if not allowed then
--             print("App not in allowed list, skipping remap")
--             return false
--           end
--         end

--         event:setFlags({})

--         if map.to.app then
--           print(
--             string.format(
--               "Remap app: %s + %s to open app '%s'",
--               table.concat(map.from.mods, ", "),
--               map.from.key, map.to.app
--             )
--           )

--           hs.application.launchOrFocus(map.to.app)
--         else
--           if not map.to.key then
--             return false
--           end

--           print(
--             string.format(
--               "Remap key: %s => [%s + %s] to [%s + %s]",
--               map.action,
--               table.concat(map.from.mods, ", "), map.from.key,
--               table.concat(map.to.mods, ", "), map.to.key
--             )
--           )

--           hs.eventtap.keyStroke(map.to.mods, map.to.key, 0)
--         end

--         -- -- Block original
--         -- event:setFlags({})

--         return true
--       end
--     end

--     return false
--   end)

--   _G.tap:start()

--   return _G.tap
-- end

-- local function keyEventListener(keybindings)
--   -- local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
--   _G.tap = hs.eventtap.new({
--     hs.eventtap.event.types.keyDown,
--     hs.eventtap.event.types.flagsChanged,
--   }, function(event)
--     -- print("event: " .. hs.inspect(hs.eventtap.event.types))
--     -- print("event type: " .. event:getType())

--     local key = ""
--     local keyCode = event:getKeyCode()

--     if nonStandardKeyCodes[keyCode] then
--       print("Found non-standard key code: " .. keyCode)
--       key = nonStandardKeyCodes[keyCode]
--     else
--       key = hs.keycodes.map[event:getKeyCode()]
--     end

--     local flags = event:getFlags()

--     print("key: " .. key)
--     print("keyCode: " .. keyCode)
--     print("flags: " .. hs.inspect(flags))

--     -- logger.info("event: " .. hs.inspect(flags))

--     -- if not key then
--     --   return false
--     -- end

--     -- print("key: " .. key)

--     for _, map in ipairs(keybindings) do
--       -- print("key: " .. key)
--       -- print("keyCode: " .. keyCode)
--       -- if key == "cmd" then
--       --   print("key, map.from.key: " .. hs.inspect(key) .. ", " .. hs.inspect(map.from.key))
--       -- end

--       if key == map.from.key and modsMatch(event:getFlags(), map.from.mods) then
--         -- If a condition function is provided, check it, if condition function
--         -- returns false, do not remap
--         if map.condition then
--           local metCondition, result = pcall(map.condition)

--           logger.info("Condition met: " .. hs.inspect(result), "attachEvents")

--           if not metCondition or not result then
--             return false
--           end
--         end

--         if map.to.handler then
--           -- print("Handler: " .. map.action)
--           map.to.handler()

--           return true
--         end

--         -- If an except list is provided, check if the current app is in the list
--         if map.except then
--           local app = hs.application.frontmostApplication()
--           local bundleId = app and app:bundleID() or ""

--           -- print("Current app bundle ID: " .. bundleId)

--           for _, exceptApp in ipairs(map.except) do
--             if bundleId == exceptApp then
--               print("App in except list, skipping remap")
--               return false
--             end
--           end
--         end

--         -- If an only list is provided, check if the current app is in the list
--         if map.only then
--           local app = hs.application.frontmostApplication()
--           local bundleId = app and app:bundleID() or ""

--           print("Current app bundle ID: " .. bundleId)

--           local allowed = false
--           for _, allowedApp in ipairs(map.only) do
--             if bundleId == allowedApp then
--               allowed = true
--               break
--             end
--           end

--           if not allowed then
--             print("App not in allowed list, skipping remap")
--             return false
--           end
--         end

--         event:setFlags({})

--         if map.to.app then
--           print(
--             string.format(
--               "Remap app: %s + %s to open app '%s'",
--               table.concat(map.from.mods, ", "),
--               map.from.key, map.to.app
--             )
--           )

--           hs.application.launchOrFocus(map.to.app)
--         else
--           if not map.to.key then
--             return false
--           end

--           print(
--             string.format(
--               "Remap key: %s => [%s + %s] to [%s + %s]",
--               map.action,
--               table.concat(map.from.mods, ", "), map.from.key,
--               table.concat(map.to.mods, ", "), map.to.key
--             )
--           )

--           hs.eventtap.keyStroke(map.to.mods, map.to.key, 0)
--         end

--         -- -- Block original
--         -- event:setFlags({})

--         return true
--       end
--     end

--     return false
--   end)

--   _G.tap:start()

--   return _G.tap
-- end

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
  -- enable = function() _G.tap:start() end,
  -- disable = function() _G.tap:stop() end
}



