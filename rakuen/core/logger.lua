-- Console logger with levels.

local logger = {}
logger.__index = logger

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }

--- Return true when a message at `level` passes `threshold`.
function logger.should_log(level, threshold)
  assert(LEVELS[level], "unknown log level: " .. tostring(level))
  assert(LEVELS[threshold], "unknown log level: " .. tostring(threshold))
  return LEVELS[level] >= LEVELS[threshold]
end

--- Create a logger. `threshold` defaults to "info". `sink` defaults to print.
function logger.new(threshold, sink)
  local self = setmetatable({}, logger)
  self.threshold = threshold or "info"
  self.sink = sink or print
  assert(LEVELS[self.threshold], "unknown log level: " .. tostring(self.threshold))
  return self
end

function logger:log(level, message)
  if not logger.should_log(level, self.threshold) then
    return
  end
  self.sink(string.format("[rakuen] %s: %s", level, message))
end

function logger:debug(message)
  self:log("debug", message)
end

function logger:info(message)
  self:log("info", message)
end

function logger:warn(message)
  self:log("warn", message)
end

function logger:error(message)
  self:log("error", message)
end

return logger
