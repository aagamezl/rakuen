-- True when the focused accessibility element is an editable text control.
-- Chrome and many Electron apps do not expose that role, so this returns false there.

local TEXT_ROLES = {
  AXTextField = true,
  AXTextArea = true,
  AXComboBox = true,
  AXSearchField = true,
}

local CONTAINER_ROLES = {
  AXScrollArea = true,
  AXGroup = true,
  AXSplitGroup = true,
  AXWebArea = true,
  AXList = true,
}

local cache = {
  at = 0,
  value = false,
}

local function attribute(element, name)
  local ok, value = pcall(function()
    return element:attributeValue(name)
  end)

  if ok then
    return value
  end
end

local function looksEditable(element)
  if not element then
    return false
  end

  if TEXT_ROLES[attribute(element, "AXRole")] then
    return true
  end

  local range = attribute(element, "AXSelectedTextRange")

  if type(range) == "table" then
    return true
  end

  return type(attribute(element, "AXNumberOfCharacters")) == "number"
end

local function focusedElement()
  if hs.uielement and hs.uielement.focusedElement then
    local ok, element = pcall(hs.uielement.focusedElement)

    if ok and element then
      return element
    end
  end

  local ok, element = pcall(function()
    return hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  end)

  if ok then
    return element
  end
end

local function fromElement(element)
  if not element then
    return false
  end

  if CONTAINER_ROLES[attribute(element, "AXRole")] then
    local children = attribute(element, "AXChildren")

    if type(children) == "table" then
      for index, child in ipairs(children) do
        if index > 8 then
          break
        end

        if looksEditable(child) then
          return true
        end
      end
    end
  end

  local current = element

  for _ = 1, 8 do
    if looksEditable(current) then
      return true
    end

    current = attribute(current, "AXParent")

    if not current then
      return false
    end
  end

  return false
end

local function isEditableTextFocused()
  local now = hs.timer.secondsSinceEpoch()

  if now - cache.at < 0.08 then
    return cache.value
  end

  cache.at = now
  cache.value = fromElement(focusedElement())

  return cache.value
end

return {
  isEditableTextFocused = isEditableTextFocused,
}
