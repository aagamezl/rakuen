-- Bundle ids shared by keybinding modules.
-- An empty enable list means the binding applies to every application.

local terminals = {
  "com.apple.Terminal",
  "com.googlecode.iterm2",
  "com.github.wez.wezterm",
  "org.alacritty",
  "net.kovidgoyal.kitty",
}

local browsers = {
  "com.apple.Safari",
  "com.google.Chrome",
  "org.mozilla.firefox",
  "com.microsoft.edgemac",
  "com.brave.Browser",
  "company.thebrowser.Browser",
  "com.operasoftware.Opera",
  "com.vivaldi.Vivaldi",
}

local editors = {
  "com.microsoft.VSCode",
  "com.todesktop.230313mzl4w4u92",
}

local function concat(...)
  local result = {}

  for _, list in ipairs({ ... }) do
    for _, id in ipairs(list) do
      table.insert(result, id)
    end
  end

  return result
end

return {
  terminals = terminals,
  browsers = browsers,
  -- Apps that already treat Ctrl+Tab as their own tab switch.
  tabApps = concat(browsers, editors, terminals),
  -- Apps that already use Command+number for their own tabs or channels.
  numberApps = concat(browsers, editors, terminals, { "com.tinyspeck.slackmacgap" }),
}
