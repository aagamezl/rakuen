local cheatsheet = require("rakuen.ui.cheatsheet")
local config = require("rakuen.core.config")
local hs_mock = require("spec.helpers.hs_mock")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

describe("cheatsheet", function()
  local function sample_rules()
    return {
      { module = "editing", description = "Copy", from = "Cmd+C", to = "Ctrl+C" },
      {
        module = "windows",
        description = "Window action menu",
        from = "none",
        to = "Opt+Space",
        feasibility = "partial",
        note = "macOS has no window menu",
      },
      { module = "editing", description = "Paste", to = "Ctrl+V", note = "Disabled in terminals" },
    }
  end

  it("builds one row per rule with the three columns", function()
    local rows = cheatsheet.rows(sample_rules())

    assert.equals(3, #rows)
    assert.equals("Ctrl+C", rows[1].new)
    assert.equals("Cmd+C", rows[1].original)
    assert.equals("Copy", rows[1].description)
  end)

  it("shows none when a rule has no original chord", function()
    assert.equals("none", cheatsheet.rows(sample_rules())[3].original)
  end)

  it("puts the feasibility prefix and the note in the description", function()
    local row = cheatsheet.rows(sample_rules())[2]

    assert.equals("Partial: Window action menu. macOS has no window menu", row.description)
  end)

  it("appends the note of a plain rule", function()
    assert.equals("Paste. Disabled in terminals", cheatsheet.rows(sample_rules())[3].description)
  end)

  it("groups rows by module in first-appearance order", function()
    local groups = cheatsheet.group(cheatsheet.rows(sample_rules()))

    assert.equals(2, #groups)
    assert.equals("editing", groups[1].module)
    assert.equals(2, #groups[1].rows)
    assert.equals("windows", groups[2].module)
  end)

  it("makes module names readable", function()
    assert.equals("Text navigation", cheatsheet.module_title("text_navigation"))
    assert.equals("Editing", cheatsheet.module_title("editing"))
  end)

  it("escapes HTML in rule text", function()
    assert.equals("&lt;b&gt; &amp; &quot;x&quot;", cheatsheet.escape_html('<b> & "x"'))
  end)

  it("renders every rule into the page", function()
    local page = cheatsheet.html(cheatsheet.group(cheatsheet.rows(sample_rules())))

    assert.is_truthy(page:find("<kbd>Ctrl+C</kbd>", 1, true))
    assert.is_truthy(page:find("<kbd>Cmd+C</kbd>", 1, true))
    assert.is_truthy(page:find("Window action menu", 1, true))
    assert.is_truthy(page:find('id="filter"', 1, true))
    assert.is_truthy(page:find("prefers-color-scheme: dark", 1, true))
  end)

  it("never injects unescaped rule text", function()
    local page = cheatsheet.html(cheatsheet.group(cheatsheet.rows({
      { module = "editing", description = "<script>x()</script>", to = "Ctrl+C" },
    })))

    assert.is_nil(page:find("<script>x()", 1, true))
  end)

  it("renders a long list without trouble", function()
    local rules = {}
    for index = 1, 200 do
      table.insert(rules, {
        module = "editing",
        description = "Rule " .. index,
        to = "Ctrl+F" .. index,
      })
    end

    local page = cheatsheet.html(cheatsheet.group(cheatsheet.rows(rules)))
    assert.is_truthy(page:find("Rule 200", 1, true))
  end)

  describe("with the real modules", function()
    before_each(function()
      hs_mock.install()
    end)

    after_each(function()
      hs_mock.uninstall()
    end)

    it("lists exactly the rules the binder registered", function()
      local settings = config.defaults()
      for _, module_name in ipairs(config.MODULE_NAMES) do
        settings.modules[module_name].enabled = true
      end

      local rules = registry.new()
      loader.load({
        settings = settings,
        registry = rules,
        logger = logger.new("error"),
      })

      local rows = cheatsheet.rows(rules:all())

      assert.is_true(#rows > 50)
      assert.equals(#rules:all(), #rows)
      for index, row in ipairs(rows) do
        assert.equals(rules:all()[index].to, row.new)
        assert.is_string(row.original)
        assert.is_string(row.description)
      end
    end)
  end)
end)
