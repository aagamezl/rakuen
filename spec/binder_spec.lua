local binder = require("rakuen.core.binder")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")
local synthetic = require("rakuen.core.synthetic")

describe("binder", function()
  local rules
  local log_lines
  local ran

  local function make_binder(mode)
    return binder.new({
      registry = rules,
      logger = logger.new("debug", function(line)
        table.insert(log_lines, line)
      end),
      mode = mode,
      run_action = function(rule)
        table.insert(ran, rule.description)
      end,
    })
  end

  before_each(function()
    rules = registry.new()
    rules:add("editing", {
      description = "Copy",
      to = "Ctrl+C",
      applications = { disable = { "com.apple.Terminal" } },
      action = { mods = { "cmd" }, key = "c" },
    })
    log_lines = {}
    ran = {}
  end)

  describe("log mode", function()
    it("logs the key and never swallows or runs anything", function()
      local swallowed = make_binder("log"):handle_chord("ctrl+c", "com.apple.Safari", 0)

      assert.is_false(swallowed)
      assert.are.same({}, ran)
      assert.are.equal(1, #log_lines)
    end)
  end)

  describe("match mode", function()
    it("runs the rule and swallows the key", function()
      local swallowed = make_binder("match"):handle_chord("ctrl+c", "com.apple.Safari", 0)

      assert.is_true(swallowed)
      assert.are.same({ "Copy" }, ran)
    end)

    it("passes unmatched keys through", function()
      local swallowed = make_binder("match"):handle_chord("ctrl+x", "com.apple.Safari", 0)

      assert.is_false(swallowed)
      assert.are.same({}, ran)
    end)

    it("passes the key through in a disabled application", function()
      local swallowed = make_binder("match"):handle_chord("ctrl+c", "com.apple.Terminal", 0)

      assert.is_false(swallowed)
      assert.are.same({}, ran)
    end)

    it("ignores events carrying the Rakuen marker", function()
      local swallowed =
        make_binder("match"):handle_chord("ctrl+c", "com.apple.Safari", synthetic.MARKER)

      assert.is_false(swallowed)
      assert.are.same({}, ran)
    end)

    it("does nothing while paused", function()
      local instance = make_binder("match")
      instance.paused = true

      assert.is_false(instance:handle_chord("ctrl+c", "com.apple.Safari", 0))
      assert.are.same({}, ran)
    end)
  end)

  it("rejects an unknown mode", function()
    assert.has_error(function()
      make_binder("loud")
    end)
  end)
end)
