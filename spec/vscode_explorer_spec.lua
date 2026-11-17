local vscode_explorer = require("rakuen.core.vscode_explorer")
local hs_mock = require("spec.helpers.hs_mock")

local function element(attributes)
  return {
    attributeValue = function(_, name)
      return attributes[name]
    end,
  }
end

local function explorer_row()
  local outline = element({ AXDescription = "Files Explorer" })
  local rows = element({ AXDOMClassList = { "monaco-list-rows" }, AXParent = outline })
  return element({ AXDOMClassList = { "monaco-list-row", "focused" }, AXParent = rows })
end

describe("vscode_explorer", function()
  after_each(function()
    hs_mock.uninstall()
  end)

  it("recognizes a Files Explorer row", function()
    assert.is_true(vscode_explorer.is_explorer_row(explorer_row()))
  end)

  it("rejects other lists and other elements", function()
    local other_outline = element({ AXDescription = "Outline" })
    local row = element({ AXDOMClassList = { "monaco-list-row" }, AXParent = other_outline })

    assert.is_false(vscode_explorer.is_explorer_row(row))
    assert.is_false(vscode_explorer.is_explorer_row(element({ AXDOMClassList = { "View" } })))
    assert.is_false(vscode_explorer.is_explorer_row(nil))
  end)

  it("lets F2 act only in the explorer for VS Code, and everywhere else", function()
    local mock_hs = hs_mock.install()
    local focused = explorer_row()
    mock_hs.application.frontmostApplication = function()
      return {
        pid = function()
          return 7
        end,
      }
    end
    mock_hs.axuielement = {
      applicationElement = function()
        return { setAttributeValue = function() end }
      end,
      systemWideElement = function()
        return {
          attributeValue = function()
            return focused
          end,
        }
      end,
    }

    assert.is_true(vscode_explorer.when_rename_applies("com.microsoft.VSCodeInsiders"))

    focused = element({ AXDOMClassList = { "xterm-helper-textarea" } })
    assert.is_false(vscode_explorer.when_rename_applies("com.microsoft.VSCodeInsiders"))
    assert.is_true(vscode_explorer.when_rename_applies("com.apple.TextEdit"))
  end)
end)
