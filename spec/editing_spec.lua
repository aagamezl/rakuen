local config = require("rakuen.core.config")
local editing = require("rakuen.modules.editing")
local keycombo = require("rakuen.core.keycombo")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

local function find_rule(rules, description)
  for _, rule in ipairs(rules) do
    if rule.description == description then
      return rule
    end
  end
  return nil
end

local function contains(list, value)
  for _, item in ipairs(list or {}) do
    if item == value then
      return true
    end
  end
  return false
end

describe("editing module", function()
  local rules

  before_each(function()
    rules = registry.new()
  end)

  it("registers without conflicts or malformed rules", function()
    assert.has_no.errors(function()
      rules:add_all("editing", editing.rules)
    end)
  end)

  it("has a unique description for every rule", function()
    local seen = {}
    for _, rule in ipairs(editing.rules) do
      assert.is_nil(seen[rule.description], "duplicate: " .. rule.description)
      seen[rule.description] = true
    end
  end)

  it("listens only for Ctrl chords, except the Finder rename key", function()
    for _, rule in ipairs(editing.rules) do
      local parsed = keycombo.parse(rule.to)
      if rule.description ~= "Rename" then
        assert.is_true(contains(parsed.modifiers, "ctrl"), rule.description)
      end
    end
  end)

  it("translates Ctrl+C, V, X, Z, A and S to the Cmd chord", function()
    rules:add_all("editing", editing.rules)

    for _, key in ipairs({ "c", "v", "x", "z", "a", "s" }) do
      local rule = rules:find("ctrl+" .. key, "com.apple.TextEdit")

      assert.is_not_nil(rule, "ctrl+" .. key)
      assert.are.same({ "cmd" }, rule.action.mods)
      assert.are.equal(key, rule.action.key)
    end
  end)

  it("leaves Ctrl+C, Z, S, W and A alone in every terminal", function()
    rules:add_all("editing", editing.rules)

    for _, terminal in ipairs(editing.TERMINALS) do
      for _, key in ipairs({ "c", "z", "s", "w", "a", "x", "v" }) do
        assert.is_nil(rules:find("ctrl+" .. key, terminal), terminal .. " ctrl+" .. key)
      end
    end
  end)

  it("copies and pastes with Ctrl+Shift+C and V in terminals only", function()
    rules:add_all("editing", editing.rules)

    for _, terminal in ipairs(editing.TERMINALS) do
      assert.are.equal("Copy in terminal", rules:find("ctrl+shift+c", terminal).description)
      assert.are.equal("Paste in terminal", rules:find("ctrl+shift+v", terminal).description)
    end
    assert.is_nil(rules:find("ctrl+shift+c", "com.apple.TextEdit"))
    assert.is_nil(rules:find("ctrl+shift+v", "com.apple.TextEdit"))
  end)

  it("maps F2 to Return in Finder only", function()
    rules:add_all("editing", editing.rules)

    local rule = rules:find("f2", "com.apple.finder")

    assert.is_not_nil(rule)
    assert.are.same({}, rule.action.mods)
    assert.are.equal("return", rule.action.key)
    assert.is_nil(rules:find("f2", "com.apple.TextEdit"))
  end)

  it("sends Redo for both Ctrl+Y and Ctrl+Shift+Z", function()
    rules:add_all("editing", editing.rules)

    for _, chord in ipairs({ "ctrl+y", "ctrl+shift+z" }) do
      local rule = rules:find(chord, "com.apple.TextEdit")
      assert.are.same({ "cmd", "shift" }, rule.action.mods)
      assert.are.equal("z", rule.action.key)
    end
  end)

  it("leaves Ctrl+Tab native in browsers and terminals", function()
    rules:add_all("editing", editing.rules)

    assert.is_nil(rules:find("ctrl+tab", "com.google.Chrome"))
    assert.is_nil(rules:find("ctrl+tab", "com.apple.Terminal"))
    assert.is_not_nil(rules:find("ctrl+tab", "com.apple.TextEdit"))
  end)

  it("covers tabs 1 to 9", function()
    rules:add_all("editing", editing.rules)

    for tab_number = 1, 9 do
      local rule = rules:find("ctrl+" .. tab_number, "com.apple.TextEdit")
      assert.are.equal(tostring(tab_number), rule.action.key)
    end
  end)

  describe("block rules", function()
    it("never block a bare key, a non-Cmd chord or a terminal", function()
      for _, rule in ipairs(editing.block_rules) do
        local parsed = keycombo.parse(rule.to)
        assert.is_true(contains(parsed.modifiers, "cmd"), rule.to)
        assert.is_false(contains(parsed.modifiers, "alt"), rule.to)
        assert.is_false(contains(parsed.modifiers, "ctrl"), rule.to)
        for _, terminal in ipairs(editing.TERMINALS) do
          assert.is_true(contains(rule.applications.disable, terminal), rule.to)
        end
      end
    end)

    it("block Cmd+C and Cmd+Shift+Z once each", function()
      assert.is_not_nil(find_rule(editing.block_rules, "Block native cmd+c"))

      local count = 0
      for _, rule in ipairs(editing.block_rules) do
        if rule.to == "cmd+shift+z" then
          count = count + 1
        end
      end
      assert.are.equal(1, count)
    end)

    it("do not block Return, which Rename sends", function()
      assert.is_nil(find_rule(editing.block_rules, "Block native return"))
    end)

    it("register alongside the main rules without conflicts", function()
      rules:add_all("editing", editing.rules)

      assert.has_no.errors(function()
        rules:add_all("editing", editing.block_rules)
      end)
      assert.is_not_nil(rules:find("cmd+c", "com.apple.TextEdit"))
      assert.is_nil(rules:find("cmd+c", "com.apple.Terminal"))
    end)
  end)

  describe("loading through the loader", function()
    local function load_with(user_config)
      local settings = config.merge(user_config)
      loader.load({
        settings = settings,
        registry = rules,
        logger = logger.new("error", function() end),
      })
    end

    it("leaves native Cmd chords alone by default (D3)", function()
      load_with({ only = "editing" })

      assert.is_not_nil(rules:find("ctrl+c", "com.apple.TextEdit"))
      assert.is_nil(rules:find("cmd+c", "com.apple.TextEdit"))
    end)

    it("blocks native Cmd chords when block_native_cmd is on", function()
      load_with({ only = "editing", block_native_cmd = true })

      assert.is_not_nil(rules:find("cmd+c", "com.apple.TextEdit"))
    end)

    it("honours a per-binding override for Copy", function()
      load_with({
        only = "editing",
        modules = {
          editing = {
            bindings = { Copy = { applications = { disable = { "com.apple.Safari" } } } },
          },
        },
      })

      assert.is_nil(rules:find("ctrl+c", "com.apple.Safari"))
      assert.is_not_nil(rules:find("ctrl+c", "com.apple.TextEdit"))
    end)
  end)
end)
