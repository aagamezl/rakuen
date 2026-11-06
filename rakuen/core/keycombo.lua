-- Parse and normalize key chords such as "Ctrl+Shift+Tab".
--
-- A normalized chord is a lowercase string with modifiers in a fixed order,
-- for example "ctrl+shift+tab". It matches the chord Rakuen builds from an
-- event, so rules and events can be compared with plain string equality.
-- The fn flag is not part of a chord: macOS sets it on arrow and Home/End keys.

local keycombo = {}

local MODIFIER_ORDER = { "ctrl", "alt", "cmd", "shift" }

local MODIFIER_ALIASES = {
  ctrl = "ctrl",
  control = "ctrl",
  alt = "alt",
  opt = "alt",
  option = "alt",
  cmd = "cmd",
  command = "cmd",
  super = "cmd",
  meta = "cmd",
  shift = "shift",
}

local KEY_ALIASES = {
  grave = "`",
  esc = "escape",
  enter = "return",
  backspace = "delete",
  del = "forwarddelete",
  page_up = "pageup",
  page_down = "pagedown",
  pgup = "pageup",
  pgdn = "pagedown",
  spacebar = "space",
}

local function is_modifier_name(name)
  return MODIFIER_ALIASES[name] ~= nil
end

local function split_on_plus(text)
  local parts = {}
  local start = 1

  while true do
    -- A "+" at the very end, or right after another "+", is the key itself.
    local plus = text:find("+", start, true)
    if plus == nil or plus == #text then
      table.insert(parts, text:sub(start))
      break
    end
    table.insert(parts, text:sub(start, plus - 1))
    start = plus + 1
  end

  return parts
end

local function sort_modifiers(modifier_set)
  local ordered = {}
  for _, modifier in ipairs(MODIFIER_ORDER) do
    if modifier_set[modifier] then
      table.insert(ordered, modifier)
    end
  end
  return ordered
end

--- Join modifiers and a key into a normalized chord string.
--- `modifiers` is a list of canonical modifier names; `key` is already lowercase.
function keycombo.build(modifiers, key)
  local modifier_set = {}
  for _, modifier in ipairs(modifiers) do
    modifier_set[modifier] = true
  end

  local parts = sort_modifiers(modifier_set)
  table.insert(parts, key)
  return table.concat(parts, "+")
end

--- Parse "Ctrl+Shift+Tab" into { modifiers = { "ctrl", "shift" }, key = "tab" }.
--- Raises an error for an empty chord, an unknown modifier, or a missing key.
function keycombo.parse(text)
  assert(type(text) == "string" and text ~= "", "chord must be a non-empty string")

  local parts = split_on_plus(text)
  local key_part = table.remove(parts)
  assert(key_part ~= nil and key_part ~= "", "chord has no key: " .. text)

  local modifier_set = {}
  for _, part in ipairs(parts) do
    local canonical = MODIFIER_ALIASES[part:lower()]
    assert(canonical ~= nil, "unknown modifier '" .. part .. "' in chord: " .. text)
    modifier_set[canonical] = true
  end

  local key = key_part:lower()
  if KEY_ALIASES[key] ~= nil then
    key = KEY_ALIASES[key]
  end
  assert(not is_modifier_name(key), "chord has no key: " .. text)

  return { modifiers = sort_modifiers(modifier_set), key = key }
end

--- Normalize a chord string: "Opt+Shift+Tab" becomes "alt+shift+tab".
function keycombo.normalize(text)
  local parsed = keycombo.parse(text)
  return keycombo.build(parsed.modifiers, parsed.key)
end

--- Build a normalized chord from event data.
--- `flags` is a table like { ctrl = true, fn = true }; `key_name` is the key's name.
function keycombo.from_event(flags, key_name)
  local modifiers = {}
  for _, modifier in ipairs(MODIFIER_ORDER) do
    if flags[modifier] then
      table.insert(modifiers, modifier)
    end
  end
  return keycombo.build(modifiers, key_name)
end

return keycombo
