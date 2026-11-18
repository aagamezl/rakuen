-- Bundle ids of app families that several modules treat alike.

local app_groups = {}

app_groups.TERMINALS = {
  "com.apple.Terminal",
  "com.googlecode.iterm2",
  "com.github.wez.wezterm",
  "net.kovidgoyal.kitty",
  "org.alacritty",
  "com.mitchellh.ghostty",
}

app_groups.BROWSERS = {
  "com.apple.Safari",
  "com.google.Chrome",
  "org.mozilla.firefox",
  "com.brave.Browser",
  "com.microsoft.edgemac",
  "company.thebrowser.Browser",
}

return app_groups
