-- Focused accessibility element of the frontmost app, for VS Code based editors.
--
-- Electron builds its accessibility tree only when asked (or when a screen reader
-- runs). Asking once per process is enough.

local vscode_focus = {}

local enabled_pids = {}

local function enable_accessibility(app)
  local pid = app:pid()
  if enabled_pids[pid] then
    return
  end

  enabled_pids[pid] = true
  hs.axuielement.applicationElement(app):setAttributeValue("AXManualAccessibility", true)
end

--- The focused element of the frontmost app, or nil. Can raise; callers use pcall.
function vscode_focus.element()
  local app = hs.application.frontmostApplication()
  if app == nil then
    return nil
  end

  enable_accessibility(app)
  return hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
end

return vscode_focus
