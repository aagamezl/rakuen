local logger = require('utils/logger')
local cheatsheet = require('usage.cheatsheet')

-- Declare hs as a global variable to avoid lint errors
local hs = _ENV.hs or {}

local function buildChoices(remaps)
  local choices = {}

  -- Now remaps is a flat table, so iterate directly
  for _, remap in ipairs(remaps) do
    if remap then
      if remap.type == "modal" then
        print("Modal: " .. remap.action)

        goto continue
      end

      local fromMods = remap.from and remap.from.mods or {}
      local fromKey = remap.from and remap.from.key or "?"
      local formatTemplate = "%s + %s"

      if fromKey == "?" then
        formatTemplate = "%s"
      end

      local fromStr
      if #fromMods > 0 then
        fromStr = string.format(formatTemplate, table.concat(fromMods, ", "), fromKey)
      else
        fromStr = fromKey
      end

      local toStr
      if remap.to and remap.to.app then
        toStr = string.format("Launch app '%s'", remap.to.app)
      elseif remap.to then
        local toMods = remap.to.mods or {}
        local toKey = remap.to.key or "?"

        if #toMods > 0 then
          toStr = string.format("%s + %s", table.concat(toMods, ", "), toKey)
        else
          toStr = toKey
        end
      else
        toStr = "?"
      end

      local formatTemplate = string.format("%s  →  %s", fromStr, toStr)
      if toStr == "?" then
        formatTemplate = string.format("%s", fromStr)
      end

      table.insert(choices, {
        text = remap.action or "(no action)",
        -- subText = string.format("%s  →  %s", fromStr, toStr),
        subText = formatTemplate,
      })
    end

    ::continue::
  end

  table.sort(choices, function(a, b)
    -- Sort by action text, but put modal remaps at the end
    if a.text == "(no action)" then return false end
    if b.text == "(no action)" then return true end
    return a.text < b.text
  end)

  return choices
end

local function showKeybindingsHelp()
  logger.info("Showing keybindings help", "usage")

  -- Get all keybindings from all modules
  local modules = {
    require('keybindings/application-management'),
    require('keybindings/browser-navigation'),
    require('keybindings/text-editing'),
    require('keybindings/general-system'),
    require('mouse/mouse'),
    require('spaces/spaces'),
    require('keybindings/text-cursor-movement'),
    require('keybindings/text-selection'),
    require('windows')
  }

  -- Collect all keybindings with their module names
  local allKeybindings = {}
  for _, module in ipairs(modules) do
    if module.rules then
      for _, rule in ipairs(module.rules) do
        rule.module = module.name or "General"
        table.insert(allKeybindings, rule)
      end
    end
  end

  -- Group by module
  local grouped = groupByModule(allKeybindings)

  -- Build the help text
  local helpText = {}

  -- Sort modules alphabetically
  local sortedModules = {}
  for moduleName in pairs(grouped) do
    table.insert(sortedModules, moduleName)
  end
  table.sort(sortedModules)

  -- Build help text for each module
  for _, moduleName in ipairs(sortedModules) do
    table.insert(helpText, "\n" .. moduleName .. ":\n" .. string.rep("=", #moduleName + 1))

    -- Sort bindings by action
    table.sort(grouped[moduleName], function(a, b)
      return (a.action or "") < (b.action or "")
    end)

    -- Find the longest action and from strings for formatting
    local maxActionLength = 0
    local maxFromLength = 0

    for _, binding in ipairs(grouped[moduleName]) do
      maxActionLength = math.max(maxActionLength, #(binding.action or ""))
      maxFromLength = math.max(maxFromLength, #formatKeyCombo(binding.from))
    end

    -- Add each binding
    for _, binding in ipairs(grouped[moduleName]) do
      local action = binding.action or ""
      local from = formatKeyCombo(binding.from)
      local to = formatKeyCombo(binding.to)

      -- Format the line with consistent spacing
      local line = string.format("  %-" .. (maxActionLength + 2) .. "s  %-" .. (maxFromLength + 2) .. "s  %s",
                               action .. ":", from, to)
      table.insert(helpText, line)
    end
  end

 hs.alert.show(table.concat(helpText), 5)
end

local function init(shortcuts)
  -- Register the keybinding to show the help
  hs.hotkey.bind({ "ctrl", "cmd" }, "k", showKeybindingsHelp)

  hs.hotkey.bind({ "ctrl", "cmd" }, "H", function()
    cheatsheet.toggle(shortcuts)
  end)

  -- Keep the old chooser-based interface as well
  hs.hotkey.bind({ "ctrl", "cmd", "shift" }, "k", function()
    local chooser = hs.chooser.new(function(_) end)
    chooser:width(40)
    chooser:rows(15)
    chooser:placeholderText("Keybindings")
    chooser:choices(buildChoices(shortcuts))
    chooser:show()
  end)
end

return {
  name = "show-keybindings",
  init = init,
}
