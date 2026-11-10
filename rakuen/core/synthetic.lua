-- Synthetic key events posted by Rakuen.
--
-- Every event Rakuen posts carries a marker in eventSourceUserData. The
-- binder ignores marked events, so Rakuen never remaps its own output.
-- Spike 1.8 confirmed the tap receives its own events with the marker intact.

local synthetic = {}

-- "RAKU" in ASCII.
synthetic.MARKER = 0x52414B55

--- Return true when an event's eventSourceUserData value is Rakuen's marker.
function synthetic.is_marked(marker_value)
  return marker_value == synthetic.MARKER
end

--- Post a key press and release carrying the Rakuen marker.
--- `modifiers` is a list like { "cmd" }; `key` is a Hammerspoon key name.
function synthetic.post_key(modifiers, key)
  assert(type(modifiers) == "table", "modifiers must be a table")
  assert(type(key) == "string", "key must be a string")

  for _, is_down in ipairs({ true, false }) do
    local event = hs.eventtap.event.newKeyEvent(modifiers, key, is_down)
    event:setProperty(hs.eventtap.event.properties.eventSourceUserData, synthetic.MARKER)
    event:post()
  end
end

return synthetic
