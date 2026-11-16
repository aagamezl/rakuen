-- Clipboard module (task 16.1): history of copied text.
--
-- A pasteboard watcher records every text copy. `Ctrl+Alt+V` opens a chooser with
-- the history; choosing an entry puts it back on the clipboard (it does not paste,
-- so the user stays in control). The history lives in memory only: it is never
-- written to disk, because copied text can hold secrets. Reloading Hammerspoon
-- clears it. GNOME has no clipboard history by default, so the chord is Rakuen's own.

local clipboard_history = require("rakuen.core.clipboard_history")
local deferred = require("rakuen.core.deferred")
local menubar = require("rakuen.ui.menubar")

local clipboard = {}

local RULE_NAME = "Clipboard history"
local PLACEHOLDER = "Search the clipboard history"

local history = clipboard_history.new()
local watcher = nil

--- The shared history, for tests and the menu bar.
function clipboard.history()
  return history
end

--- Chooser rows for the history: { text = preview, subText = position, entry = full text }.
function clipboard.choices(entries)
  local choices = {}

  for index, entry in ipairs(entries) do
    table.insert(choices, {
      text = clipboard_history.preview(entry),
      subText = tostring(index),
      entry = entry,
    })
  end
  return choices
end

--- Put an entry back on the clipboard. The watcher then moves it to the front.
function clipboard.copy_entry(entry)
  hs.pasteboard.setContents(entry)
end

local function show_chooser()
  local entries = history:list()
  if #entries == 0 then
    hs.alert.show("Clipboard history is empty")
    return
  end

  local chooser = hs.chooser.new(function(choice)
    if choice ~= nil then
      clipboard.copy_entry(choice.entry)
    end
  end)
  chooser:placeholderText(PLACEHOLDER)
  chooser:choices(clipboard.choices(entries))
  chooser:show()
end

clipboard.rules = {
  {
    description = RULE_NAME,
    from = "none",
    to = "Ctrl+Alt+V",
    action = deferred.guard(show_chooser),
    feasibility = "yes",
    note = "Lists copied text. Choose one to put it back on the clipboard. Kept in memory only",
  },
}

local MENU_LIMIT = 10
local DELETE_TITLE = "✘  Delete"

--- One row per newest entry: choosing it copies it, and its submenu offers Copy and
--- Delete. Menu items cannot hold a button, so the delete icon sits in the submenu.
local function entry_items()
  local items = {}

  for index, entry in ipairs(history:list()) do
    table.insert(items, {
      title = clipboard_history.preview(entry),
      menu = {
        {
          title = "Copy",
          fn = function()
            clipboard.copy_entry(entry)
          end,
        },
        {
          title = DELETE_TITLE,
          fn = function()
            history:remove(entry)
          end,
        },
      },
    })
    if index >= MENU_LIMIT then
      break
    end
  end
  return items
end

local function menu_items()
  local items = entry_items()

  if #items == 0 then
    return { { title = "Clipboard history is empty", disabled = true } }
  end

  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Clear history",
    fn = function()
      history:clear()
    end,
  })
  return items
end

--- Start recording copies. Skipped when the binding is disabled in the config.
function clipboard.on_load(_, rules)
  for _, rule in ipairs(rules) do
    if rule.description == RULE_NAME then
      history:add(hs.pasteboard.getContents())

      watcher = hs.pasteboard.watcher.new(function(text)
        history:add(text)
      end)
      watcher:start()

      menubar.add_section("clipboard", function()
        return { { title = "Clipboard history", menu = menu_items() } }
      end)
      return
    end
  end
end

return clipboard
