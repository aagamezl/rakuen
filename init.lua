-- Rakuen entry point. ~/.hammerspoon/init.lua sets package.path to this folder and runs it.

local binder = require("rakuen.core.binder")
local config = require("rakuen.core.config")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

local CONFIG_PATH = os.getenv("HOME") .. "/.config/rakuen/config.lua"
local RELOAD_MODIFIERS = { "ctrl", "alt", "cmd" }
local RELOAD_KEY = "r"

local settings, config_error = config.load(CONFIG_PATH)
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

hs.hotkey.bind(RELOAD_MODIFIERS, RELOAD_KEY, function()
  rakuen_binder:stop()
  hs.reload()
end)

hs.alert.show("Rakuen is ready (" .. settings.mode .. " mode)")
