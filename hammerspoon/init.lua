local mergeObjects = require('utils/mergeObjects')
local reloadConfig = require('utils/reloadConfig')

-- Window management
local windows = require('windows')

-- Keybindings Events management
local attachEvents = require('keybindings/utils/attachEvents')
local usage = require('keybindings/utils/usage')

-- Keybindings
local applicationManagement = require('keybindings/application-management')
local browserNavigation = require('keybindings/browser-navigation')
local editingText = require('keybindings/editing-text')
local generalSystem = require('keybindings/general-system')
local mouse = require('mouse/mouse')
local spaces = require("spaces/spaces")
local textCursorMovement = require('keybindings/text-cursor-movement')
local textSelection = require('keybindings/text-selection')

-- local dragWindowToSpace = require("spaces/spaces2")

-- Initialize Keybindings
local keybindings = mergeObjects(
  applicationManagement,
  browserNavigation,
  editingText,
  generalSystem,
  mouse,
  spaces,
  textCursorMovement,
  textSelection,
  windows
)

-- Initialize Keybindings
attachEvents(keybindings)

-- Initialize Usage
usage.init(keybindings)

-- Reload config on change
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Config loaded")
