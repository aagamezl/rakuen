--- Build one keybinding rule.
--- enable = {} means every application. disable always wins over enable.
--- @param fields table
--- @return table
local function rule(fields)
  return {
    description = fields.description,
    gnome = fields.gnome,
    original = fields.original or "none",
    mods = fields.mods or {},
    key = fields.key,
    applications = {
      enable = (fields.applications and fields.applications.enable) or {},
      disable = (fields.applications and fields.applications.disable) or {},
    },
    action = fields.action,
    whenText = fields.whenText or false,
    note = fields.note,
  }
end

return rule
