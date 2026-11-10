local keycombo = require("rakuen.core.keycombo")
local registry = require("rakuen.core.registry")
local text_navigation = require("rakuen.modules.text_navigation")

local function find_by_chord(rules, chord)
  local normalized = keycombo.normalize(chord)
  for _, rule in ipairs(rules) do
    if keycombo.normalize(rule.to) == normalized then
      return rule
    end
  end
  return nil
end

describe("text_navigation module", function()
  it("registers without conflicts or malformed rules", function()
    local rules = registry.new()
    assert.has_no.errors(function()
      rules:add_all("text_navigation", text_navigation.rules)
    end)
  end)

  it("has a unique description for every rule", function()
    local seen = {}
    for _, rule in ipairs(text_navigation.rules) do
      assert.is_nil(seen[rule.description], "duplicate: " .. rule.description)
      seen[rule.description] = true
    end
  end)

  it("covers every Linux caret chord", function()
    local chords = {
      "Home",
      "End",
      "Shift+Home",
      "Shift+End",
      "Ctrl+Home",
      "Ctrl+End",
      "Ctrl+Shift+Home",
      "Ctrl+Shift+End",
      "Ctrl+Left",
      "Ctrl+Right",
      "Ctrl+Shift+Left",
      "Ctrl+Shift+Right",
      "Ctrl+Up",
      "Ctrl+Down",
      "Ctrl+Shift+Up",
      "Ctrl+Shift+Down",
      "Ctrl+Backspace",
      "Ctrl+Del",
    }
    for _, chord in ipairs(chords) do
      assert.is_not_nil(find_by_chord(text_navigation.rules, chord), chord)
    end
    assert.equals(#chords, #text_navigation.rules)
  end)

  it("translates Home and Ctrl+Home to the macOS caret chords", function()
    local home = find_by_chord(text_navigation.rules, "Home")
    assert.same({ "cmd" }, home.action.mods)
    assert.equals("left", home.action.key)

    local document_start = find_by_chord(text_navigation.rules, "Ctrl+Home")
    assert.same({ "cmd" }, document_start.action.mods)
    assert.equals("up", document_start.action.key)
  end)

  it("deletes words with Option+Delete and Option+Forward Delete", function()
    local back = find_by_chord(text_navigation.rules, "Ctrl+Backspace")
    assert.equals("delete", back.action.key)

    local forward = find_by_chord(text_navigation.rules, "Ctrl+Del")
    assert.equals("forwarddelete", forward.action.key)
  end)

  it("is disabled in terminals", function()
    local rules = registry.new()
    rules:add_all("text_navigation", text_navigation.rules)
    for _, bundle_id in ipairs(text_navigation.terminals) do
      assert.is_nil(rules:find("ctrl+left", bundle_id))
    end
  end)

  it("lists Chrome, VS Code and Slack as forced apps", function()
    local forced = {}
    for _, bundle_id in ipairs(text_navigation.force) do
      forced[bundle_id] = true
    end
    assert.is_true(forced["com.google.Chrome"])
    assert.is_true(forced["com.microsoft.VSCode"])
    assert.is_true(forced["com.tinyspeck.slackmacgap"])
  end)

  it("does not consume keys while the gate is closed", function()
    local rules = registry.new()
    rules:add_all("text_navigation", {
      {
        description = "Gated",
        to = "Ctrl+Left",
        action = { mods = { "alt" }, key = "left" },
        when = function()
          return false
        end,
      },
    })
    assert.is_nil(rules:find("ctrl+left", "com.apple.Finder"))
  end)
end)
