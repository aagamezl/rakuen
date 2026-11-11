-- Startup check: are the macOS Spaces shortcuts where Rakuen expects them?
--
-- bin/install.sh moves Move left/right a space, Mission Control and
-- Application windows to Ctrl+Cmd+Arrow (design decision D7). When they are
-- still on Ctrl+Arrow, Ctrl+Arrow would switch Spaces and clash with text
-- navigation. `problems` is pure; `read` and `check` talk to macOS.

local shortcut_check = {}

local MODIFIERS_TARGET = 9699328 -- Ctrl+Cmd, including the arrow-key flag

-- Hotkey id, label and arrow key code. Same ids as bin/install.sh.
shortcut_check.EXPECTED = {
  { id = "79", label = "Move left a space", keycode = 123 },
  { id = "81", label = "Move right a space", keycode = 124 },
  { id = "32", label = "Mission Control", keycode = 126 },
  { id = "33", label = "Application windows", keycode = 125 },
}

local READ_COMMAND = "/usr/bin/defaults export com.apple.symbolichotkeys - "
  .. "| /usr/bin/plutil -convert json -o - -"

local function is_enabled(hotkey)
  return hotkey ~= nil and hotkey.enabled == true
end

local function has_parameters(hotkey)
  if not is_enabled(hotkey) or type(hotkey.value) ~= "table" then
    return false
  end
  return type(hotkey.value.parameters) == "table"
end

--- `hotkeys` is the decoded AppleSymbolicHotKeys table (string ids).
--- Returns the labels of the shortcuts that are not on Ctrl+Cmd+Arrow.
function shortcut_check.problems(hotkeys)
  assert(type(hotkeys) == "table", "hotkeys must be a table")

  local found = {}
  for _, expected in ipairs(shortcut_check.EXPECTED) do
    local hotkey = hotkeys[expected.id]
    local parameters = nil
    if has_parameters(hotkey) then
      parameters = hotkey.value.parameters
    end

    local on_target = parameters ~= nil
      and parameters[2] == expected.keycode
      and parameters[3] == MODIFIERS_TARGET
    if not on_target then
      table.insert(found, expected.label)
    end
  end
  return found
end

--- Read the hotkeys from macOS. Returns the table, or nil and a message.
function shortcut_check.read()
  local succeeded, output = pcall(hs.execute, READ_COMMAND)
  if not succeeded or type(output) ~= "string" or output == "" then
    return nil, "could not read com.apple.symbolichotkeys"
  end

  local decoded_ok, decoded = pcall(hs.json.decode, output)
  if not decoded_ok or type(decoded) ~= "table" then
    return nil, "could not decode com.apple.symbolichotkeys"
  end
  return decoded.AppleSymbolicHotKeys or {}
end

--- Check the shortcuts and alert when some are not moved. Never raises.
function shortcut_check.check(logger)
  local hotkeys, read_error = shortcut_check.read()
  if hotkeys == nil then
    logger:warn("workspaces: " .. read_error)
    return
  end

  local found = shortcut_check.problems(hotkeys)
  if #found == 0 then
    return
  end

  local message = "Rakuen: macOS shortcuts are not on Ctrl+Cmd+Arrow ("
    .. table.concat(found, ", ")
    .. "). Run bin/install.sh"
  logger:warn(message)
  hs.alert.show(message, 6)
end

return shortcut_check
