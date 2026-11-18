-- Diagnostic: while you press keys, log the focused accessibility element and its
-- ancestors, to learn what an app exposes (for example the VS Code file explorer).
--
-- Easiest way, from a terminal in the repo:   bin/ax-watch            (toggle)
--                                              bin/ax-watch 300 f2,return
-- Or from the Hammerspoon console:
--   dofile(os.getenv("HOME") .. "/workspace/personal/git-repos/rakuen/scripts/spikes/ax_watch.lua")
--
-- Run it again to stop. Options, set as globals before running:
--   RAKUEN_AX_SECONDS  stop by itself after this many seconds (default 120)
--   RAKUEN_AX_KEYS     comma list of key names to log, e.g. "f2,return" (default: every key)
--
-- Output: /tmp/rakuen_ax_watch.log. Each line: the chord, the app, then the focused
-- element and up to ANCESTORS parents, each with role, description, title,
-- identifier and DOM classes. It never swallows or changes a key press.

local vscode_focus = require("rakuen.core.vscode_focus")

local OUTPUT_PATH = "/tmp/rakuen_ax_watch.log"
local DEFAULT_SECONDS = 120
local ANCESTORS = 6
local ATTRIBUTES = {
  "AXRole",
  "AXSubrole",
  "AXDescription",
  "AXTitle",
  "AXIdentifier",
  "AXDOMIdentifier",
  "AXDOMClassList",
}

-- A second run stops the first one.
if RAKUEN_AX_WATCH ~= nil then
  RAKUEN_AX_WATCH.stop()
  RAKUEN_AX_WATCH = nil
  hs.alert.show("ax-watch stopped")
  return "stopped"
end

local function read(element, name)
  local ok, value = pcall(function()
    return element:attributeValue(name)
  end)
  if ok then
    return value
  end
  return nil
end

local function format_value(value)
  if type(value) == "table" then
    return "{" .. table.concat(value, " ") .. "}"
  end
  return tostring(value)
end

local function describe(element)
  local fields = {}
  for _, name in ipairs(ATTRIBUTES) do
    local value = read(element, name)
    if value ~= nil and value ~= "" then
      table.insert(fields, name:gsub("^AX", "") .. "=" .. format_value(value))
    end
  end
  return table.concat(fields, " | ")
end

local function wanted_keys()
  local keys = {}
  local list = RAKUEN_AX_KEYS
  if list == nil or list == "" then
    return nil
  end

  for key in tostring(list):gmatch("[^,%s]+") do
    keys[key:lower()] = true
  end
  return keys
end

local only_keys = wanted_keys()
local log_file = assert(io.open(OUTPUT_PATH, "w"))

local function write(line)
  log_file:write(line .. "\n")
  log_file:flush()
end

local function log_key(event)
  local key = hs.keycodes.map[event:getKeyCode()] or ("keycode_" .. event:getKeyCode())
  if only_keys ~= nil and not only_keys[tostring(key):lower()] then
    return
  end

  local modifiers = {}
  for name, pressed in pairs(event:getFlags()) do
    if pressed then
      table.insert(modifiers, name)
    end
  end
  table.sort(modifiers)
  table.insert(modifiers, tostring(key))

  local app = hs.application.frontmostApplication()
  write(string.format("== %s  app=%s", table.concat(modifiers, "+"), tostring(app:bundleID())))

  local ok, element = pcall(vscode_focus.element)
  if not ok or element == nil then
    write("   no focused element")
    return
  end

  local depth = 0
  while element ~= nil and depth <= ANCESTORS do
    write(string.format("   %s%s", string.rep("^", depth), describe(element)))
    element = read(element, "AXParent")
    depth = depth + 1
  end
end

local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local ok, log_error = pcall(log_key, event)
  if not ok then
    write("   error: " .. tostring(log_error))
  end
  return false
end)
tap:start()

local seconds = tonumber(RAKUEN_AX_SECONDS) or DEFAULT_SECONDS
local timer

local function stop()
  tap:stop()
  if timer ~= nil then
    timer:stop()
  end
  log_file:close()
  RAKUEN_AX_WATCH = nil
end

timer = hs.timer.doAfter(seconds, function()
  stop()
  hs.alert.show("ax-watch finished")
end)

RAKUEN_AX_WATCH = { stop = stop }
write(string.format("ax-watch started, %d seconds, keys=%s", seconds, tostring(RAKUEN_AX_KEYS)))
hs.alert.show("ax-watch started")
return "started, log: " .. OUTPUT_PATH
