local screenshot = require("rakuen.core.screenshot")

local TIME = { year = 2026, month = 11, day = 5, hour = 9, min = 3, sec = 7 }

describe("screenshot", function()
  it("names files in the macOS style with zero padding", function()
    assert.equals("Screenshot 2026-11-05 at 09.03.07.png", screenshot.file_name(TIME))
  end)

  it("saves on the Desktop", function()
    assert.equals(
      "/Users/me/Desktop/Screenshot 2026-11-05 at 09.03.07.png",
      screenshot.file_path("/Users/me", TIME)
    )
  end)

  it("builds a screencapture command for one window", function()
    local executable, arguments = screenshot.window_command(42, "/tmp/a.png")
    assert.equals("/usr/sbin/screencapture", executable)
    assert.same({ "-l", "42", "/tmp/a.png" }, arguments)
  end)

  it("rejects a non-integer window id", function()
    assert.has_error(function()
      screenshot.window_command("42", "/tmp/a.png")
    end)
  end)
end)
