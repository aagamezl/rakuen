-- Text-field gate (design decision D5).
--
-- Text navigation must only act while the caret is in an editable text field.
-- Everywhere else Ctrl+Left/Right and Ctrl+Up/Down belong to Spaces and Mission Control.
--
-- Chrome, Electron apps and Slack expose no focused AX element (spike 1.7), so
-- they are listed in `force` and always count as being in a text field.

local text_gate = {}

local TEXT_ROLES = {
  AXTextField = true,
  AXTextArea = true,
  AXComboBox = true,
  AXSearchField = true,
}

--- Return true when an AX role names an editable text control.
function text_gate.is_text_role(role)
  return TEXT_ROLES[role] == true
end

--- Decide whether text navigation applies.
--- `role` is the focused element's AX role (nil when unknown), `bundle_id` the
--- frontmost app, `force` a list of bundle ids that always count as text fields.
function text_gate.allows(role, bundle_id, force)
  if bundle_id ~= nil then
    for _, forced_id in ipairs(force or {}) do
      if forced_id == bundle_id then
        return true
      end
    end
  end

  return text_gate.is_text_role(role)
end

--- Read the focused element's AX role. Returns nil when there is none or AX fails.
function text_gate.focused_role()
  local succeeded, role = pcall(function()
    local element = hs.uielement.focusedElement()
    if element == nil then
      return nil
    end
    return element:role()
  end)

  if not succeeded then
    return nil
  end
  return role
end

return text_gate
