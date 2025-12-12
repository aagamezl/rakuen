-- Window management
local windows = require('windows')

windows.init()

myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", utils.reloadConfig):start()

hs.alert.show("Config loaded")

