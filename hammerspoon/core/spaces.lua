-- Mission Control ignores key events that Hammerspoon posts itself.
-- System Events key codes are the shortcut Mission Control actually receives.
-- The event tap is paused while those keys are sent so Ctrl+Left in a text
-- field stays "previous word" and is not treated as a Space switch.
-- Left arrow is 123, right arrow is 124.

local binder = require("core.binder")

local KEY_CODES = {
  left = 123,
  right = 124,
}

local function move(key, times)
  local code = KEY_CODES[key]

  if not code then
    return
  end

  times = times or 1

  local script = string.format(
    'tell application "System Events" to repeat %d times\nkey code %d using control down\nend repeat',
    times,
    code
  )

  hs.timer.doAfter(0, function()
    binder.pause()

    local ok = hs.osascript.applescript(script)

    binder.resume()

    if not ok then
      hs.alert.show("Allow Hammerspoon to control System Events to switch Spaces")
    end
  end)
end

return {
  move = move,
}
