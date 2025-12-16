local mergeObjects = require('utils/mergeObjects')
local reloadConfig = require('utils/reloadConfig')

-- Window management
local windows = require('windows')

-- Keybindings Events management
local attachEvents = require('keybindings/utils/attachEvents')
local usage = require('keybindings/utils/usage')

-- Keybindings
local applicationManagement = require('keybindings/application-management')
local editingText = require('keybindings/editing-text')
local generalSystem = require('keybindings/general-system')
local textCursorMovement = require('keybindings/text-cursor-movement')
local textSelection = require('keybindings/text-selection')

-- Initialize Window module
windows.init()

-- Initialize Keybindings
local keybindings = mergeObjects(
  applicationManagement,
  editingText,
  generalSystem,
  textCursorMovement,
  textSelection
)

usage.init(keybindings)

-- Initialize Keybindings
attachEvents(keybindings)

-- Reload config on change
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Config loaded")

