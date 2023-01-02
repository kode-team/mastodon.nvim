local Parser = require("mastodon.parser")
local renderer = require("mastodon.renderer")

describe("renderer module", function()
  describe("for render_lines function", function()
    it("works with simple dataset", function()
      local parser1 = Parser:new("<p>hello world</p>aaaaa<b>aaa</b>")
      local parser2 = Parser:new("<p>hello world</p><br/>")

      local parse_tree1 = parser1:parse()
      local parse_tree2 = parser2:parse()

      local nodes1 = {}
      local nodes2 = {}
      renderer.flatten_nodes(nodes1, parse_tree1)
      renderer.flatten_nodes(nodes2, parse_tree2)

      local lines1 = renderer.render_lines(nodes1)
      local lines2 = renderer.render_lines(nodes2)

      assert(lines1[1] == "hello world")
      assert(lines1[2] == "aaaaaaaa")

      assert(lines2[1] == "hello world")
      assert(lines2[2] == "")
    end)

    describe("for actual dataset", function()
      it("works with heartade's case", function()
        -- Thanks to heartade
        local parser1 = Parser:new(
          '<p><span class="h-card"><a class="u-url mention" href="https://qdon.space/@horse_sensei" rel="nofollow noopener noreferrer" target="_blank">@<span>horse_sensei</span></a></span>  <code>pleroma</code> <em>specific</em> <a href="https://en.m.wikipedia.org/wiki/Markdown" rel="nofollow noopener noreferrer" target="_blank">markdown</a> <strong>syntax</strong> <del>test</del></p><ul><li>li</li><li>li &lt;br/&gt;<ul><li><code>‹li› ‹/li›</code></li></ul></li></ul><blockquote><p>quote</p></blockquote>heading<p><a class="hashtag" href="https://my.covalent.ml/tag/hashtag" rel="nofollow noopener noreferrer" target="_blank">#hashtag</a></p>heading'
        )

        local parse_tree1 = parser1:parse()
        local nodes1 = {}
        renderer.flatten_nodes(nodes1, parse_tree1)

        local lines1 = renderer.render_lines(nodes1)
        assert(parse_tree1.tag == "html")
      end)
    end)
  end)
end)
