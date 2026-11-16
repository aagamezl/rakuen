-- The one Rakuen menu bar item (task 16.2), shared by every module.
--
-- Modules add sections with `add_section(id, builder)`; a builder returns a list of
-- hs.menubar menu items and runs each time the menu opens, so it shows live state.
-- `configure` supplies the core entries (cheatsheet, module switches) from init.lua.
-- The item is titled "楽" (Rakuen). The caffeine cup (15.7) adds its icon beside it
-- through `set_appearance`.

local menubar = {}

local DEFAULT_TITLE = "楽"
local DEFAULT_TOOLTIP = "Rakuen"
local SEPARATOR = { title = "-" }

local state = {
  item = nil,
  sections = {},
  order = {},
  options = {},
  appearance = { tooltip = DEFAULT_TOOLTIP },
}

--- Join groups of menu items, with a separator between non-empty groups. Pure.
function menubar.join(groups)
  local menu = {}

  for _, group in ipairs(groups) do
    if #group > 0 then
      if #menu > 0 then
        table.insert(menu, SEPARATOR)
      end
      for _, entry in ipairs(group) do
        table.insert(menu, entry)
      end
    end
  end
  return menu
end

--- Menu items that switch modules. `enabled` maps name to boolean, `on_toggle(name,
--- new_value)` runs on a click. Pure.
function menubar.module_items(names, enabled, on_toggle)
  local items = {}

  for _, name in ipairs(names) do
    local current = enabled[name] == true
    table.insert(items, {
      title = name:gsub("_", " "),
      checked = current,
      fn = function()
        on_toggle(name, not current)
      end,
    })
  end
  return items
end

--- Register or replace a section owned by a module.
function menubar.add_section(id, builder)
  assert(type(builder) == "function", "builder must be a function")

  if state.sections[id] == nil then
    table.insert(state.order, id)
  end
  state.sections[id] = builder
  menubar.ensure()
end

--- Core entries: { on_cheatsheet = fn, module_names = {}, module_enabled = fn -> table,
--- on_module_toggle = fn(name, value) }.
function menubar.configure(options)
  state.options = options
  menubar.ensure()
end

--- Menu for the current state. Runs when the menu opens.
function menubar.build_menu()
  local groups = {}

  for _, id in ipairs(state.order) do
    local succeeded, items = pcall(state.sections[id])
    if succeeded and type(items) == "table" then
      table.insert(groups, items)
    end
  end

  local options = state.options
  local core = {}
  if options.on_cheatsheet ~= nil then
    table.insert(core, { title = "Show keybindings", fn = options.on_cheatsheet })
  end
  if options.on_module_toggle ~= nil then
    table.insert(core, {
      title = "Modules",
      menu = menubar.module_items(
        options.module_names,
        options.module_enabled(),
        options.on_module_toggle
      ),
    })
  end
  table.insert(groups, core)

  return menubar.join(groups)
end

local function paint()
  local item = state.item
  if item == nil then
    return
  end

  -- The title always names Rakuen; a module may add an icon beside it.
  local appearance = state.appearance
  item:setIcon(appearance.image, false)
  item:setTitle(DEFAULT_TITLE)
  item:setTooltip(appearance.tooltip)
end

--- Create the item on first use.
function menubar.ensure()
  if state.item ~= nil then
    return state.item
  end

  state.item = hs.menubar.new()
  state.item:setMenu(menubar.build_menu)
  paint()
  return state.item
end

--- Set the icon shown beside the Rakuen title (an hs.image or nil) and the tooltip.
function menubar.set_appearance(image, tooltip)
  state.appearance = {
    image = image,
    tooltip = tooltip or DEFAULT_TOOLTIP,
  }
  menubar.ensure()
  paint()
end

--- Remove the item and every section. For tests.
function menubar.reset()
  if state.item ~= nil then
    state.item:delete()
  end
  state.item = nil
  state.sections = {}
  state.order = {}
  state.options = {}
  state.appearance = { tooltip = DEFAULT_TOOLTIP }
end

return menubar
