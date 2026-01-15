local mergeObjects = require('utils/mergeObjects')
local logger = require('utils/logger')
-- local cheatsheet = require('usage.cheatsheet')

-- Declare hs as a global variable to avoid lint errors
-- local hs = _ENV.hs or {}

-- Keybindings
local applicationManagement = require('keybindings/application-management')
local browserNavigation = require('keybindings/browser-navigation')
local textEditing = require('keybindings/text-editing')
local generalSystem = require('keybindings/general-system')
local mouse = require('mouse/mouse')
local spaces = require("spaces/spaces")
local textCursorMovement = require('keybindings/text-cursor-movement')
local textSelection = require('keybindings/text-selection')
local windows = require('windows')

local function buildChoices(shortcuts)
  local choices = {}

  -- Now remaps is a flat table, so iterate directly
  for _, shortcut in ipairs(shortcuts) do
    if shortcut then
      if shortcut.type == "modal" then
        goto continue
      end

      local fromMods = shortcut.from and shortcut.from.mods or {}
      local fromKey = shortcut.from and shortcut.from.key or "?"
      local formatTemplate = "%s + %s"

      if fromKey == "?" then
        formatTemplate = "%s"
      end

      local fromStr
      if #fromMods > 0 then
        fromStr = string.format(formatTemplate, table.concat(fromMods, ", "):upper(), fromKey:upper())
      else
        fromStr = fromKey:upper()
      end

      local toStr
      if shortcut.to and shortcut.to.app then
        toStr = string.format("Launch app '%s'", shortcut.to.app)
      elseif shortcut.to then
        local toMods = shortcut.to.mods or {}
        local toKey = shortcut.to.key or "?"

        if #toMods > 0 then
          toStr = string.format("%s + %s", table.concat(toMods, ", "):upper(), toKey:upper())
        else
          toStr = toKey:upper()
        end
      else
        toStr = "?"
      end

      local formatTemplate = string.format("%s  →  %s", fromStr, toStr)
      if toStr == "?" then
        formatTemplate = string.format("%s", fromStr)
      end

      table.insert(choices, {
        text = shortcut.action or "(no action)",
        subText = formatTemplate,
        -- shortcut = shortcut
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


-- local function showKeybindingsHelp()
--   logger.info("Showing keybindings help", "usage")

--   -- Get all keybindings from all modules
--   local modules = {
--     require('keybindings/application-management'),
--     require('keybindings/browser-navigation'),
--     require('keybindings/text-editing'),
--     require('keybindings/general-system'),
--     require('mouse/mouse'),
--     require('spaces/spaces'),
--     require('keybindings/text-cursor-movement'),
--     require('keybindings/text-selection'),
--     require('windows')
--   }

--   -- Collect all keybindings with their module names
--   local allKeybindings = {}
--   for _, module in ipairs(modules) do
--     if module.rules then
--       for _, rule in ipairs(module.rules) do
--         rule.module = module.name or "General"
--         table.insert(allKeybindings, rule)
--       end
--     end
--   end

--   -- Group by module
--   local grouped = groupByModule(allKeybindings)

--   -- Build the help text
--   local helpText = {}

--   -- Sort modules alphabetically
--   local sortedModules = {}
--   for moduleName in pairs(grouped) do
--     table.insert(sortedModules, moduleName)
--   end
--   table.sort(sortedModules)

--   -- Build help text for each module
--   for _, moduleName in ipairs(sortedModules) do
--     table.insert(helpText, "\n" .. moduleName .. ":\n" .. string.rep("=", #moduleName + 1))

--     -- Sort bindings by action
--     table.sort(grouped[moduleName], function(a, b)
--       return (a.action or "") < (b.action or "")
--     end)

--     -- Find the longest action and from strings for formatting
--     local maxActionLength = 0
--     local maxFromLength = 0

--     for _, binding in ipairs(grouped[moduleName]) do
--       maxActionLength = math.max(maxActionLength, #(binding.action or ""))
--       maxFromLength = math.max(maxFromLength, #formatKeyCombo(binding.from))
--     end

--     -- Add each binding
--     for _, binding in ipairs(grouped[moduleName]) do
--       local action = binding.action or ""
--       local from = formatKeyCombo(binding.from)
--       local to = formatKeyCombo(binding.to)

--       -- Format the line with consistent spacing
--       local line = string.format("  %-" .. (maxActionLength + 2) .. "s  %-" .. (maxFromLength + 2) .. "s  %s",
--         action .. ":", from, to)
--       table.insert(helpText, line)
--     end
--   end

--   hs.alert.show(table.concat(helpText), 5)
-- end

local function getShortcurtByAction(shortcuts, action)
  for _, shortcut in ipairs(shortcuts) do
    if shortcut.action == action then
      return shortcut
    end
  end
end

local shortcuts = mergeObjects(
  applicationManagement.rules,
  browserNavigation.rules,
  textEditing.rules,
  generalSystem.rules,
  mouse.rules,
  spaces.rules,
  textCursorMovement.rules,
  textSelection.rules,
  windows.rules
)

local keybindings = {
  name = "Usage",
  rules = {
    {
      action = "Show Keybindings Help",
      from = { mods = { "ctrl", "cmd" }, key = "h" },
      to = {
        handler = function()
          logger.info("Showing keybindings help", "usage")

          local chooser = hs.chooser.new(function(choice)
            if not choice then
              return
            end

            local shortcut = getShortcurtByAction(shortcuts, choice.text)

            if not shortcut then
              logger.error("Shortcut not found for action: " .. choice.text, "usage")
              return
            end

            if shortcut.to.handler then
              -- If there's a handler function, call it
              shortcut.to.handler()
            elseif shortcut.to.app then
              -- If it's an app launcher
              hs.application.launchOrFocus(shortcut.to.app)
            elseif shortcut.to.key then
              -- If it's a key sequence, send the key event
              local mods = shortcut.to.mods or {}
              hs.eventtap.keyStroke(mods, shortcut.to.key, 0)
            end
          end)

          chooser:width(40)
          chooser:rows(15)
          chooser:placeholderText("Keybindings")
          chooser:choices(buildChoices(shortcuts))

          chooser:show()
        end
      },
    },
  }
}

return keybindings