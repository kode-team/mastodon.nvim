local utils = require("mastodon.utils")

describe("utils", function()
  describe("parse_json", function()
    it("works with simple structure", function()
      json = utils.parse_json('{"hello": "world"}')
      assert(json["hello"] == "world")
    end)

    it("works with nested json structure", function()
      json = utils.parse_json('{"a": {"b": "c"}}')
      assert(json["a"]["b"] == "c")
    end)
  end)

  describe("Stack object", function()
    Stack = utils.Stack
    it("works with separated instance", function()
      local st1 = Stack:new()
      local st2 = Stack:new()

      st1:push(1)
      st1:push(2)
      st2:push("3354")

      assert(st1:size() ~= st2:size())
      assert(st1:top() == 2)
      assert(st2:top() == "3354")
    end)
  end)
end)
