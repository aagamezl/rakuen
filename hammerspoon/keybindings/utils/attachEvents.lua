local nonStandardKeyCodes = {
  [160] = "f3",
  [129] = "f4",
  [176] = "f5",
  [161] = "f6"
}

local function modsMatch(eventFlags, mods)
  -- if not mods or empty return true (no modifiers, match only key)
  if not mods or #mods == 0 then
    return true
  end

  -- print("Event Flags: " .. hs.inspect(eventFlags))
  -- print("Mods: " .. hs.inspect(mods))
  -- print("eventFlags containing: " .. hs.inspect(eventFlags:contain(mods)))

  if not eventFlags:contain(mods) then
    -- print("Event Flags do not match")
    return false
  end

  local allMods = { "cmd", "alt", "shift", "ctrl" }
  for _, m in ipairs(allMods) do
    local required = false

    for _, req in ipairs(mods) do
      if req == m then
        required = true
        break
      end
    end

    if eventFlags[m] and not required then
      print("Event Flags do not match")
      return false
    end
  end

  print("Event Flags match")
  return true
end

local function attachEvents(keybindings)
  -- local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  _G.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    -- print("event: " .. hs.inspect(hs.eventtap.event.types))
    -- print("event type: " .. event:getType())

    local key = ""
    local keyCode = event:getKeyCode()
    if nonStandardKeyCodes[keyCode] then
      print("Found non-standard key code: " .. keyCode)
      key = nonStandardKeyCodes[keyCode]
    else
      key = hs.keycodes.map[event:getKeyCode()]
    end

    -- local flags = event:getFlags()
    -- print("flags: " .. hs.inspect(flags))
    -- print("keyCode: " .. keyCode)
    -- print("key: " .. key)

    if not key then
      return false
    end

    -- print("key: " .. key)

    for _, map in ipairs(keybindings) do
      -- print("map.from.key: " .. map.from.key)
      if key == map.from.key and modsMatch(event:getFlags(), map.from.mods) then
        -- If a condition function is provided, check it, if condition function
        -- returns false, do not remap
        if map.condition then
          local metCondition, result = pcall(map.condition)

          if not metCondition or not result then
            return false
          end
        end

        if map.to.handler then
          print("Handler: " .. map.action)
          map.to.handler()

          return true
        end

        if map.excepkt then
          local app = hs.application.frontmostApplication()
          local bundleId = app and app:bundleID() or ""

          -- print("Current app bundle ID: " .. bundleId)

          for _, exceptApp in ipairs(map.except) do
            if bundleId == exceptApp then
              print("App in except list, skipping remap")
              return false
            end
          end
        end

        if map.only then
          local app = hs.application.frontmostApplication()
          local bundleId = app and app:bundleID() or ""

          print("Current app bundle ID: " .. bundleId)

          local allowed = false
          for _, allowedApp in ipairs(map.only) do
            if bundleId == allowedApp then
              allowed = true
              break
            end
          end

          if not allowed then
            print("App not in allowed list, skipping remap")
            return false
          end
        end

        event:setFlags({})

        if map.to.app then
          print(
            string.format(
              "Remap: %s + %s to open app '%s'",
              table.concat(map.from.mods, ", "),
              map.from.key, map.to.appk
            )
          )

          hs.application.launchOrFocus(map.to.app)
        else
          if not map.to.key then
            return false
          end

          print(
            string.format(
              "Remap: %s => [%s + %s] to [%s + %s]",
              map.action,
              table.concat(map.from.mods, ", "), map.from.key,
              table.concat(map.to.mods, ", "), map.to.key
            )
          )

          hs.eventtap.keyStroke(map.to.mods, map.to.key, 0)
        end

        -- -- Block original
        -- event:setFlags({})

        return true
      end
    end

    return false
  end)

  _G.tap:start()

  return _G.tap
end

return attachEvents

-- local module = {
--   name = 'attach-events',
--   attachEvents = attachEvents,
-- }

-- return module
