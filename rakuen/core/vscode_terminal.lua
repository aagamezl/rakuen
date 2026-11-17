-- VS Code family editors: tell the integrated terminal from the editor (task 16.3).
--
-- The terminal is a web view inside the editor, so the bundle id alone cannot say
-- whether Ctrl+C should copy (editor) or interrupt (terminal). The focused
-- accessibility element can: xterm.js exposes its input as a text field with the
-- class "xterm-helper-textarea" and a label such as "Terminal 2, zsh ..." (checked
-- in VS Code Insiders).
--
-- Rakuen then treats the integrated terminal like any other terminal: shell chords
-- stay native, and Ctrl+Shift+C/V copy and paste.

local vscode_focus = require("rakuen.core.vscode_focus")

local vscode_terminal = {}

vscode_terminal.EDITORS = {
  "com.microsoft.VSCode",
  "com.microsoft.VSCodeInsiders",
  "com.vscodium",
  "com.todesktop.230313mzl4w4u92", -- Cursor
  "com.exafunction.windsurf",
}

local LABEL_PREFIX = "terminal"
local TERMINAL_CLASS = "xterm-helper-textarea"

--- Return true when `bundle_id` is a VS Code based editor.
function vscode_terminal.is_editor(bundle_id)
  for _, editor_id in ipairs(vscode_terminal.EDITORS) do
    if editor_id == bundle_id then
      return true
    end
  end
  return false
end

--- Return true when an AX label (title or description) names the terminal input.
function vscode_terminal.is_terminal_label(label)
  if type(label) ~= "string" then
    return false
  end
  return label:lower():sub(1, #LABEL_PREFIX) == LABEL_PREFIX
end

--- Return true when `element` (anything with `attributeValue(name)`) is the terminal input.
function vscode_terminal.is_terminal_element(element)
  if element == nil then
    return false
  end

  -- xterm.js marks its input with a class; the label is the fallback.
  local classes = element:attributeValue("AXDOMClassList")
  if type(classes) == "table" then
    for _, class_name in ipairs(classes) do
      if class_name == TERMINAL_CLASS then
        return true
      end
    end
  end

  local label = element:attributeValue("AXDescription") or element:attributeValue("AXTitle")
  return vscode_terminal.is_terminal_label(label)
end

--- Return true while the focused element of the frontmost app is the terminal input.
--- Any accessibility failure counts as "not a terminal", so the editor keeps working.
function vscode_terminal.is_focused()
  local succeeded, result = pcall(function()
    return vscode_terminal.is_terminal_element(vscode_focus.element())
  end)

  return succeeded and result == true
end

--- Gate for rules that must act as terminal rules: true in a real terminal, and in
--- a VS Code based editor only while its terminal has focus.
function vscode_terminal.when_in_terminal(bundle_id)
  if vscode_terminal.is_editor(bundle_id) then
    return vscode_terminal.is_focused()
  end
  return true
end

--- Gate for rules that must not fire in a terminal: false only while the VS Code
--- terminal has focus.
function vscode_terminal.when_outside_terminal(bundle_id)
  if vscode_terminal.is_editor(bundle_id) then
    return not vscode_terminal.is_focused()
  end
  return true
end

return vscode_terminal
