-- Modules switched on or off from the menu bar (task 16.2).
--
-- The choice is kept in ~/.config/rakuen/modules.json as { "editing": false, ... },
-- apart from config.lua so Rakuen never rewrites a file the user edits by hand.
-- A module named here overrides the `enabled` flag of config.lua.

local config = require("rakuen.core.config")

local module_state = {}

--- Apply `overrides` ({ name = boolean }) to merged `settings`. Unknown names and
--- non-boolean values are ignored, so a stale file cannot break loading.
function module_state.apply(settings, overrides)
  for name, enabled in pairs(overrides or {}) do
    local module_config = settings.modules[name]
    if module_config ~= nil and type(enabled) == "boolean" then
      module_config.enabled = enabled
    end
  end
  return settings
end

--- Return a copy of `overrides` with `name` set to `enabled`.
function module_state.with(overrides, name, enabled)
  local updated = {}
  for key, value in pairs(overrides or {}) do
    updated[key] = value
  end
  updated[name] = enabled
  return updated
end

--- Names of the modules the menu offers, in load order.
function module_state.names()
  return config.MODULE_NAMES
end

--- Read the overrides file. A missing or broken file gives an empty table.
function module_state.load(path)
  local file = io.open(path, "r")
  if file == nil then
    return {}
  end

  local text = file:read("*a")
  file:close()

  local decoded_ok, decoded = pcall(hs.json.decode, text)
  if not decoded_ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

--- Write the overrides file. Returns true, or false and a message.
function module_state.save(path, overrides)
  local file, open_error = io.open(path, "w")
  if file == nil then
    return false, open_error
  end

  file:write(hs.json.encode(overrides, true))
  file:close()
  return true
end

return module_state
