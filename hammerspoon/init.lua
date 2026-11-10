local binder = require("core.binder")
local cheatsheet = require("modules.cheatsheet")

local modules = {
  require("modules.editing"),
  require("modules.text-navigation"),
  require("modules.windows"),
  require("modules.focus"),
  require("modules.workspaces"),
  require("modules.shell"),
  require("modules.session"),
  require("modules.accessibility"),
}

-- The cheatsheet row is registered with the other modules so it appears in the list.
cheatsheet:attach()
table.insert(modules, cheatsheet)

binder.start(modules)

hs.pathwatcher.new(hs.configdir, function()
  hs.reload()
end):start()

hs.alert.show("Rakuen Config Reloaded")
