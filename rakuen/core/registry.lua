-- Registry of keybinding rules.
--
-- Modules register rules here. The binder looks rules up by chord, and the
-- docs and cheatsheet read the same data (design decision D8).
--
-- Rule shape:
--   {
--     description = "Copy",
--     from = "Cmd+C",              -- original macOS chord, for docs ("none" if absent)
--     to = "Ctrl+C",               -- chord Rakuen listens for
--     applications = { enable = {}, disable = { "com.apple.Terminal" } },
--     action = { mods = { "cmd" }, key = "c" },   -- or a function
--     feasibility = "yes",         -- yes | partial | no
--     note = "optional limitation note",
--   }

local app_filter = require("rakuen.core.app_filter")
local keycombo = require("rakuen.core.keycombo")

local registry = {}
registry.__index = registry

local VALID_FEASIBILITY = { yes = true, partial = true, no = true }

local function validate_action(action, description)
  if type(action) == "function" then
    return
  end

  assert(
    type(action) == "table",
    "rule '" .. description .. "': action must be a function or table"
  )
  assert(type(action.mods) == "table", "rule '" .. description .. "': action.mods must be a table")
  assert(type(action.key) == "string", "rule '" .. description .. "': action.key must be a string")
end

local function validate_rule(rule)
  assert(type(rule) == "table", "rule must be a table")
  assert(type(rule.description) == "string" and rule.description ~= "", "rule needs a description")

  local description = rule.description
  assert(type(rule.to) == "string", "rule '" .. description .. "': to must be a string")
  validate_action(rule.action, description)

  if rule.feasibility ~= nil then
    assert(
      VALID_FEASIBILITY[rule.feasibility],
      "rule '" .. description .. "': feasibility must be yes, partial or no"
    )
  end
end

--- Create an empty registry.
function registry.new()
  return setmetatable({ rules = {}, by_chord = {} }, registry)
end

--- Validate and add one rule for `module_name`.
--- Raises an error when the rule is malformed or claims a chord that another
--- rule already uses in an overlapping set of applications.
function registry:add(module_name, rule)
  assert(type(module_name) == "string" and module_name ~= "", "module name is required")
  validate_rule(rule)

  local chord = keycombo.normalize(rule.to)

  for _, existing in ipairs(self.by_chord[chord] or {}) do
    assert(
      not app_filter.overlaps(existing.applications, rule.applications),
      string.format(
        "rule '%s' (%s) conflicts with '%s' (%s) on %s",
        rule.description,
        module_name,
        existing.description,
        existing.module,
        chord
      )
    )
  end

  local entry = {}
  for field, value in pairs(rule) do
    entry[field] = value
  end
  entry.module = module_name
  entry.chord = chord

  table.insert(self.rules, entry)
  self.by_chord[chord] = self.by_chord[chord] or {}
  table.insert(self.by_chord[chord], entry)
end

--- Add every rule in the list for `module_name`.
function registry:add_all(module_name, rules)
  for _, rule in ipairs(rules) do
    self:add(module_name, rule)
  end
end

--- Return the rule that applies to `chord` in `bundle_id`, or nil.
function registry:find(chord, bundle_id)
  for _, rule in ipairs(self.by_chord[chord] or {}) do
    if app_filter.allows(rule.applications, bundle_id) then
      return rule
    end
  end
  return nil
end

--- Return all rules in registration order, for docs and the cheatsheet.
function registry:all()
  return self.rules
end

return registry
