-- Diagnostic: dump the WindowManager's Mission Control accessibility tree
-- (on macOS 27 Mission Control lives there, not in the Dock).
-- Hover a desktop thumbnail with the mouse before the dump to expose its close button.
--
-- hs.spaces.addSpaceToScreen and removeSpace fail with "Unable to get mission
-- control data from the dock" on recent macOS. This script opens Mission
-- Control, writes the Dock's accessibility tree to a file, and closes Mission
-- Control, so the buttons Rakuen must press can be found.
--
-- Run from the Hammerspoon console:
--   local dir = "/workspace/personal/git-repos/rakuen/scripts/spikes/"
--   dofile(os.getenv("HOME") .. dir .. "mission_control_dump.lua")
--
-- Output: ~/rakuen-mission-control.txt

local OUTPUT_PATH = os.getenv("HOME") .. "/rakuen-mission-control.txt"
local OPEN_WAIT_SECONDS = 3
local MAX_DEPTH = 8

local function describe(element)
  local fields = {}
  for _, name in ipairs({ "AXRole", "AXSubrole", "AXTitle", "AXDescription", "AXIdentifier" }) do
    local ok, value = pcall(function()
      return element:attributeValue(name)
    end)
    if ok and value ~= nil and value ~= "" then
      table.insert(fields, name:gsub("^AX", "") .. "=" .. tostring(value))
    end
  end

  local ok, actions = pcall(function()
    return element:actionNames()
  end)
  if ok and actions ~= nil and #actions > 0 then
    table.insert(fields, "actions=" .. table.concat(actions, ","))
  end
  return table.concat(fields, " ")
end

local function dump(element, depth, lines)
  table.insert(lines, string.rep("  ", depth) .. describe(element))
  if depth >= MAX_DEPTH then
    return
  end

  local ok, children = pcall(function()
    return element:attributeValue("AXChildren")
  end)
  if not ok or children == nil then
    return
  end
  for _, child in ipairs(children) do
    dump(child, depth + 1, lines)
  end
end

--- Mission Control may be hosted outside the Dock's own tree, so also list
--- processes that look related and what the system says has focus.
local function dump_other_clues(dock, lines)
  table.insert(lines, "--- running apps with dock, mission or control in the name")
  for _, app in ipairs(hs.application.runningApplications()) do
    local name = (app:name() or "") .. " " .. (app:bundleID() or "")
    local lowered = name:lower()
    if lowered:find("dock") or lowered:find("mission") or lowered:find("control") then
      table.insert(lines, name .. " pid=" .. tostring(app:pid()))
    end
  end

  table.insert(lines, "--- WindowManager windows")
  local dock_element = hs.axuielement.applicationElement(dock)
  local windows = dock_element:attributeValue("AXWindows") or {}
  table.insert(lines, "count=" .. #windows)
  for _, window in ipairs(windows) do
    dump(window, 1, lines)
  end

  table.insert(lines, "--- system-wide focused element")
  local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  if focused ~= nil then
    table.insert(lines, describe(focused))
  end
end

local function write_lines(lines)
  local file = assert(io.open(OUTPUT_PATH, "w"))
  file:write(table.concat(lines, "\n"), "\n")
  file:close()
  print("[mission-control] wrote " .. #lines .. " lines to " .. OUTPUT_PATH)
end

local dock = hs.application.get("com.apple.WindowManager")
assert(dock ~= nil, "WindowManager is not running")

hs.spaces.toggleMissionControl()
hs.timer.doAfter(OPEN_WAIT_SECONDS, function()
  local lines = { "macOS " .. hs.host.operatingSystemVersionString() }
  local ok, dump_error = pcall(function()
    dump(hs.axuielement.applicationElement(dock), 0, lines)
    dump_other_clues(dock, lines)
  end)
  if not ok then
    table.insert(lines, "dump failed: " .. tostring(dump_error))
  end

  hs.spaces.closeMissionControl()
  write_lines(lines)
end)
