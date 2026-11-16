local vscode_terminal = require("rakuen.core.vscode_terminal")
local hs_mock = require("spec.helpers.hs_mock")

local function element(attributes)
  return {
    attributeValue = function(_, name)
      return attributes[name]
    end,
  }
end

local function install_ax(mock_hs, focused_element)
  local app = {
    pid = function()
      return 1
    end,
  }
  mock_hs.application.frontmostApplication = function()
    return app
  end
  mock_hs.axuielement = {
    applicationElement = function()
      return {
        setAttributeValue = function() end,
      }
    end,
    systemWideElement = function()
      return {
        attributeValue = function()
          return focused_element()
        end,
      }
    end,
  }
end

describe("vscode_terminal", function()
  after_each(function()
    hs_mock.uninstall()
  end)

  it("recognizes the xterm input by its class", function()
    local xterm = { AXDOMClassList = { "xterm-helper-textarea" }, AXDescription = "Message input" }

    assert.is_true(vscode_terminal.is_terminal_element(element(xterm)))
  end)

  it("knows the VS Code family bundle ids", function()
    assert.is_true(vscode_terminal.is_editor("com.microsoft.VSCode"))
    assert.is_false(vscode_terminal.is_editor("com.apple.Terminal"))
    assert.is_false(vscode_terminal.is_editor(nil))
  end)

  it("recognizes the terminal input by its label", function()
    assert.is_true(
      vscode_terminal.is_terminal_element(element({ AXDescription = "Terminal 1, zsh" }))
    )
    assert.is_true(vscode_terminal.is_terminal_element(element({ AXTitle = "terminal input" })))
    assert.is_false(
      vscode_terminal.is_terminal_element(element({ AXDescription = "Editor content" }))
    )
    assert.is_false(vscode_terminal.is_terminal_element(element({})))
    assert.is_false(vscode_terminal.is_terminal_element(nil))
  end)

  it("gates only VS Code editors by focus", function()
    local mock_hs = hs_mock.install()
    local focused = element({ AXDescription = "Terminal input" })
    install_ax(mock_hs, function()
      return focused
    end)

    assert.is_true(vscode_terminal.when_in_terminal("com.microsoft.VSCode"))
    assert.is_false(vscode_terminal.when_outside_terminal("com.microsoft.VSCode"))

    focused = element({ AXDescription = "Editor content" })
    assert.is_false(vscode_terminal.when_in_terminal("com.microsoft.VSCode"))
    assert.is_true(vscode_terminal.when_outside_terminal("com.microsoft.VSCode"))

    assert.is_true(vscode_terminal.when_in_terminal("com.apple.Terminal"))
    assert.is_true(vscode_terminal.when_outside_terminal("com.apple.Safari"))
  end)

  it("treats an accessibility failure as not a terminal", function()
    local mock_hs = hs_mock.install()
    install_ax(mock_hs, function()
      error("AX failed")
    end)

    assert.is_false(vscode_terminal.is_focused())
  end)
end)
