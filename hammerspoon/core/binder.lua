-- One event tap for every module. Synthetic keystrokes are tagged so a remap
-- cannot match another Rakuen rule (Ctrl+Home posts Cmd+Up and must not maximize).

local textfield = require("core.textfield")

-- keyboardEventAutorepeat survives posting and is visible to this tap.
-- It is cleared before the event reaches the app so the key is not treated as a repeat.
local SYNTHETIC_PROPERTY = hs.eventtap.event.properties.keyboardEventAutorepeat
local SYNTHETIC_TAG = 9999
local TRACKED_MODS = { "cmd", "alt", "shift", "ctrl" }

local MOD_LABELS = {
  ctrl = "Ctrl",
  alt = "Opt",
  shift = "Shift",
  cmd = "Cmd",
}

local KEY_LABELS = {
  left = "Left",
  right = "Right",
  up = "Up",
  down = "Down",
  home = "Home",
  ["end"] = "End",
  pageup = "PageUp",
  pagedown = "PageDown",
  delete = "Backspace",
  forwarddelete = "ForwardDelete",
  escape = "Escape",
  tab = "Tab",
  space = "Space",
  ["return"] = "Return",
  ["`"] = "grave",
}

local state = {
  rules = {},
  tap = nil,
  interceptor = nil,
}

local function contains(list, value)
  for _, item in ipairs(list or {}) do
    if item == value then
      return true
    end
  end

  return false
end

local function modsMatch(required, flags)
  for _, modifier in ipairs(TRACKED_MODS) do
    local need = contains(required, modifier)
    local pressed = flags[modifier] == true

    if need ~= pressed then
      return false
    end
  end

  return true
end

local function frontBundleId()
  local app = hs.application.frontmostApplication()

  return (app and app:bundleID()) or ""
end

local function applicationAllows(rule, bundleId)
  local apps = rule.applications or { enable = {}, disable = {} }

  if contains(apps.disable, bundleId) then
    return false
  end

  local enable = apps.enable or {}

  if #enable == 0 then
    return true
  end

  return contains(enable, bundleId)
end

local function isSynthetic(event)
  return event:getProperty(SYNTHETIC_PROPERTY) == SYNTHETIC_TAG
end

local function tag(event)
  event:setProperty(SYNTHETIC_PROPERTY, SYNTHETIC_TAG)

  return event
end

--- Post a key down/up pair that the binder will not intercept.
--- @param mods table
--- @param key string
local function fire(mods, key)
  tag(hs.eventtap.event.newKeyEvent(mods, key, true)):post()
  tag(hs.eventtap.event.newKeyEvent(mods, key, false)):post()
end

local function formatChord(mods, key)
  local parts = {}

  for _, modifier in ipairs({ "ctrl", "alt", "shift", "cmd" }) do
    if contains(mods, modifier) then
      table.insert(parts, MOD_LABELS[modifier])
    end
  end

  local label = KEY_LABELS[key]

  if not label then
    if key and #key == 1 then
      label = key:upper()
    elseif key and key:match("^f%d+$") then
      label = key:upper()
    else
      label = key or ""
    end
  end

  table.insert(parts, label)

  return table.concat(parts, "+")
end

local function runAction(rule)
  local action = rule.action

  if action == "passthrough" then
    return false
  end

  if type(action) == "function" then
    action()

    return true
  end

  if type(action) == "table" and action.key then
    fire(action.mods or {}, action.key)

    return true
  end

  return false
end

local function onKeyDown(event)
  if isSynthetic(event) then
    event:setProperty(SYNTHETIC_PROPERTY, 0)

    return false
  end

  local key = hs.keycodes.map[event:getKeyCode()]
  local flags = event:getFlags()

  if state.interceptor and state.interceptor(key, flags) then
    return true
  end

  local bundleId = frontBundleId()

  for _, rule in ipairs(state.rules) do
    if rule.key == key and modsMatch(rule.mods, flags) and applicationAllows(rule, bundleId) then
      if rule.whenText and not textfield.isEditableTextFocused() then
        -- Leave Mission Control and Space shortcuts intact outside text fields.
      elseif rule.action == "passthrough" then
        return false
      elseif runAction(rule) then
        return true
      end
    end
  end

  return false
end

local function collect(modules)
  local rules = {}

  for _, mod in ipairs(modules) do
    for _, rule in ipairs(mod.rules or {}) do
      rule.section = mod.name
      rule.configured = formatChord(rule.mods, rule.key)
      table.insert(rules, rule)
    end
  end

  state.rules = rules

  return rules
end

local function start(modules)
  collect(modules)

  if state.tap then
    state.tap:stop()
  end

  state.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, onKeyDown)
  state.tap:start()

  return state.rules
end

local function setInterceptor(fn)
  state.interceptor = fn
end

local function pause()
  if state.tap then
    state.tap:stop()
  end
end

local function resume()
  if state.tap then
    state.tap:start()
  end
end

return {
  start = start,
  collect = collect,
  fire = fire,
  formatChord = formatChord,
  setInterceptor = setInterceptor,
  pause = pause,
  resume = resume,
  rules = function()
    return state.rules
  end,
}
