-- Decide when an app quits after a window closes (design decision D11).
--
-- Pure: no hs calls. rakuen/modules/applications.lua gathers the facts about
-- the app and its windows, and this file decides.

local app_filter = require("rakuen.core.app_filter")

local quit_policy = {}

--- Count the windows that keep an app alive.
--- Each window is { standard, minimized, fullscreen }. Minimized and fullscreen
--- windows count: the app still has them, they are only out of sight.
--- Sheets, panels and popovers (not standard) do not count.
function quit_policy.count_windows(windows)
  local count = 0

  for _, window in ipairs(windows) do
    if window.standard or window.minimized or window.fullscreen then
      count = count + 1
    end
  end

  return count
end

--- Return true when the app should quit.
--- app_info: { bundle_id, regular, hidden }. `regular` is false for menu bar
--- and background apps, which have no windows by design. A hidden app (Cmd+H)
--- reports no windows, so it never quits.
--- `filter` is { enable, disable } (D4).
function quit_policy.should_quit(app_info, window_count, filter)
  if not app_info.regular or app_info.hidden then
    return false
  end

  if app_info.bundle_id == nil then
    return false
  end

  if window_count > 0 then
    return false
  end

  return app_filter.allows(filter, app_info.bundle_id)
end

return quit_policy
