local registry = require("rakuen.core.registry")

local function make_rule(overrides)
  local rule = {
    description = "Copy",
    from = "Cmd+C",
    to = "Ctrl+C",
    action = { mods = { "cmd" }, key = "c" },
    feasibility = "yes",
  }
  for field, value in pairs(overrides or {}) do
    rule[field] = value
  end
  return rule
end

describe("registry", function()
  local rules

  before_each(function()
    rules = registry.new()
  end)

  it("finds a rule by normalized chord", function()
    rules:add("editing", make_rule())

    local found = rules:find("ctrl+c", "com.apple.TextEdit")

    assert.are.equal("Copy", found.description)
    assert.are.equal("editing", found.module)
  end)

  it("respects application filters when finding", function()
    rules:add("editing", make_rule({ applications = { disable = { "com.apple.Terminal" } } }))

    assert.is_nil(rules:find("ctrl+c", "com.apple.Terminal"))
    assert.is_not_nil(rules:find("ctrl+c", "com.apple.Safari"))
  end)

  it("allows the same chord in disjoint applications", function()
    rules:add("editing", make_rule({ applications = { enable = { "a" } } }))
    rules:add(
      "terminal",
      make_rule({ description = "Terminal copy", applications = { enable = { "b" } } })
    )

    assert.are.equal("Copy", rules:find("ctrl+c", "a").description)
    assert.are.equal("Terminal copy", rules:find("ctrl+c", "b").description)
  end)

  it("rejects conflicting chords", function()
    rules:add("editing", make_rule())

    assert.has_error(function()
      rules:add("other", make_rule({ description = "Other", to = "Control+C" }))
    end)
  end)

  it("accepts function actions", function()
    rules:add("shell", make_rule({ action = function() end }))
    assert.are.equal(1, #rules:all())
  end)

  it("rejects malformed rules", function()
    assert.has_error(function()
      rules:add("editing", make_rule({ description = "" }))
    end)
    assert.has_error(function()
      rules:add("editing", make_rule({ to = "Hyper+C" }))
    end)
    assert.has_error(function()
      rules:add("editing", make_rule({ action = "cmd+c" }))
    end)
    assert.has_error(function()
      rules:add("editing", make_rule({ feasibility = "maybe" }))
    end)
  end)

  it("applies a rule only while its when function returns true", function()
    local open = false
    rules:add(
      "editing",
      make_rule({
        when = function()
          return open
        end,
      })
    )

    assert.is_nil(rules:find("ctrl+c", "com.apple.TextEdit"))
    open = true
    assert.is_not_nil(rules:find("ctrl+c", "com.apple.TextEdit"))
  end)

  it("rejects a when that is not a function", function()
    assert.has_error(function()
      rules:add("editing", make_rule({ when = true }))
    end)
  end)

  it("returns rules in registration order", function()
    rules:add_all("editing", {
      make_rule(),
      make_rule({ description = "Paste", to = "Ctrl+V" }),
    })

    assert.are.equal("Copy", rules:all()[1].description)
    assert.are.equal("Paste", rules:all()[2].description)
  end)
end)
