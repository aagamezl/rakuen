local mergeObjects = require("utils/mergeObjects")
local reloadConfig = require("utils/reloadConfig")

-- Window management
local windows = require("windows")

-- Keybindings Events management
local keyEventListener = require("keybindings/utils/key-event-listener").keyEventListener

-- Keybindings
local applicationManagement = require("keybindings/application-management")
local browserNavigation = require("keybindings/browser-navigation")
local caffeine = require("caffeine/caffeine")
local cpu = require("system-stats/cpu")
local generalSystem = require("keybindings/general-system")
-- local mouse = require("mouse/mouse")
local spaces = require("spaces/spaces")
local textCursorMovement = require("keybindings/text-cursor-movement")
local textEditing = require("keybindings/text-editing")
local textSelection = require("keybindings/text-selection")
local usage = require("usage/usage")

-- Initialize Keybindings
local shortcutsRules = mergeObjects(
-- applicationManagement.rules,
-- browserNavigation.rules,
-- textEditing.rules,
-- generalSystem.rules,
-- mouse.rules,
-- spaces.rules,
-- textCursorMovement.rules,
-- textSelection.rules,
-- usage.rules,
-- windows.rules

  applicationManagement.rules,
  browserNavigation.rules,
  caffeine.keybindings.rules,
  cpu.keybindings.rules,
  generalSystem.rules,
  -- mouse.rules,
  spaces.rules,
  textCursorMovement.rules,
  textEditing.rules,
  textSelection.rules,
  usage.rules,
  windows.rules
)

-- Initialize Keybindings
keyEventListener(shortcutsRules)

caffeine.init()
cpu.init()

-- Reload config on change
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Rakuen Config Reloaded")