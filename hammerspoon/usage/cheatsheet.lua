-- =============================================
-- SYSTEM SHORTCUTS CHEATSHEET for Hammerspoon
-- =============================================
local logger = require("utils/logger")

local cheatsheetCanvas = nil

-- Build the cheatsheet text
local function formatModifiers(mods)
  if not mods or #mods == 0 then return "" end

  local modSymbols = {
    -- cmd = "⌘",
    -- ctrl = "⌃",
    -- alt = "⌥",
    -- shift = "⇧",
    cmd = "CMD",
    ctrl = "CTRL",
    alt = "OPT/ALT",
    shift = "SHIFT",
    fn = "FN"
  }

  local result = {}
  for _, mod in ipairs(mods) do
    table.insert(result, modSymbols[mod] or mod)
  end

  return table.concat(result, " + ")
end

local function formatKey(key)
  -- Convert special keys to symbols
  local keySymbols = {
    escape = "⎋",
    ["return"] = "⏎",
    space = "␣",
    tab = "⇥",
    delete = "⌫",
    forwarddelete = "⌦",
    up = "↑",
    down = "↓",
    left = "←",
    right = "→",
    pageup = "⇞",
    pagedown = "⇟",
    home = "↖",
    ["end"] = "↘",
    ["["] = "[",
    ["]"] = "]",
    ["-"] = "-",
    ["="] = "=",
    ["'"] = "'",
    ["\\"] = "\\",
    [";"] = ";",
    ["`"] = "`",
    [","] = ",",
    ["."] = ".",
    ["/"] = "/"
  }

  -- If it's a single character, return it as is
  if #key == 1 then
    return key:upper()
  end

  -- Check if it's a function key (f1-f19)
  local fkey = key:match("^f(%d+)$")
  if fkey then
    return "F" .. fkey
  end

  -- Return the symbol if found, otherwise capitalize the key
  return keySymbols[key:lower()] or key:gsub("^%l", string.upper)
end

local function formatKeybinding(binding)
  local parts = {}

  if binding.mods and #binding.mods > 0 then
    table.insert(parts, formatModifiers(binding.mods))
  end

  if binding.key then
    table.insert(parts, formatKey(binding.key))
  end

  return table.concat(parts, " + ")
end

local function buildText(shortcuts)
  local text = ""
  local table = require("table")

  -- Group shortcuts by their section (name)
  local sections = {}
  for _, shortcut in ipairs(shortcuts) do
    local sectionName = shortcut.name

    if not sections[sectionName] then
      sections[sectionName] = {}
    end

    for _, rules in ipairs(shortcut.rules) do
      table.insert(sections[sectionName], rules)
    end
  end

  -- Sort sections alphabetically
  local sortedSections = {}

  for name, _ in pairs(sections) do
    table.insert(sortedSections, name)
  end

  table.sort(sortedSections)

  -- Generate the text for each section
  for _, sectionName in ipairs(sortedSections) do
    text = text .. "## " .. sectionName .. "\n\n"

    local sectionBindings = sections[sectionName]

    -- Sort bindings by action name
    table.sort(sectionBindings, function(a, b)
      return (a.action or "") < (b.action or "")
    end)

    -- Add each binding to the section
    for _, binding in ipairs(sectionBindings) do
      local from = formatKeybinding(binding.from or {})
      local to = ""

      if binding.to then
        if binding.to.app then
          to = "→ Launch " .. binding.to.app
        else
          to = "→ " .. formatKeybinding(binding.to)
        end
      end

      text = text .. "**" .. from .. "**  "
      if to ~= "" then
        text = text .. to .. "\n"
      end

      text = text .. "\n" .. (binding.action or "") .. "\n\n"
    end
  end

  return text
end

-- Create and show the cheatsheet window
local function show(shortcuts)
  if cheatsheetCanvas then
    cheatsheetCanvas:show()
    return
  end

  local screenFrame = hs.screen.primaryScreen():frame()
  local width, height = 1200, 600
  local x = (screenFrame.w - width) / 2
  local y = (screenFrame.h - height) / 2

  cheatsheetCanvas = hs.canvas.new { x = x, y = y, w = width, h = height }

  -- Styling
  cheatsheetCanvas[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = { white = 0.95, alpha = 0.98 },
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    strokeColor = { white = 0.7 },
    strokeWidth = 1,
  }

  cheatsheetCanvas[2] = {
    type = "text",
    text = buildText(shortcuts),
    textColor = { white = 0.2 },
    textFont = "Menlo",
    textSize = 14,
    frame = { x = 30, y = 30, w = width - 20, h = height - 20 },
    textAlignment = "left",
    textLineBreak = "wordWrap",
  }

  cheatsheetCanvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  cheatsheetCanvas:level(hs.canvas.windowLevels.floating)
  cheatsheetCanvas:show()
end

-- Hide the cheatsheet
local function hide()
  if cheatsheetCanvas then
    cheatsheetCanvas:hide()
  end
end

-- Toggle visibility
local function toggle(shortcuts)
  if cheatsheetCanvas and cheatsheetCanvas:isShowing() then
    hide()
  else
    show(shortcuts)
  end
end

-- Optional: Auto-hide on click outside
if cheatsheetCanvas then
  cheatsheetCanvas:mouseCallback(function(_, msg)
    if msg == "mouseDown" then
      local frame = cheatsheetCanvas:frame()
      local mousePos = hs.mouse.getAbsolutePosition()

      if mousePos.x < frame.x or mousePos.x > frame.x + frame.w or
          mousePos.y < frame.y or mousePos.y > frame.y + frame.h then
        hide()
      end
    end
  end)
end

-- return cheatsheet
return {
  name = "usage-cheatsheet",
  show = show,
  hide = hide,
  toggle = toggle
}