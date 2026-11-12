-- Renders docs/keybindings.md from the registry (design decision D8).
--
-- Pure: no hs calls and no file access. scripts/generate_docs.lua feeds it the
-- registered rules and the data in scripts/docs_data.lua, then writes the file.

local docs = {}

local FEASIBILITY_LABEL = { yes = "Yes", partial = "Partial", no = "No" }
local NO_VALUE = "—"

--- Escape a table cell: a pipe would end the cell, and a newline the row.
function docs.cell(text)
  local escaped = tostring(text):gsub("|", "\\|"):gsub("\n", " ")
  return escaped
end

--- GNOME chord of `rule`: its own `gnome` field, else the data file's entry.
--- Returns nil when neither has one.
function docs.gnome_chord(rule, gnome_by_rule)
  if rule.gnome ~= nil then
    return rule.gnome
  end
  return gnome_by_rule[rule.description .. "|" .. rule.to]
end

local function table_row(cells)
  local escaped = {}
  for _, cell in ipairs(cells) do
    table.insert(escaped, docs.cell(cell))
  end
  return "| " .. table.concat(escaped, " | ") .. " |"
end

local function table_lines(rows)
  local lines = {
    "| Action | GNOME | Configured as | macOS original | Possible | Notes |",
    "| --- | --- | --- | --- | --- | --- |",
  }
  for _, row in ipairs(rows) do
    table.insert(lines, table_row(row))
  end
  return lines
end

--- Table rows { action, gnome, configured, original, possible, note } of one rule.
function docs.rule_row(rule, gnome_by_rule)
  local original = rule.from
  if original == nil or original == "" then
    original = "none"
  end

  return {
    rule.description,
    docs.gnome_chord(rule, gnome_by_rule) or NO_VALUE,
    rule.to,
    original,
    FEASIBILITY_LABEL[rule.feasibility or "yes"],
    rule.note or "",
  }
end

--- Rules without a GNOME chord, as "module: description (chord)" strings.
function docs.missing_gnome(rules, gnome_by_rule)
  local missing = {}
  for _, rule in ipairs(rules) do
    if docs.gnome_chord(rule, gnome_by_rule) == nil then
      table.insert(missing, string.format("%s: %s (%s)", rule.module, rule.description, rule.to))
    end
  end
  return missing
end

--- Module names in the order their rules were registered.
local function module_order(rules)
  local order = {}
  local seen = {}
  for _, rule in ipairs(rules) do
    if not seen[rule.module] then
      seen[rule.module] = true
      table.insert(order, rule.module)
    end
  end
  return order
end

local function section_lines(module_name, rules, data)
  local section = data.sections[module_name] or { title = module_name, extra_rows = {} }
  local rows = {}

  for _, rule in ipairs(rules) do
    if rule.module == module_name then
      table.insert(rows, docs.rule_row(rule, data.gnome))
    end
  end
  for _, row in ipairs(section.extra_rows or {}) do
    table.insert(rows, row)
  end

  local lines = { "### " .. section.title, "" }
  if section.intro ~= nil and section.intro ~= "" then
    table.insert(lines, section.intro)
    table.insert(lines, "")
  end
  for _, line in ipairs(table_lines(rows)) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  return lines
end

--- The whole docs/keybindings.md text for `rules` (registry:all()) and `data`.
function docs.render(rules, data)
  local lines = { data.header, "" }

  for _, module_name in ipairs(module_order(rules)) do
    for _, line in ipairs(section_lines(module_name, rules, data)) do
      table.insert(lines, line)
    end
  end

  table.insert(lines, "### Not configured")
  table.insert(lines, "")
  for _, line in ipairs(table_lines(data.not_configured)) do
    table.insert(lines, line)
  end
  table.insert(lines, "")

  return table.concat(lines, "\n")
end

return docs
