--- Shared application bundle-ID groups used to scope keybinding rules via the
--- `only` / `except` fields. Centralizing these avoids drift between rules and
--- keeps a single source of truth for app classification.

--- Terminal emulators. Ctrl-based readline/emacs keys must stay native here.
--- @type string[]
local terminals = {
  "com.apple.Terminal",
  "com.googlecode.iterm2",
  "com.github.wez.wezterm",
  "org.alacritty",
  "net.kovidgoyal.kitty",
}

--- Code editors that ship their own keybindings (via imported settings).
--- @type string[]
local editors = {
  "com.exafunction.windsurf",
  "com.microsoft.VSCode",
  "com.todesktop.230313mzl4w4u92", -- Cursor
}

--- Web browsers.
--- @type string[]
local browsers = {
  "com.google.Chrome",
  "com.apple.Safari",
  "com.brave.Browser",
  "org.mozilla.firefox",
}

--- Concatenate one or more array-like lists into a new list.
--- @vararg string[]
--- @return string[]
local function concat(...)
  local result = {}

  for _, list in ipairs({ ... }) do
    for _, value in ipairs(list) do
      table.insert(result, value)
    end
  end

  return result
end

return {
  terminals = terminals,
  editors = editors,
  browsers = browsers,

  --- Apps that manage their own text shortcuts and should be excepted from
  --- the generic Ctrl->Cmd editing remaps.
  terminalsAndEditors = concat(terminals, editors),

  concat = concat,
}
