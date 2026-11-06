-- Luacheck configuration for Rakuen (Hammerspoon runs Lua 5.4).
std = "lua54"
max_line_length = 100
codes = true

-- Globals provided by Hammerspoon at runtime.
read_globals = {
  "hs",
}

-- Tests run under busted, which provides these globals.
files["spec/**/*.lua"] = {
  std = "+busted",
}
