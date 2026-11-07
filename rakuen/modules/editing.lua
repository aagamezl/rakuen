-- Editing module: Ctrl performs what Cmd normally does (copy, paste, save, ...).
--
-- Each rule listens for a Ctrl chord and posts the matching Cmd chord.
-- Terminals keep their shell meaning for Ctrl+C, Ctrl+Z, and so on, so most
-- rules are disabled there; `Ctrl+Shift+C/V` copy and paste in terminals only.

local keycombo = require("rakuen.core.keycombo")

local editing = {}

local FINDER = "com.apple.finder"

local TERMINALS = {
  "com.apple.Terminal",
  "com.googlecode.iterm2",
  "com.github.wez.wezterm",
  "net.kovidgoyal.kitty",
  "org.alacritty",
  "com.mitchellh.ghostty",
}

-- Browsers already handle Ctrl+Tab themselves, so tab switching is left native there.
local BROWSERS = {
  "com.apple.Safari",
  "com.google.Chrome",
  "org.mozilla.firefox",
  "com.brave.Browser",
  "com.microsoft.edgemac",
  "company.thebrowser.Browser",
}

local function concat_lists(first, second)
  local result = {}
  for _, value in ipairs(first) do
    table.insert(result, value)
  end
  for _, value in ipairs(second) do
    table.insert(result, value)
  end
  return result
end

-- Where a rule applies. A missing scope means every application (task 3.1).
local SCOPES = {
  everywhere = nil,
  no_terminals = { disable = TERMINALS },
  terminals_only = { enable = TERMINALS },
  finder_only = { enable = { FINDER } },
  native_tabs = { disable = concat_lists(TERMINALS, BROWSERS) },
}

--- Build one rule. `action_mods` and `key` are the chord Rakuen posts.
local function make_rule(description, from, to, action_mods, key, scope, note)
  assert(scope == "everywhere" or SCOPES[scope] ~= nil, "unknown scope: " .. tostring(scope))

  return {
    description = description,
    from = from,
    to = to,
    applications = SCOPES[scope],
    action = { mods = action_mods, key = key },
    feasibility = "yes",
    note = note,
  }
end

local function make_rules()
  local rules = {
    make_rule("Copy", "Cmd+C", "Ctrl+C", { "cmd" }, "c", "no_terminals"),
    make_rule("Copy in terminal", "Cmd+C", "Ctrl+Shift+C", { "cmd" }, "c", "terminals_only"),
    make_rule("Paste", "Cmd+V", "Ctrl+V", { "cmd" }, "v", "no_terminals"),
    make_rule("Paste in terminal", "Cmd+V", "Ctrl+Shift+V", { "cmd" }, "v", "terminals_only"),
    make_rule("Cut", "Cmd+X", "Ctrl+X", { "cmd" }, "x", "no_terminals"),
    make_rule("Undo", "Cmd+Z", "Ctrl+Z", { "cmd" }, "z", "no_terminals"),
    make_rule("Redo", "Cmd+Shift+Z", "Ctrl+Y", { "cmd", "shift" }, "z", "no_terminals"),
    make_rule(
      "Redo alternate",
      "Cmd+Shift+Z",
      "Ctrl+Shift+Z",
      { "cmd", "shift" },
      "z",
      "everywhere"
    ),
    make_rule("Select all", "Cmd+A", "Ctrl+A", { "cmd" }, "a", "no_terminals"),
    make_rule("Save", "Cmd+S", "Ctrl+S", { "cmd" }, "s", "no_terminals"),
    make_rule("Save as", "Cmd+Shift+S", "Ctrl+Shift+S", { "cmd", "shift" }, "s", "everywhere"),
    make_rule("Find", "Cmd+F", "Ctrl+F", { "cmd" }, "f", "no_terminals"),
    make_rule("Find next", "Cmd+G", "Ctrl+G", { "cmd" }, "g", "no_terminals"),
    make_rule("New", "Cmd+N", "Ctrl+N", { "cmd" }, "n", "no_terminals"),
    make_rule("Open", "Cmd+O", "Ctrl+O", { "cmd" }, "o", "no_terminals"),
    make_rule(
      "Rename",
      "Return",
      "F2",
      {},
      "return",
      "finder_only",
      "Sends Return, which renames in Finder"
    ),
    make_rule("Close window or tab", "Cmd+W", "Ctrl+W", { "cmd" }, "w", "no_terminals"),
    make_rule("Close tab", "Cmd+W", "Ctrl+F4", { "cmd" }, "w", "everywhere"),
    make_rule("Quit", "Cmd+Q", "Ctrl+Q", { "cmd" }, "q", "no_terminals"),
    make_rule("New tab", "Cmd+T", "Ctrl+T", { "cmd" }, "t", "no_terminals"),
    make_rule("Next tab", "Cmd+Opt+Right", "Ctrl+Tab", { "cmd", "alt" }, "right", "native_tabs"),
    make_rule(
      "Previous tab",
      "Cmd+Opt+Left",
      "Ctrl+Shift+Tab",
      { "cmd", "alt" },
      "left",
      "native_tabs"
    ),
    make_rule("Bold", "Cmd+B", "Ctrl+B", { "cmd" }, "b", "no_terminals"),
    make_rule("Italic", "Cmd+I", "Ctrl+I", { "cmd" }, "i", "no_terminals"),
    make_rule("Underline", "Cmd+U", "Ctrl+U", { "cmd" }, "u", "no_terminals"),
    make_rule("Settings", "Cmd+,", "Ctrl+,", { "cmd" }, ",", "no_terminals"),
    make_rule("Hide app", "Cmd+H", "Ctrl+H", { "cmd" }, "h", "no_terminals"),
  }

  for tab_number = 1, 9 do
    local digit = tostring(tab_number)
    table.insert(
      rules,
      make_rule(
        "Switch to tab " .. digit,
        "Cmd+" .. digit,
        "Ctrl+" .. digit,
        { "cmd" },
        digit,
        "no_terminals"
      )
    )
  end

  return rules
end

local function is_cmd_only_or_cmd_shift(action_mods)
  local has_cmd = false
  for _, modifier in ipairs(action_mods) do
    if modifier == "cmd" then
      has_cmd = true
    elseif modifier ~= "shift" then
      return false
    end
  end
  return has_cmd
end

local function ignore_key()
  -- Intentionally empty: matching the chord and swallowing it is the whole job.
end

--- Build rules that swallow the native Cmd chords the given rules replace.
--- Only plain Cmd and Cmd+Shift chords are blocked. Terminals are always excluded
--- because they use Cmd+C, Cmd+V and friends natively, and a chord that one of the
--- rules listens for is never blocked.
function editing.build_block_rules(rules)
  local listened_to = {}
  for _, rule in ipairs(rules) do
    listened_to[keycombo.normalize(rule.to)] = true
  end

  local block_rules = {}
  local seen = {}

  for _, rule in ipairs(rules) do
    local action = rule.action
    if type(action) == "table" and is_cmd_only_or_cmd_shift(action.mods) then
      local chord = keycombo.build(action.mods, action.key)
      if not seen[chord] and not listened_to[chord] then
        seen[chord] = true
        table.insert(block_rules, {
          description = "Block native " .. chord,
          from = "none",
          to = chord,
          applications = { disable = TERMINALS },
          action = ignore_key,
          feasibility = "yes",
          note = "Only registered when block_native_cmd is true",
        })
      end
    end
  end

  return block_rules
end

editing.TERMINALS = TERMINALS
editing.BROWSERS = BROWSERS
editing.rules = make_rules()
editing.block_rules = editing.build_block_rules(editing.rules)

return editing
