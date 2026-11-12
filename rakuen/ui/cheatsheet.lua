-- Cheatsheet window: every rule the binder registered, grouped by module.
--
-- The rows come from the registry only (design decision D8), so the window can
-- never drift from what is bound. `rows`, `group` and `html` are pure. `toggle`
-- opens an hs.webview with the page. The page has a search box, follows the
-- system light or dark theme, and closes with Escape.

local cheatsheet = {}

local WINDOW_WIDTH = 920
local WINDOW_HEIGHT = 660
local MESSAGE_HANDLER = "rakuen"
local NO_ORIGINAL = "none"
local FEASIBILITY_PREFIX = {
  partial = "Partial: ",
  no = "Not available: ",
}

local PAGE_STYLE = [[
:root { color-scheme: light dark; --bg: #ffffff; --fg: #1d1d1f; --muted: #6e6e73;
  --line: #d2d2d7; --head: #f5f5f7; --key: #e8e8ed; --accent: #0a60d0; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #1e1e1e; --fg: #f5f5f7; --muted: #a1a1a6; --line: #3a3a3c;
    --head: #2a2a2c; --key: #3a3a3c; --accent: #5aa2ff; }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg);
  font: 13px -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif; }
header { position: sticky; top: 0; z-index: 2; background: var(--bg);
  padding: 14px 20px 10px; border-bottom: 1px solid var(--line); }
h1 { margin: 0 0 8px; font-size: 16px; }
input { width: 100%; padding: 8px 10px; font-size: 14px; color: var(--fg);
  background: var(--head); border: 1px solid var(--line); border-radius: 6px; }
input:focus { outline: 2px solid var(--accent); border-color: transparent; }
main { padding: 4px 20px 24px; }
h2 { margin: 22px 0 6px; font-size: 13px; text-transform: uppercase;
  letter-spacing: .06em; color: var(--muted); }
table { width: 100%; border-collapse: collapse; table-layout: fixed; }
th { text-align: left; padding: 6px 8px; font-weight: 600; color: var(--muted);
  background: var(--head); }
td { padding: 6px 8px; border-top: 1px solid var(--line); vertical-align: top;
  overflow-wrap: anywhere; }
col.chord { width: 20%; } col.desc { width: 60%; }
kbd { font: 12px ui-monospace, Menlo, monospace; background: var(--key);
  padding: 2px 6px; border-radius: 4px; white-space: nowrap; }
.muted { color: var(--muted); }
.empty { padding: 24px 0; color: var(--muted); }
[hidden] { display: none !important; }
]]

local PAGE_SCRIPT = [[
var input = document.getElementById("filter");
var groups = document.querySelectorAll("section");
var empty = document.getElementById("empty");
function apply() {
  var query = input.value.trim().toLowerCase();
  var shown = 0;
  groups.forEach(function (group) {
    var visible = 0;
    group.querySelectorAll("tbody tr").forEach(function (row) {
      var match = query === "" || row.textContent.toLowerCase().indexOf(query) !== -1;
      row.hidden = !match;
      if (match) { visible += 1; }
    });
    group.hidden = visible === 0;
    shown += visible;
  });
  empty.hidden = shown !== 0;
}
input.addEventListener("input", apply);
document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    window.webkit.messageHandlers.rakuen.postMessage("close");
  }
});
input.focus();
]]

--- Escape text for HTML.
function cheatsheet.escape_html(text)
  local replacements = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }

  return (tostring(text):gsub('[&<>"]', replacements))
end

--- "text_navigation" -> "Text navigation".
function cheatsheet.module_title(module_name)
  local spaced = module_name:gsub("_", " ")

  return spaced:sub(1, 1):upper() .. spaced:sub(2)
end

--- Description column: the rule's note, with partial and no rules flagged.
function cheatsheet.describe(rule)
  local prefix = FEASIBILITY_PREFIX[rule.feasibility] or ""
  local note = rule.note

  if note == nil or note == "" then
    return prefix .. rule.description
  end

  return prefix .. rule.description .. ". " .. note
end

