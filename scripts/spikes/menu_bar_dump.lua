-- Diagnostic: dump the accessibility tree of the apps that own the menu bar
-- extras (clock, battery, ...), with identifiers, to find the item that opens Notification Center.
--
-- Run from the Hammerspoon console:
--   local dir = "/workspace/personal/git-repos/rakuen/scripts/spikes/"
--   dofile(os.getenv("HOME") .. dir .. "menu_bar_dump.lua")
--
-- Output: ~/rakuen-menu-bar.txt

local OUTPUT_PATH = os.getenv("HOME") .. "/rakuen-menu-bar.txt"
local BUNDLE_IDS = { "com.apple.controlcenter", "com.apple.systemuiserver" }
local MAX_DEPTH = 6
-- Attributes of the app that may hold the menu bar items, besides AXChildren.
local APP_ATTRIBUTES = { "AXExtrasMenuBar", "AXMenuBar", "AXWindows" }
local ATTRIBUTES = { "AXRole", "AXSubrole", "AXTitle", "AXDescription", "AXIdentifier" }

local function describe(element)
  local fields = {}
  for _, name in ipairs(ATTRIBUTES) do
    local ok, value = pcall(function()
      return element:attributeValue(name)
    end)
    if ok and value ~= nil and value ~= "" then
      table.insert(fields, name:gsub("^AX", "") .. "=" .. tostring(value))
    end
  end
  return table.concat(fields, " ")
end

local function dump(element, depth, lines)
  table.insert(lines, string.rep("  ", depth) .. describe(element))
  local ok, children = pcall(function()
    return element:attributeValue("AXChildren")
  end)
  if ok and children ~= nil and depth < MAX_DEPTH then
    for _, child in ipairs(children) do
      dump(child, depth + 1, lines)
    end
  end
end

local lines = { "macOS " .. hs.host.operatingSystemVersionString() }
for _, bundle_id in ipairs(BUNDLE_IDS) do
  table.insert(lines, "=== " .. bundle_id)
  local app = hs.application.get(bundle_id)
  if app == nil then
    table.insert(lines, "not running")
  else
    local root = hs.axuielement.applicationElement(app)
    dump(root, 0, lines)
    for _, name in ipairs(APP_ATTRIBUTES) do
      local ok, value = pcall(function()
        return root:attributeValue(name)
      end)
      table.insert(lines, "--- attribute " .. name .. ": " .. tostring(ok and value ~= nil))
      if ok and value ~= nil then
        if value.attributeValue ~= nil then
          dump(value, 1, lines)
        else
          for _, item in ipairs(value) do
            dump(item, 1, lines)
          end
        end
      end
    end
  end
end

-- Any other process may own the menu bar extras on this macOS version.
table.insert(lines, "=== every running app that has an AXExtrasMenuBar")
for _, app in ipairs(hs.application.runningApplications()) do
  local ok, extras = pcall(function()
    return hs.axuielement.applicationElement(app):attributeValue("AXExtrasMenuBar")
  end)
  if ok and extras ~= nil then
    table.insert(lines, "# " .. tostring(app:bundleID()) .. " (" .. tostring(app:name()) .. ")")
    dump(extras, 1, lines)
  end
end

local file = assert(io.open(OUTPUT_PATH, "w"))
file:write(table.concat(lines, "\n"), "\n")
file:close()
print("[menu-bar] wrote " .. #lines .. " lines to " .. OUTPUT_PATH)
