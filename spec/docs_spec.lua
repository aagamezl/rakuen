local config = require("rakuen.core.config")
local docs = require("rakuen.core.docs")
local docs_data = require("scripts.docs_data")
local hs_mock = require("spec.helpers.hs_mock")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

describe("docs", function()
  local data = {
    header = "# Title",
    gnome = { ["Copy|Ctrl+C"] = "Ctrl+C" },
    sections = { editing = { title = "Editing", intro = "Intro text.", extra_rows = {} } },
    not_configured = { { "Rotate", "XF86", "—", "none", "No", "No API" } },
  }

  local function rules()
    return {
      {
        module = "editing",
        description = "Copy",
        from = "Cmd+C",
        to = "Ctrl+C",
        feasibility = "yes",
        note = "Disabled | in terminals",
      },
    }
  end

  it("escapes pipes in cells", function()
    assert.equals("a \\| b", docs.cell("a | b"))
  end)

  it("builds a row with the six columns", function()
    local row = docs.rule_row(rules()[1], data.gnome)

    assert.same({ "Copy", "Ctrl+C", "Ctrl+C", "Cmd+C", "Yes", "Disabled | in terminals" }, row)
  end)

  it("prefers the rule's own gnome field", function()
    local rule = { description = "X", to = "Ctrl+X", gnome = "Alt+X" }
    assert.equals("Alt+X", docs.gnome_chord(rule, {}))
  end)

  it("reports rules that have no GNOME chord", function()
    local missing = docs.missing_gnome(rules(), {})
    assert.same({ "editing: Copy (Ctrl+C)" }, missing)
  end)

  it("renders sections, intro, rows and the not configured table", function()
    local text = docs.render(rules(), data)

    assert.is_truthy(text:find("# Title", 1, true))
    assert.is_truthy(text:find("### Editing", 1, true))
    assert.is_truthy(text:find("Intro text.", 1, true))
    assert.is_truthy(
      text:find("| Copy | Ctrl+C | Ctrl+C | Cmd+C | Yes | Disabled \\| in terminals |", 1, true)
    )
    assert.is_truthy(text:find("### Not configured", 1, true))
    assert.is_truthy(text:find("| Rotate |", 1, true))
  end)

  describe("with the real modules", function()
    local real_rules

    before_each(function()
      hs_mock.install()
      local settings = config.defaults()
      for _, module_name in ipairs(config.MODULE_NAMES) do
        settings.modules[module_name].enabled = true
      end

      local rule_registry = registry.new()
      loader.load({ settings = settings, registry = rule_registry, logger = logger.new("error") })
      real_rules = rule_registry:all()
    end)

    after_each(function()
      hs_mock.uninstall()
    end)

    it("has a GNOME chord for every registered rule", function()
      assert.same({}, docs.missing_gnome(real_rules, docs_data.gnome))
    end)

    it("lists every registered rule once", function()
      local text = docs.render(real_rules, docs_data)
      for _, rule in ipairs(real_rules) do
        local row = "| " .. docs.cell(rule.description) .. " | "
        assert.is_truthy(text:find(row, 1, true), rule.description)
      end
    end)
  end)
end)
