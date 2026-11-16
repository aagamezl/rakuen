-- Rakuen entry point. ~/.hammerspoon/init.lua sets package.path to this folder and runs it.

-- Lets bin/install.sh reach Hammerspoon through the hs command line tool.
require("hs.ipc")

local binder = require("rakuen.core.binder")
local cheatsheet = require("rakuen.ui.cheatsheet")
local config = require("rakuen.core.config")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local menubar = require("rakuen.ui.menubar")
local module_state = require("rakuen.core.module_state")
local registry = require("rakuen.core.registry")

local CONFIG_PATH = os.getenv("HOME") .. "/.config/rakuen/config.lua"
local RELOAD_MODIFIERS = { "ctrl", "alt", "cmd" }
local RELOAD_KEY = "r"
local CHEATSHEET_MODIFIERS = { "ctrl", "alt" }
local CHEATSHEET_KEY = "/"

local MODULES_PATH = os.getenv("HOME") .. "/.config/rakuen/modules.json"

local settings, config_error = config.load(CONFIG_PATH)
local module_overrides = module_state.load(MODULES_PATH)
module_state.apply(settings, module_overrides)
local rakuen_logger = logger.new(settings.log_level)

if config_error ~= nil then
  rakuen_logger:error("config ignored, using defaults: " .. config_error)
end

local rakuen_registry = registry.new()
local loaded_modules = loader.load({
  settings = settings,
  registry = rakuen_registry,
  logger = rakuen_logger,
})

rakuen_logger:info("modules loaded: " .. table.concat(loaded_modules, ", "))

local rakuen_binder = binder.new({
  registry = rakuen_registry,
  logger = rakuen_logger,
  mode = settings.mode,
})

rakuen_binder:start()

local function show_cheatsheet()
  local succeeded, toggle_error = pcall(cheatsheet.toggle, rakuen_registry)

  if not succeeded then
    hs.alert.show("Rakuen: cheatsheet failed. " .. tostring(toggle_error))
  end
end

local function module_enabled()
  local enabled = {}
  for _, name in ipairs(config.MODULE_NAMES) do
    enabled[name] = config.is_module_enabled(settings, name)
  end
  return enabled
end

local function switch_module(name, enabled)
  local updated = module_state.with(module_overrides, name, enabled)
  local saved, save_error = module_state.save(MODULES_PATH, updated)

  if not saved then
    hs.alert.show("Rakuen: could not save modules. " .. tostring(save_error))
    return
  end

  rakuen_binder:stop()
  hs.reload()
end

menubar.configure({
  on_cheatsheet = show_cheatsheet,
  module_names = config.MODULE_NAMES,
  module_enabled = module_enabled,
  on_module_toggle = switch_module,
})

hs.hotkey.bind(RELOAD_MODIFIERS, RELOAD_KEY, function()
  rakuen_binder:stop()
  hs.reload()
end)

hs.hotkey.bind(CHEATSHEET_MODIFIERS, CHEATSHEET_KEY, show_cheatsheet)

hs.alert.show("Rakuen is ready (" .. settings.mode .. " mode)")
