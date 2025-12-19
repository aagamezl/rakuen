local function buildChoices(remaps)
  local choices = {}

  -- Now remaps is a flat table, so iterate directly
  for _, remap in ipairs(remaps) do
    if remap then
      if remap.type == "modal" then
        print("Modal: " .. remap.action)

        goto continue
      end

      local fromMods = remap.from and remap.from.mods or {}
      local fromKey = remap.from and remap.from.key or "?"
      local formatTemplate = "%s + %s"

      if fromKey == "?" then
        formatTemplate = "%s"
      end

      local fromStr
      if #fromMods > 0 then
        fromStr = string.format(formatTemplate, table.concat(fromMods, ", "), fromKey)
      else
        fromStr = fromKey
      end

      local toStr
      if remap.to and remap.to.app then
        toStr = string.format("Launch app '%s'", remap.to.app)
      elseif remap.to then
        local toMods = remap.to.mods or {}
        local toKey = remap.to.key or "?"

        if #toMods > 0 then
          toStr = string.format("%s + %s", table.concat(toMods, ", "), toKey)
        else
          toStr = toKey
        end
      else
        toStr = "?"
      end

      local formatTemplate = string.format("%s  →  %s", fromStr, toStr)
      if toStr == "?" then
        formatTemplate = string.format("%s", fromStr)
      end

      table.insert(choices, {
        text = remap.action or "(no action)",
        -- subText = string.format("%s  →  %s", fromStr, toStr),
        subText = formatTemplate,
      })
    end

    ::continue::
  end

  table.sort(choices, function(a, b) return a.text < b.text end)

  return choices
end

local function init(remaps)
  hs.hotkey.bind({ "ctrl", "cmd" }, "k", function()
    local chooser = hs.chooser.new(function(_) end)

    chooser:width(40)
    chooser:rows(15)
    chooser:placeholderText("Keybindings")
    chooser:choices(buildChoices(remaps))
    chooser:show()
  end)
end

return {
  name = "show-keybindings",
  init = init,
}
