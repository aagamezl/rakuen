-- Luacheck configuration for Rakuen (Hammerspoon runs Lua 5.4).
std = "lua54"
max_line_length = 100
codes = true

-- Tests run under busted, which provides these globals.
files["spec/**/*.lua"] = {
  std = "+busted",
}

-- Docs text lives in long strings; wrapping them would change the generated docs.
files["scripts/docs_data.lua"] = {
  max_line_length = false,
}

-- `hs` is provided by Hammerspoon at runtime. The RAKUEN_AX_* globals are shared with
-- bin/ax-watch through the Hammerspoon console.
globals = { "RAKUEN_AX_WATCH" }
read_globals = { "hs", "RAKUEN_AX_KEYS", "RAKUEN_AX_SECONDS" }
