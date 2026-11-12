-- Run slow rule handlers outside the event tap.
--
-- macOS disables an event tap whose callback is slow, and a disabled tap stops
-- every Rakuen shortcut. Handlers that talk to other processes (accessibility,
-- launching apps, dialogs) therefore run on a zero-delay timer, and an error in
-- one becomes an alert instead of being lost in the console.

local deferred = {}

--- Wrap `handler` so the tap callback returns at once and the work runs later.
function deferred.guard(handler)
  assert(type(handler) == "function", "handler must be a function")

  return function()
    hs.timer.doAfter(0, function()
      local succeeded, handler_error = pcall(handler)
      if not succeeded then
        hs.alert.show("Rakuen: " .. tostring(handler_error))
      end
    end)
  end
end

return deferred
