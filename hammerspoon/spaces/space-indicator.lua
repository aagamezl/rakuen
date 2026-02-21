local config = {
  activeIcon = "□",
  alertIcon = "⬜",
  alertActiveIcon = "🔳",
  icon = "▧",
  menuBar = hs.menubar.new(false),
  previousScreen = hs.screen.mainScreen()
}

local function render()
  local activeScreen = hs.screen.mainScreen()
  local currentScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)
  local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
  local menuBarContent = ""
  local alertContent = ""

  for i = 1, #screenSpaces do
    if screenSpaces[i] == activeSpace then
      menuBarContent = menuBarContent .. config.activeIcon
      alertContent = alertContent .. config.alertActiveIcon
    else
      menuBarContent = menuBarContent .. config.icon
      alertContent = alertContent .. config.alertIcon
    end
  end

  if config.previousScreen == activeScreen then
    -- Show the alert on the current screen
    -- hs.alert.closeAll(0)
    -- hs.alert(alertContent, { radius = 10, textSize = 50 }, currentScreen)
  end

  config.menuBar:setTitle(menuBarContent)
end

local spaceWatcher = hs.spaces.watcher.new(function()
  render()
end)

local screenWatcher = hs.screen.watcher.newWithActiveScreen(function()
  render()

  config.previousScreen = hs.screen.mainScreen()
end)

local function init()
  config.menuBar:returnToMenuBar()
  render()

  spaceWatcher:start()
  screenWatcher:start()
end

local function stop()
  spaceWatcher:stop()
  screenWatcher:stop()

  config.menuBar:removeFromMenuBar()
end

return {
  version = "1.0.0",
  name = "space-indicator",
  description = "Displays a menubar item indicating the current space",
  author = {
    name = "Álvaro José Agámez Licha",
    email = "alvaroagamez@outlook.com"
  },
  init = init,
  render = render,
  stop = stop
}
