local config = require("rakuen.core.config")

describe("config", function()
  describe("defaults", function()
    it("uses log mode with every module disabled", function()
      local settings = config.defaults()

      assert.are.equal("log", settings.mode)
      for _, name in ipairs(config.MODULE_NAMES) do
        assert.is_false(settings.modules[name].enabled)
      end
    end)
  end)

  describe("merge", function()
    it("returns defaults for an empty table", function()
      assert.are.same(config.defaults(), config.merge({}))
    end)

    it("applies mode, log level and module flags", function()
      local settings = config.merge({
        mode = "match",
        log_level = "debug",
        modules = { editing = { enabled = true } },
      })

      assert.are.equal("match", settings.mode)
      assert.are.equal("debug", settings.log_level)
      assert.is_true(settings.modules.editing.enabled)
      assert.is_false(settings.modules.windows.enabled)
    end)

    it("keeps native Cmd chords untouched by default and accepts the opt-in", function()
      assert.is_false(config.merge({}).block_native_cmd)
      assert.is_true(config.merge({ block_native_cmd = true }).block_native_cmd)
    end)

    it("rejects bad values", function()
      local bad_configs = {
        { mode = "fast" },
        { log_level = "loud" },
        { only = "nonsense" },
        { block_native_cmd = "yes" },
        { modules = { nonsense = {} } },
        { modules = { editing = { enabled = "yes" } } },
        { modules = { editing = { bindings = { Copy = { enabled = "no" } } } } },
        { modules = { editing = { colour = "red" } } },
        { unknown_key = true },
      }

      for _, bad in ipairs(bad_configs) do
        assert.has_error(function()
          config.merge(bad)
        end)
      end
    end)
  end)

  describe("load", function()
    local function write_temp(content)
      local path = os.tmpname()
      local file = assert(io.open(path, "w"))
      file:write(content)
      file:close()
      return path
    end

    it("returns defaults without an error when the file is missing", function()
      local settings, load_error = config.load("/nonexistent/rakuen/config.lua")

      assert.are.same(config.defaults(), settings)
      assert.is_nil(load_error)
    end)

    it("loads a valid file", function()
      local path = write_temp('return { mode = "match" }')

      local settings, load_error = config.load(path)
      os.remove(path)

      assert.is_nil(load_error)
      assert.are.equal("match", settings.mode)
    end)

    it("falls back to defaults with a message for a syntax error", function()
      local path = write_temp("return {")

      local settings, load_error = config.load(path)
      os.remove(path)

      assert.are.same(config.defaults(), settings)
      assert.is_not_nil(load_error)
    end)

    it("falls back to defaults with a message for invalid values", function()
      local path = write_temp('return { mode = "fast" }')

      local settings, load_error = config.load(path)
      os.remove(path)

      assert.are.same(config.defaults(), settings)
      assert.is_truthy(load_error:find("mode", 1, true))
    end)
  end)

  describe("is_module_enabled", function()
    it("follows the enabled flag", function()
      local settings = config.merge({ modules = { editing = { enabled = true } } })

      assert.is_true(config.is_module_enabled(settings, "editing"))
      assert.is_false(config.is_module_enabled(settings, "windows"))
    end)

    it("enables only the chosen module when only is set", function()
      local settings = config.merge({
        only = "windows",
        modules = { editing = { enabled = true } },
      })

      assert.is_true(config.is_module_enabled(settings, "windows"))
      assert.is_false(config.is_module_enabled(settings, "editing"))
    end)
  end)

  describe("apply_overrides", function()
    local rules = {
      { description = "Copy", to = "Ctrl+C" },
      { description = "Paste", to = "Ctrl+V" },
    }

    it("drops disabled bindings", function()
      local result = config.apply_overrides(rules, { Copy = { enabled = false } })

      assert.are.equal(1, #result)
      assert.are.equal("Paste", result[1].description)
    end)

    it("replaces applications without changing the original rule", function()
      local filter = { disable = { "com.apple.Terminal" } }

      local result = config.apply_overrides(rules, { Copy = { applications = filter } })

      assert.are.same(filter, result[1].applications)
      assert.is_nil(rules[1].applications)
    end)

    it("leaves rules alone without overrides", function()
      assert.are.same(rules, config.apply_overrides(rules, {}))
    end)
  end)

  describe("unknown_bindings", function()
    it("lists binding names that match no rule", function()
      local rules = { { description = "Copy" } }

      local unknown = config.unknown_bindings(rules, { Copy = {}, Cpoy = {}, Aaa = {} })

      assert.are.same({ "Aaa", "Cpoy" }, unknown)
    end)
  end)
end)
