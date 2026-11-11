local config = require("rakuen.core.config")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

describe("loader", function()
  local rules
  local warnings
  local test_logger
  local requested

  local fake_modules = {
    ["rakuen.modules.editing"] = {
      rules = {
        { description = "Copy", to = "Ctrl+C", action = { mods = { "cmd" }, key = "c" } },
      },
    },
    ["rakuen.modules.windows"] = {
      rules = {
        { description = "Close", to = "Opt+F4", action = { mods = { "cmd" }, key = "w" } },
      },
    },
  }

  local function fake_require(name)
    table.insert(requested, name)
    return fake_modules[name] or { rules = {} }
  end

  local function load_with(user_config)
    return loader.load({
      settings = config.merge(user_config),
      registry = rules,
      logger = test_logger,
      require_module = fake_require,
    })
  end

  before_each(function()
    rules = registry.new()
    warnings = {}
    requested = {}
    test_logger = logger.new("warn", function(line)
      table.insert(warnings, line)
    end)
  end)

  it("loads nothing with the default config", function()
    local loaded = load_with({})

    assert.are.same({}, loaded)
    assert.are.same({}, requested)
  end)

  it("loads only enabled modules", function()
    local loaded = load_with({ modules = { editing = { enabled = true } } })

    assert.are.same({ "editing" }, loaded)
    assert.are.equal(1, #rules:all())
    assert.are.equal("Copy", rules:all()[1].description)
  end)

  it("loads a single module alone with only", function()
    local loaded = load_with({
      only = "windows",
      modules = { editing = { enabled = true } },
    })

    assert.are.same({ "windows" }, loaded)
    assert.are.same({ "rakuen.modules.windows" }, requested)
  end)

  it("applies binding overrides before registering", function()
    load_with({
      modules = {
        editing = { enabled = true, bindings = { Copy = { enabled = false } } },
      },
    })

    assert.are.equal(0, #rules:all())
  end)

  it("warns about bindings that match no rule", function()
    load_with({
      modules = {
        editing = { enabled = true, bindings = { Cpoy = { enabled = false } } },
      },
    })

    assert.are.equal(1, #warnings)
    assert.is_truthy(warnings[1]:find("Cpoy", 1, true))
  end)

  it("loads every real module file with the default shape", function()
    local settings = config.merge({})
    for _, name in ipairs(config.MODULE_NAMES) do
      settings.modules[name].enabled = true
    end

    local loaded = loader.load({ settings = settings, registry = rules, logger = test_logger })

    assert.are.equal(#config.MODULE_NAMES, #loaded)
  end)
end)

describe("loader on_load hook", function()
  it("runs on_load once and survives an error in it", function()
    local calls = 0
    local warnings = {}
    local fake_logger = {
      warn = function(_, message)
        table.insert(warnings, message)
      end,
    }

    local loaded = loader.load({
      settings = config.merge({ modules = { workspaces = { enabled = true } } }),
      registry = registry.new(),
      logger = fake_logger,
      require_module = function()
        return {
          rules = {},
          on_load = function()
            calls = calls + 1
            error("boom")
          end,
        }
      end,
    })

    assert.same({ "workspaces" }, loaded)
    assert.equals(1, calls)
    assert.equals(1, #warnings)
  end)
end)
