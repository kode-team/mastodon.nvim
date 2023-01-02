local Parser = require("mastodon.parser")

describe("Parser", function()
  describe("For basic functionality", function()
    it("All parse tree have single root node", function()
      local parser1 = Parser:new("<p>hello world</p>aaaaa<b>aaa</b>")
      local parser2 = Parser:new("<p>hello world</p><br/>")

      local parse_tree1 = parser1:parse()
      local parse_tree2 = parser2:parse()

      assert(parse_tree1.tag == "html")
      assert(parse_tree2.tag == "html")

      assert(parse_tree1.children[1].tag == "p")
      assert(parse_tree1.children[2].tag == "/p")
      assert(parse_tree1.children[3].text == "aaaaa")
      assert(parse_tree1.children[4].tag == "b")

      assert(parse_tree2.children[1].tag == "p")
      assert(parse_tree2.children[2].tag == "/p")
      assert(parse_tree2.children[3].tag == "br/")
    end)
  end)

  describe("for actual dataset", function()
    it("works with heartade's case", function()
      -- Thanks to heartade
      local parser1 = Parser:new(
        '<p><span class="h-card"><a class="u-url mention" href="https://qdon.space/@horse_sensei" rel="nofollow noopener noreferrer" target="_blank">@<span>horse_sensei</span></a></span>  <code>pleroma</code> <em>specific</em> <a href="https://en.m.wikipedia.org/wiki/Markdown" rel="nofollow noopener noreferrer" target="_blank">markdown</a> <strong>syntax</strong> <del>test</del></p><ul><li>li</li><li>li &lt;br/&gt;<ul><li><code>‹li› ‹/li›</code></li></ul></li></ul><blockquote><p>quote</p></blockquote>heading<p><a class="hashtag" href="https://my.covalent.ml/tag/hashtag" rel="nofollow noopener noreferrer" target="_blank">#hashtag</a></p>heading'
      )

      local parse_tree1 = parser1:parse()

      assert(parse_tree1.tag == "html")
    end)
  end)
end)
