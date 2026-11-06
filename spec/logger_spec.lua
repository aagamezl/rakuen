local logger = require("rakuen.core.logger")

describe("logger", function()
  local lines
  local sink

  before_each(function()
    lines = {}
    sink = function(line)
      table.insert(lines, line)
    end
  end)

  it("drops messages below the threshold", function()
    local log = logger.new("warn", sink)

    log:info("hidden")
    log:warn("shown")

    assert.are.same({ "[rakuen] warn: shown" }, lines)
  end)

  it("defaults to info", function()
    local log = logger.new(nil, sink)

    log:debug("hidden")
    log:info("shown")

    assert.are.equal(1, #lines)
  end)

  it("rejects an unknown level", function()
    assert.has_error(function()
      logger.new("loud", sink)
    end)
  end)
end)
