-- Minimal stand-in for the Hammerspoon `hs` global, used by unit tests.
-- Only the pieces Rakuen needs are mocked; add more as modules require them.

local hs_mock = {}

--- Install a fresh mock `hs` global and return it.
--- Call this in `before_each` so tests never share state.
function hs_mock.install()
  local mock_hs = {
    -- Keystrokes posted through hs.eventtap.keyStroke, in call order.
    posted_keystrokes = {},
    -- Bundle ID reported as the frontmost application.
    frontmost_bundle_id = nil,
  }

  mock_hs.eventtap = {
    keyStroke = function(modifiers, key)
      table.insert(mock_hs.posted_keystrokes, { modifiers = modifiers, key = key })
    end,
  }

  mock_hs.application = {
    frontmostApplication = function()
      return {
        bundleID = function()
          return mock_hs.frontmost_bundle_id
        end,
      }
    end,
  }

  _G.hs = mock_hs
  return mock_hs
end

--- Remove the mock `hs` global.
function hs_mock.uninstall()
  _G.hs = nil
end

return hs_mock
