-- Builds the rule tables that modules hand to the registry and the docs generator.

local rule = {}

--- Build a rule. `note` and `applications` are optional.
function rule.new(description, from, to, action, note, applications)
  return {
    description = description,
    from = from,
    to = to,
    action = action,
    note = note,
    applications = applications,
  }
end

return rule
