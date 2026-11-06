-- Phase 1 feasibility spikes for Rakuen.
--
-- Run from the Hammerspoon console:
--   local path = "/workspace/personal/git-repos/rakuen/scripts/spikes/spikes.lua"
--   spikes = dofile(os.getenv("HOME") .. path)
--   spikes.help()
--
-- Every spike logs to the Hammerspoon console and to ~/rakuen-spike-log.txt.
-- Each spike stops by itself after SPIKE_SECONDS, so a mistake never leaves
-- keys swallowed.

local LOG_PATH = os.getenv("HOME") .. "/rakuen-spike-log.txt"
local SYNTHETIC_MARKER = 0x52414B55
local SPIKE_SECONDS = 30
local INSPECT_DELAY_SECONDS = 5
local MODIFIER_ORDER = { "ctrl", "alt", "cmd", "shift" }

-- Chords swallowed by spikes.swallow_test (spikes 1.4 and 1.5).
local SWALLOW_CHORDS = {
  ["ctrl+left"] = true,
  ["ctrl+right"] = true,
  ["ctrl+up"] = true,
  ["ctrl+down"] = true,
  ["ctrl+tab"] = true,
  ["ctrl+shift+tab"] = true,
  ["cmd+`"] = true,
  ["alt+tab"] = true,
  ["alt+space"] = true,
  ["cmd+space"] = true,
  ["cmd+tab"] = true,
}

local spikes = {}
local active_spikes = {}

local function log(message)
  local line = os.date("%H:%M:%S") .. " " .. message
  print("[spike] " .. line)

  local file = io.open(LOG_PATH, "a")
  if file == nil then
    return
  end
  file:write(line .. "\n")
  file:close()
end

--- Return a normalized chord such as "ctrl+shift+left", the keycode, and
--- whether the fn flag was set. The fn flag is not part of the chord because
--- macOS sets it on arrow keys.
local function build_chord(event)
  local keycode = event:getKeyCode()
  local key_name = hs.keycodes.map[keycode] or ("keycode_" .. keycode)
  local flags = event:getFlags()

  local parts = {}
  for _, modifier in ipairs(MODIFIER_ORDER) do
    if flags[modifier] then
      table.insert(parts, modifier)
    end
  end
  table.insert(parts, key_name)

  return table.concat(parts, "+"), keycode, flags.fn == true
end

local function read_marker(event)
  return event:getProperty(hs.eventtap.event.properties.eventSourceUserData)
end

--- Wrap a handler so an error never blocks the user's keyboard.
local function protect(handler)
  return function(event)
    local succeeded, result = pcall(handler, event)
    if not succeeded then
      log("handler error: " .. tostring(result))
      return false
    end
    return result
  end
end

local function stop_spike(name)
  local entry = active_spikes[name]
  if entry == nil then
    return
  end

  entry.tap:stop()
  entry.timer:stop()
  active_spikes[name] = nil
  log("stopped spike: " .. name)
end

local function start_spike(name, handler)
  stop_spike(name)

  local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, protect(handler))
  local timer = hs.timer.doAfter(SPIKE_SECONDS, function()
    stop_spike(name)
  end)

  active_spikes[name] = { tap = tap, timer = timer }
  tap:start()

  log(
    string.format(
      "started spike: %s (auto-stops in %ds, secure_input=%s)",
      name,
      SPIKE_SECONDS,
      tostring(hs.eventtap.isSecureInputEnabled())
    )
  )
end

-- Spike 1.5 and 1.6: log every key without changing anything.
local function log_key_handler(event)
  local chord, keycode, has_fn = build_chord(event)
  log(
    string.format(
      "key chord=%s keycode=%d fn=%s marker=%s",
      chord,
      keycode,
      tostring(has_fn),
      tostring(read_marker(event))
    )
  )
  return false
end

-- Spike 1.4 and 1.5: swallow chords to see if macOS still reacts to them.
local function swallow_handler(event)
  local chord, keycode, has_fn = build_chord(event)
  if SWALLOW_CHORDS[chord] then
    log(
      string.format(
        "SWALLOWED chord=%s keycode=%d fn=%s -> did macOS still react?",
        chord,
        keycode,
        tostring(has_fn)
      )
    )
    return true
  end
  return false
