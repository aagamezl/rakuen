-- Scrollable window of every binding the binder registered.

local binder = require("core.binder")

local view = nil

local function escapeHtml(value)
  return tostring(value or "")
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
end

local function rowDescription(rule)
  local text = rule.description or ""

  if rule.note and rule.note ~= "" then
    text = text .. ". " .. rule.note
  end

  return text
end

local function buildHtml(rules)
  local sections = {}
  local order = {}

  for _, rule in ipairs(rules) do
    local name = rule.section or "Other"

    if not sections[name] then
      sections[name] = {}
      table.insert(order, name)
    end

    table.insert(sections[name], rule)
  end

  local body = {}

  for _, name in ipairs(order) do
    table.insert(body, "<h2>" .. escapeHtml(name) .. "</h2>")
    table.insert(body, "<table><thead><tr><th>Description</th><th>New keybinding</th><th>Original keybinding</th></tr></thead><tbody>")

    for _, rule in ipairs(sections[name]) do
      table.insert(body, "<tr><td>" .. escapeHtml(rowDescription(rule)) .. "</td><td><kbd>" .. escapeHtml(rule.configured or "") .. "</kbd></td><td><kbd>" .. escapeHtml(rule.original or "none") .. "</kbd></td></tr>")
    end

    table.insert(body, "</tbody></table>")
  end

  return [[
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font: 14px/1.4 -apple-system, sans-serif; margin: 0; color: #1d1d1f; background: #f5f5f7; }
          header { position: sticky; top: 0; background: #1d1d1f; color: white; padding: 16px 24px; }
          main { padding: 8px 24px 32px; }
          h2 { margin: 24px 0 8px; font-size: 16px; }
          table { width: 100%; border-collapse: collapse; background: white; }
          th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #e5e5ea; vertical-align: top; }
          th { font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: #6e6e73; }
          kbd { font-family: ui-monospace, Menlo, monospace; }
        </style>
      </head>
      <body>
        <header><strong>Rakuen keybindings</strong></header>
        <main>]] .. table.concat(body) .. [[</main>
      </body>
    </html>
  ]]
end

local function hide()
  if view then
    view:delete()
    view = nil
  end
end

local function show(rules)
  hide()

  local screen = hs.screen.mainScreen():frame()
  local width = math.min(980, screen.w - 80)
  local height = math.min(720, screen.h - 80)
  local frame = hs.geometry.rect(
    screen.x + (screen.w - width) / 2,
    screen.y + (screen.h - height) / 2,
    width,
    height
  )

  view = hs.webview.new(frame)
  view:windowTitle("Rakuen keybindings")
  view:windowStyle({ "titled", "closable", "resizable", "utility" })
  if hs.canvas and hs.canvas.windowLevels then
    view:level(hs.canvas.windowLevels.floating)
  end
  view:html(buildHtml(rules))
  view:show()
end

local function toggle(rules)
  if view then
    hide()
  else
    show(rules)
  end
end

return {
  name = "Cheatsheet",
  rules = {},
  toggle = toggle,
  attach = function(self)
    self.rules = {
      {
        description = "Show keybindings",
        gnome = "—",
        original = "none",
        mods = { "ctrl", "alt" },
        key = "/",
        applications = { enable = {}, disable = {} },
        action = function()
          toggle(binder.rules())
        end,
        whenText = false,
        note = "Lists the new binding, the original macOS binding, and a description",
      },
    }
  end,
}
