local logger = require('utils/logger')

local menubar = hs.menubar.new()
-- local USAGE_PREFIX = "💻 "
local USAGE_PREFIX = "CPU: "
local refreshInterval = 3
local cpuTimer = nil
local isEnabled = true

--- Get the CPU usageString
local function getCPUUsage()
  -- local cmd = "ps -A -o %cpu | awk '{s+=$1} END {print s \"%\"}'"
  -- local handle = io.popen(cmd)
  -- local result = handle:read("*a")
  -- handle:close()
  -- return result:gsub("%s+", "")   -- Remove any whitespace

  local cpuUsage = hs.host.cpuUsage()

  local usageString = string.format("%04.1f%%", cpuUsage.overall.active)

  return usageString
end

--- Update the CPU usage display
local function updateCPU()
  local usage = getCPUUsage()

  menubar:setTitle(USAGE_PREFIX .. usage)
end

--- Initialize the CPU usage display
local function init()
  if menubar then
    if cpuTimer and cpuTimer:running() then
      cpuTimer:stop()
    end

    menubar:removeFromMenuBar()

    menubar:setTooltip("CPU Usage")

    local status = (isEnabled and "Disable" or "Enable")

    menubar:setMenu({
      {
        title = status,
        fn = function()
          isEnabled = not isEnabled

          init()
        end
      },
      { title = "-" },
      {
        title = "Refresh Interval",
        fn = function() end,
        menu = {
          {
            title = "2 seconds",
            fn = function()
              refreshInterval = 2

              init()
            end,
            checked = refreshInterval == 2
          },
          {
            title = "3 seconds",
            fn = function()
              refreshInterval = 3

              init()
            end,
            checked = refreshInterval == 3
          },
          {
            title = "5 seconds",
            fn = function()
              refreshInterval = 5

              init()
            end,
            checked = refreshInterval == 5
          },
        }
      },
    })

    menubar:returnToMenuBar()


    if (isEnabled) then
      -- cpuTimer:start()
      updateCPU()

      cpuTimer = hs.timer.doEvery(refreshInterval, updateCPU)
    else
      menubar:setTitle(USAGE_PREFIX .. "----")
    end
  end
  return menubar
end

--- Toggle the CPU usage display
local function toggle()
  logger.info("Toggling CPU", "cpu-usage")

  if cpuTimer and cpuTimer:running() then
    cpuTimer:stop()

    menubar:setTitle("")
  else
    cpuTimer:start()

    updateCPU()
  end
end

local keybindings = {
  name = "CPU",
  rules = {
    {
      action = "Toggle CPU Usage",
      from = { mods = { "ctrl", "cmd" }, key = "c" },
      to = {
        handler = toggle
      }
    }
  }
}

return {
  version = "1.1.0",
  name = "cpu-usage",
  description = "Display CPU Usage in the taskbar",
  author = {
    name = "Álvaro José Agámez Licha",
    email = "alvaroagamez@outlook.com"
  },
  keybindings = keybindings,
  init = init
}