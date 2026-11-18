-- Builds the rule tables that modules hand to the registry and the docs generator.

local rule = {}

--- Build a rule. `feasibility` defaults to "yes"; `applications` is optional.
function rule.new(description, from, to, action, feasibility, note, applications)
  return {
    description = description,
    from = from,
    to = to,
    action = action,
    feasibility = feasibility or "yes",
    note = note,
    applications = applications,
  }
end

return rule
