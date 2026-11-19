-- VS Code family editors: tell the file explorer from the rest (task 16.5).
--
-- Seen with bin/ax-watch in VS Code Insiders: a focused explorer row is an
-- AXOutlineRow with the class "monaco-list-row", and its AXOutline ancestor is
-- described as "Files Explorer". In the explorer, Return renames (like Finder), so
-- F2 can send Return there; elsewhere F2 stays native (rename symbol).

local vscode_explorer = {}

local ROW_CLASS = "monaco-list-row"
local OUTLINE_DESCRIPTION = "Files Explorer"
local MAX_ANCESTORS = 4

local vscode_terminal = require("rakuen.core.vscode_terminal")
local vscode_focus = require("rakuen.core.vscode_focus")

local function has_class(element, class_name)
  local classes = element:attributeValue("AXDOMClassList")
  if type(classes) ~= "table" then
    return false
  end

  for _, name in ipairs(classes) do
    if name == class_name then
      return true
    end
  end
  return false
end

--- Return true when `element` (anything with `attributeValue(name)`) is a row of the
--- Files Explorer tree.
function vscode_explorer.is_explorer_row(element)
  if element == nil or not has_class(element, ROW_CLASS) then
    return false
  end

  local ancestor = element:attributeValue("AXParent")
  for _ = 1, MAX_ANCESTORS do
    if ancestor == nil then
      return false
    end
    if ancestor:attributeValue("AXDescription") == OUTLINE_DESCRIPTION then
      return true
    end
    ancestor = ancestor:attributeValue("AXParent")
  end
  return false
end

--- Return true while the focused element is a Files Explorer row. Any accessibility
--- failure counts as "not the explorer".
function vscode_explorer.is_focused()
  local succeeded, result = pcall(function()
    return vscode_explorer.is_explorer_row(vscode_focus.element())
  end)

  return succeeded and result == true
end

--- Gate for the F2 rename rule: true in every app except VS Code based editors, where
--- it is true only while the Files Explorer has focus.
function vscode_explorer.when_rename_applies(bundle_id)
  if vscode_terminal.is_editor(bundle_id) then
    return vscode_explorer.is_focused()
  end
  return true
end

return vscode_explorer
