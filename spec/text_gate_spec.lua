local text_gate = require("rakuen.core.text_gate")

describe("text_gate", function()
  it("accepts editable text roles", function()
    for _, role in ipairs({ "AXTextField", "AXTextArea", "AXComboBox", "AXSearchField" }) do
      assert.is_true(text_gate.allows(role, "com.apple.TextEdit", {}), role)
    end
  end)

  it("rejects other roles and a missing role", function()
    assert.is_false(text_gate.allows("AXButton", "com.apple.TextEdit", {}))
    assert.is_false(text_gate.allows(nil, "com.apple.TextEdit", {}))
  end)

  it("always allows forced apps, even without a role", function()
    local force = { "com.google.Chrome" }
    assert.is_true(text_gate.allows(nil, "com.google.Chrome", force))
    assert.is_false(text_gate.allows(nil, "com.apple.Finder", force))
  end)

  it("handles a missing frontmost app", function()
    assert.is_false(text_gate.allows(nil, nil, { "com.google.Chrome" }))
  end)
end)