end

-- Spike 1.8: post marked and unmarked synthetic keys and see what the tap receives.
local function post_key(key_name, marker)
  for _, is_down in ipairs({ true, false }) do
    local event = hs.eventtap.event.newKeyEvent({}, key_name, is_down)
    if marker ~= nil then
      event:setProperty(hs.eventtap.event.properties.eventSourceUserData, marker)
    end
    event:post()
  end
end

local function marker_handler(event)
  local chord = build_chord(event)

  if chord == "ctrl+j" then
    log("posting MARKED synthetic f19")
    post_key("f19", SYNTHETIC_MARKER)
    return true
  end

  if chord == "ctrl+k" then
    log("posting UNMARKED synthetic f20")
    post_key("f20", nil)
    return true
  end

  if chord == "f19" or chord == "f20" then
    log(
      string.format(
        "tap received own event chord=%s marker=%s",
        chord,
        tostring(read_marker(event))
      )
    )
  end
  return false
end

-- Spike 1.7: inspect the focused accessibility element.
local function describe_element(source, element)
  if element == nil then
    log("  focus[" .. source .. "] = nil")
    return
  end

  local selected_range = element:attributeValue("AXSelectedTextRange")
  log(
    string.format(
      "  focus[%s] role=%s subrole=%s has_selected_text_range=%s",
      source,
      tostring(element:attributeValue("AXRole")),
      tostring(element:attributeValue("AXSubrole")),
      tostring(selected_range ~= nil)
    )
  )
end

local function read_focus(label)
  local app = hs.application.frontmostApplication()
  log(string.format("focus %s: app=%s", label, tostring(app:bundleID())))

  local system_element = hs.axuielement.systemWideElement()
  describe_element("system_wide", system_element:attributeValue("AXFocusedUIElement"))

  local app_element = hs.axuielement.applicationElement(app)
  describe_element("application", app_element:attributeValue("AXFocusedUIElement"))

  return app_element
end

local function inspect_focus_now()
  local app_element = read_focus("before AXManualAccessibility")
  app_element:setAttributeValue("AXManualAccessibility", true)

  hs.timer.doAfter(1, function()
    read_focus("after AXManualAccessibility")
  end)
end

function spikes.log_keys()
  start_spike("log_keys", log_key_handler)
end

function spikes.swallow_test()
  start_spike("swallow_test", swallow_handler)
end

function spikes.synthetic_marker()
  start_spike("synthetic_marker", marker_handler)
end

function spikes.inspect_focus()
  log(string.format("inspect_focus: click into a text field now (%ds)", INSPECT_DELAY_SECONDS))
  hs.timer.doAfter(INSPECT_DELAY_SECONDS, function()
    local succeeded, error_message = pcall(inspect_focus_now)
    if not succeeded then
      log("inspect_focus error: " .. tostring(error_message))
    end
  end)
end

function spikes.stop_all()
  local names = {}
  for name in pairs(active_spikes) do
    table.insert(names, name)
  end

  for _, name in ipairs(names) do
    stop_spike(name)
  end
end

function spikes.help()
  print([[
Rakuen spikes (results also go to ~/rakuen-spike-log.txt)

  spikes.log_keys()          Spikes 1.5, 1.6. Logs every key for 30s, changes nothing.
                             Press Ctrl+Tab, Cmd+`, Opt+Tab, Opt+Space, Cmd+Space,
                             Cmd+Tab, Fn+Left, Fn+Right, Fn+Up, Fn+Down, Ctrl+Left.
  spikes.swallow_test()      Spikes 1.4, 1.5. For 30s swallows Ctrl+Arrows, Ctrl+Tab,
                             Ctrl+Shift+Tab, Cmd+`, Opt+Tab, Opt+Space, Cmd+Space, Cmd+Tab.
                             Press each one and note whether macOS still reacted.
  spikes.synthetic_marker()  Spike 1.8. For 30s: Ctrl+J posts a marked F19, Ctrl+K posts
                             an unmarked F20. The log shows what the tap receives.
  spikes.inspect_focus()     Spike 1.7. Run it, then within 5s click into a text field
                             of the app under test. Repeat per app.
  spikes.stop_all()          Stop every running spike.
]])
end

return spikes
