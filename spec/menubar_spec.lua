local menubar = require("rakuen.ui.menubar")
local module_state = require("rakuen.core.module_state")
local config = require("rakuen.core.config")
local hs_mock = require("spec.helpers.hs_mock")

describe("menubar", function()
  local item

  before_each(function()
    local mock_hs = hs_mock.install()
    item = {
      setIcon = function() end,
      setTitle = function(_, title)
        item.title = title
      end,
      setTooltip = function() end,
      setMenu = function(_, builder)
        item.builder = builder
      end,
      delete = function() end,
    }
    mock_hs.menubar = {
      new = function()
        return item
      end,
    }
  end)

  after_each(function()
    menubar.reset()
    hs_mock.uninstall()
  end)

  it("joins non-empty groups with separators", function()
    local menu = menubar.join({ { { title = "a" } }, {}, { { title = "b" } } })

    assert.same({ "a", "-", "b" }, { menu[1].title, menu[2].title, menu[3].title })
  end)

  it("builds module switches that flip the current value", function()
    local calls = {}
    local items = menubar.module_items(
      { "editing", "text_navigation" },
      { editing = true },
      function(name, value)
        table.insert(calls, { name, value })
      end
    )

    assert.is_true(items[1].checked)
    assert.is_false(items[2].checked)
    assert.equals("text navigation", items[2].title)

    items[1].fn()
    items[2].fn()
    assert.same({ { "editing", false }, { "text_navigation", true } }, calls)
  end)

  it("shares one item among sections and core entries", function()
    local created = 0
    _G.hs.menubar = {
      new = function()
        created = created + 1
        return item
      end,
    }

    menubar.add_section("one", function()
      return { { title = "First" } }
    end)
    menubar.add_section("two", function()
      return { { title = "Second" } }
    end)
    menubar.configure({ on_cheatsheet = function() end })

    assert.equals(1, created)
    local titles = {}
    for _, entry in ipairs(item.builder()) do
      table.insert(titles, entry.title)
    end
    assert.same({ "First", "-", "Second", "-", "Show keybindings" }, titles)
  end)

  it("always titles the item Rakuen", function()
    menubar.set_appearance({}, "tip")

    assert.equals("楽", item.title)
  end)
end)

describe("module_state", function()
  it("overrides enabled flags and ignores unknown names", function()
    local settings = config.defaults()
    module_state.apply(settings, { editing = true, nonsense = true, windows = "yes" })

    assert.is_true(settings.modules.editing.enabled)
    assert.is_false(settings.modules.windows.enabled)
  end)

  it("returns an updated copy", function()
    local original = { editing = true }
    local updated = module_state.with(original, "windows", false)

    assert.same({ editing = true }, original)
    assert.same({ editing = true, windows = false }, updated)
  end)
end)
