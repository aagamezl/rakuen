-- Binder: one keyDown eventtap that dispatches to the registry.
--
-- Modes:
--   "log"   logs every key and lets it continue untouched (task 2.6).
--   "match" runs the matching rule's action and swallows only that key (task 2.7).
--
-- Guard rails (task 2.8):
--   * a handler error never blocks input (pcall, event passes through);
--   * a watchdog restarts the tap if macOS disables it;
--   * a panic hotkey turns Rakuen off and on without touching the tap.

local keycombo = require("rakuen.core.keycombo")
local synthetic = require("rakuen.core.synthetic")

local binder = {}
binder.__index = binder

local WATCHDOG_SECONDS = 5
local PANIC_MODIFIERS = { "ctrl", "alt", "cmd" }
local PANIC_KEY = "escape"

--- Create a binder.
--- options: registry (required), logger (required), mode ("log" or "match", default "log").
--- options.run_action (optional) replaces the action runner, for tests.
function binder.new(options)
  assert(options.registry, "binder needs a registry")
  assert(options.logger, "binder needs a logger")

  local mode = options.mode or "log"
  assert(mode == "log" or mode == "match", "mode must be 'log' or 'match'")

  local self = setmetatable({}, binder)
  self.registry = options.registry
  self.logger = options.logger
  self.mode = mode
  self.run_action = options.run_action or binder.run_action
  self.paused = false
  self.tap = nil
  self.watchdog = nil
  self.panic_hotkey = nil
  return self
end

--- Run a rule's action: call a function, or post a marked translated key.
function binder.run_action(rule)
  local action = rule.action
  if type(action) == "function" then
    action()
    return
  end
  synthetic.post_key(action.mods, action.key)
end

--- Decide what to do with one key press. Returns true when the key must be swallowed.
--- Pure apart from the injected action runner, so it can be tested without hs.
function binder:handle_chord(chord, bundle_id, marker)
  if synthetic.is_marked(marker) then
    return false
  end

  if self.paused then
    return false
  end

  if self.mode == "log" then
    self.logger:info(string.format("key %s app=%s", chord, tostring(bundle_id)))
    return false
  end

  local rule = self.registry:find(chord, bundle_id)
  if rule == nil then
    return false
  end

  self.logger:debug(string.format("match %s -> %s (%s)", chord, rule.description, rule.module))
  self.run_action(rule)
  return true
end

local function read_event(event)
  local key_name = hs.keycodes.map[event:getKeyCode()] or ("keycode_" .. event:getKeyCode())
  local chord = keycombo.from_event(event:getFlags(), key_name)
  local marker = event:getProperty(hs.eventtap.event.properties.eventSourceUserData)
  return chord, marker
end

local function frontmost_bundle_id()
  local app = hs.application.frontmostApplication()
  if app == nil then
    return nil
  end
  return app:bundleID()
end

--- Handle a raw event. Never raises: on error the key passes through.
function binder:handle_event(event)
  local succeeded, result = pcall(function()
    local chord, marker = read_event(event)
    return self:handle_chord(chord, frontmost_bundle_id(), marker)
  end)

  if not succeeded then
    self.logger:error("handler error: " .. tostring(result))
    return false
  end

  return result
end

function binder:toggle_pause()
  self.paused = not self.paused
  local state = "paused"
  if not self.paused then
    state = "active"
  end
  self.logger:warn("Rakuen is " .. state)
  hs.alert.show("Rakuen " .. state)
end

--- Start the tap, the watchdog and the panic hotkey.
function binder:start()
  self:stop()

  self.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    return self:handle_event(event)
  end)
  self.tap:start()

  self.watchdog = hs.timer.doEvery(WATCHDOG_SECONDS, function()
    if self.tap ~= nil and not self.tap:isEnabled() then
      self.logger:warn("event tap was disabled by macOS, restarting")
      self.tap:start()
    end
  end)

  self.panic_hotkey = hs.hotkey.bind(PANIC_MODIFIERS, PANIC_KEY, function()
    self:toggle_pause()
  end)

  self.logger:info(string.format("binder started in %s mode", self.mode))
end

function binder:stop()
  if self.tap ~= nil then
    self.tap:stop()
    self.tap = nil
  end

  if self.watchdog ~= nil then
    self.watchdog:stop()
    self.watchdog = nil
  end

  if self.panic_hotkey ~= nil then
    self.panic_hotkey:delete()
    self.panic_hotkey = nil
  end
end

return binder