--- One row per rule: { module, name, new, original, description }.
function cheatsheet.rows(rules)
  local rows = {}

  for _, rule in ipairs(rules) do
    local original = rule.from

    if original == nil or original == "" then
      original = NO_ORIGINAL
    end

    table.insert(rows, {
      module = rule.module or "other",
      name = rule.description,
      new = rule.to,
      original = original,
      description = cheatsheet.describe(rule),
    })
  end

  return rows
end

--- Group rows by module, keeping the order in which modules first appear.
--- Returns a list of { module, title, rows }.
function cheatsheet.group(rows)
  local groups = {}
  local by_module = {}

  for _, row in ipairs(rows) do
    local group = by_module[row.module]

    if group == nil then
      group = { module = row.module, title = cheatsheet.module_title(row.module), rows = {} }
      by_module[row.module] = group
      table.insert(groups, group)
    end

    table.insert(group.rows, row)
  end

  return groups
end

local function chord_cell(chord)
  if chord == NO_ORIGINAL then
    return '<span class="muted">none</span>'
  end

  return "<kbd>" .. cheatsheet.escape_html(chord) .. "</kbd>"
end

local function group_html(group)
  local parts = {
    "<section><h2>" .. cheatsheet.escape_html(group.title) .. "</h2><table>",
    '<colgroup><col class="chord"><col class="chord"><col class="desc"></colgroup>',
    "<thead><tr><th>New</th><th>Original</th><th>Description</th></tr></thead><tbody>",
  }

  for _, row in ipairs(group.rows) do
    table.insert(
      parts,
      string.format(
        "<tr><td>%s</td><td>%s</td><td>%s</td></tr>",
        chord_cell(row.new),
        chord_cell(row.original),
        cheatsheet.escape_html(row.description)
      )
    )
  end

  table.insert(parts, "</tbody></table></section>")

  return table.concat(parts)
end

--- The full page for `groups` (from `group`).
function cheatsheet.html(groups)
  local body = {}

  for _, group in ipairs(groups) do
    table.insert(body, group_html(group))
  end

  return table.concat({
    '<!doctype html><html><head><meta charset="utf-8"><title>Rakuen keybindings</title>',
    "<style>",
    PAGE_STYLE,
    "</style></head><body>",
    '<header><h1>Rakuen keybindings</h1><input id="filter" type="search" ',
    'placeholder="Filter by shortcut or description" autocomplete="off"></header>',
    "<main>",
    table.concat(body),
    '<p id="empty" class="empty" hidden>No shortcut matches.</p>',
    "</main><script>",
    PAGE_SCRIPT,
    "</script></body></html>",
  })
end

-- Kept at module level so the window is not garbage collected while open.
local state = { window = nil, controller = nil }

local function close_window()
  if state.window ~= nil then
    state.window:delete()
  end

  state.window = nil
  state.controller = nil
end

local function window_frame()
  local area = hs.screen.mainScreen():frame()

  return {
    x = area.x + (area.w - WINDOW_WIDTH) / 2,
    y = area.y + (area.h - WINDOW_HEIGHT) / 2,
    w = WINDOW_WIDTH,
    h = WINDOW_HEIGHT,
  }
end

--- True while the window is on screen.
function cheatsheet.is_open()
  return state.window ~= nil
end

--- Open the window for the rules in `registry`, or close it when it is open.
function cheatsheet.toggle(registry)
  assert(registry ~= nil, "registry is required")

  if cheatsheet.is_open() then
    close_window()
    return
  end

  local page = cheatsheet.html(cheatsheet.group(cheatsheet.rows(registry:all())))

  state.controller = hs.webview.usercontent.new(MESSAGE_HANDLER)
  state.controller:setCallback(function()
    close_window()
  end)

  state.window = hs.webview.new(window_frame(), {}, state.controller)
  state.window:windowStyle({ "titled", "closable", "resizable", "utility" })
  state.window:allowTextEntry(true)
  state.window:level(hs.drawing.windowLevels.floating)
  state.window:windowTitle("Rakuen keybindings")
  state.window:windowCallback(function(action)
    if action == "closing" then
      state.window = nil
      state.controller = nil
    end
  end)

  state.window:html(page)
  state.window:show()
  state.window:hswindow():focus()
end

return cheatsheet
