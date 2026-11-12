-- Pure helpers for window screenshots with `screencapture`.

local screenshot = {}

local SCREENCAPTURE = "/usr/sbin/screencapture"

--- File name in the macOS style: "Screenshot 2026-11-11 at 10.13.30.png".
--- `time` is a table from os.date("*t").
function screenshot.file_name(time)
  assert(type(time) == "table", "time must be a table")

  return string.format(
    "Screenshot %04d-%02d-%02d at %02d.%02d.%02d.png",
    time.year,
    time.month,
    time.day,
    time.hour,
    time.min,
    time.sec
  )
end

--- Full path on the Desktop, where macOS saves screenshots by default.
function screenshot.file_path(home, time)
  assert(type(home) == "string" and home ~= "", "home must be a non-empty string")

  return home .. "/Desktop/" .. screenshot.file_name(time)
end

--- Command and arguments that capture one window by id.
--- Returns the executable and its argument list.
function screenshot.window_command(window_id, path)
  assert(math.type(window_id) == "integer", "window_id must be an integer")
  assert(type(path) == "string" and path ~= "", "path must be a non-empty string")

  return SCREENCAPTURE, { "-l", tostring(window_id), path }
end

return screenshot
