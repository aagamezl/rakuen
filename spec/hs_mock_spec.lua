-- Smoke test: proves the test harness and the `hs` mock work.

local hs_mock = require("helpers.hs_mock")

describe("hs mock", function()
  local mock_hs

  before_each(function()
    mock_hs = hs_mock.install()
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("records posted keystrokes", function()
    hs.eventtap.keyStroke({ "cmd" }, "c")

    assert.are.equal(1, #mock_hs.posted_keystrokes)
    assert.are.equal("c", mock_hs.posted_keystrokes[1].key)
  end)

  it("reports the configured frontmost application", function()
    mock_hs.frontmost_bundle_id = "com.apple.finder"

    local bundle_id = hs.application.frontmostApplication():bundleID()

    assert.are.equal("com.apple.finder", bundle_id)
  end)
end)
