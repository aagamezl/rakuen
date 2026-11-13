-- Applications module: quit an app when its last window closes (D11).
--
-- GNOME ends an app with its last window; macOS keeps it running. The rule has
-- no chord: a window filter reports closed windows, and after a short delay (so
-- a window swap or a fullscreen change is not mistaken for a close) the app is
-- quit if no window is left. The quit is graceful (`hs.application:kill`, never
-- `kill9`), so an app with unsaved changes shows its own prompt.
--
-- Protect an app with the `applications` filter of the binding:
--   bindings = { ["Quit on last window"] = { applications = { disable = { "id" } } } }
-- A filter in the config replaces the default list below.

local quit_policy = require("rakuen.core.quit_policy")

local applications = {}

local RULE_NAME = "Quit on last window"
-- hs.application:kind(): 1 regular, 0 accessory, -1 prohibited.
local REGULAR_APP_KIND = 1
local COUNT_DELAY_SECONDS = 0.5

-- Apps that must keep running without a window, or keep working in the background.
local DEFAULT_DISABLE = {
  "com.apple.finder",
  "org.hammerspoon.Hammerspoon",
  "com.apple.Music",
  "com.spotify.client",
  "com.apple.podcasts",
}

local function window_info(window)
  return {
    standard = window:isStandard(),
    minimized = window:isMinimized(),
    fullscreen = window:isFullScreen(),
  }
end

local function app_windows(app)
  local infos = {}

  for _, window in ipairs(app:allWindows()) do
    table.insert(infos, window_info(window))
  end

  return infos
end

local function app_info(app)
  return {
    bundle_id = app:bundleID(),
    regular = app:kind() == REGULAR_APP_KIND,
    hidden = app:isHidden(),
  }
end

--- Quit `app` when it has no window left. Never forces the quit.
local function quit_if_windowless(app, filter, logger)
  if not app:isRunning() then
    return
  end

  local info = app_info(app)
  local count = quit_policy.count_windows(app_windows(app))

  if quit_policy.should_quit(info, count, filter) then
    logger:info("last window closed, quitting " .. tostring(info.bundle_id))
    app:kill()
  end
end

--- The app that owned a closed window. The window itself may be gone already.
local function owning_app(window, app_name)
  local found, app = pcall(function()
    return window:application()
  end)

  if found and app ~= nil then
    return app
  end

  return hs.application.get(app_name)
end

local function watch_closed_windows(filter, logger)
  local windows = hs.window.filter.new(true)

  windows:subscribe(hs.window.filter.windowDestroyed, function(window, app_name)
    local app = owning_app(window, app_name)
    if app == nil then
      return
    end

    hs.timer.doAfter(COUNT_DELAY_SECONDS, function()
      local succeeded, quit_error = pcall(quit_if_windowless, app, filter, logger)
      if not succeeded then
        logger:warn("quit on last window failed: " .. tostring(quit_error))
      end
    end)
  end)

  return windows
end

applications.rules = {
  {
    description = RULE_NAME,
    from = "none",
    to = "none",
    feasibility = "partial",
    note = "No chord. Quits an app gracefully after its last window closes. "
      .. "Finder, Hammerspoon and music apps are skipped by default. "
      .. "Windows on other Spaces may not be seen",
    applications = { disable = DEFAULT_DISABLE },
  },
}

--- Start watching. `rules` are the rules after the user's overrides, so a
--- disabled binding starts no watcher.
function applications.on_load(logger, rules)
  for _, rule in ipairs(rules) do
    if rule.description == RULE_NAME then
      applications.watcher = watch_closed_windows(rule.applications, logger)
    end
  end
end

return applications
