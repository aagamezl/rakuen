local logger = require('utils/logger')

local menubar = hs.menubar.new()

--- Set the caffeine display
--- @param state boolean The state of the caffeine MenuBar
local function setCaffeineDisplay(state)
  if state then
    menubar:setTitle("☕ Awake")
  else
    menubar:setTitle("🛏 Sleep")
  end
end

--- Toggle the caffeine MenuBar
local function toggle()
  logger.info("Toggling caffeine", "caffeine")

  setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

--- Initialize the caffeine MenuBar
local function init()
  if menubar then
    menubar:setTooltip("Click to toggle system sleep/wake state, Ctrl+Cmd+K to toggle Caffeine")
    menubar:setClickCallback(toggle)

    -- Set initial state to awake
    toggle()

    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
  end
end

local keybindings = {
  name = "Caffeine",
  rules = {
    {
      action = "Toggle Caffeine",
      from = { mods = { "ctrl", "cmd" }, key = "k" },
      to = {
        handler = toggle
      }
    }
  }
}

return {
  version = "1.0.0",
  name = "caffeine",
  description = "Displays a menubar item indicating if the system is awake or asleep",
  author = {
    name = "Álvaro José Agámez Licha",
    email = "alvaroagamez@outlook.com"
  },
  keybindings = keybindings,
  init = init
}