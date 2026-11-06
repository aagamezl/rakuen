local synthetic = require("rakuen.core.synthetic")

describe("synthetic", function()
  it("recognizes its own marker", function()
    assert.is_true(synthetic.is_marked(0x52414B55))
    assert.is_true(synthetic.is_marked(1380010837))
  end)

  it("does not treat other values as marked", function()
    assert.is_false(synthetic.is_marked(0))
    assert.is_false(synthetic.is_marked(nil))
  end)
end)
