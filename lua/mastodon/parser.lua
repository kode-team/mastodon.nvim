local utils = require("mastodon.utils")
Stack = utils.Stack

local Parser = {}

SELF_CLOSING_TAGS = {
  "area", "base", "br", "col", "embed", "hr", "img", "input",
  "link", "meta", "param", "source", "track", "wbr",
}

BLOCK_ELEMENTS = {
  "html", "body", "article", "section", "nav", "aside",
  "h1", "h2", "h3", "4", "h5", "h6", "hgroup", "header",
  "footer", "address", "p", "hr", "pre", "blockquote",
  "ol", "ul", "menu", "li", "dl", "dt", "dd", "figure",
  "figcaption", "main", "div", "table", "form", "fieldset",
  "legend", "details", "summary"
}

local TextNode = {}

local function split_string(text)
  local chunks = {}
  for substring in text:gmatch("%S+") do
     table.insert(chunks, substring)
  end

  return chunks
end

function TextNode:new(text, parent)
  local o = setmetatable({}, self)
  o.text = text
  o.parent = parent
  return o
end

local ElementNode = {}

function ElementNode:new(tag, attributes, parent)
  local o = setmetatable({}, self)
  o.tag = tag
  o.attributes = attributes
  o.parent = parent
  o.children = {}
  return o
end

local function contains(table, val)
   for i=1,#table do
      if table[i] == val then
         return true
      end
   end
   return false
end

Parser.__index = Parser

function Parser:new(content)
  local o = setmetatable({}, self)
  o.i = 1
  o.content = "<html>" .. content .. "</html>"
  o.unfinished = Stack.new()
  return o
end

function Parser:add_text(text)
  local parent = self.unfinished:top()
  local node = TextNode:new(text, parent)
  if parent ~= nil then
    table.insert(parent.children, node)
  end
end

function Parser:add_tag(text)
  local result = self:get_attributes(text)
  local tag = result.tag
  local attributes = result.attributes
  if tag:sub(1, 1) == "/" then
    if (self.unfinished:size() == 1) then
      return
    end
    local node = self.unfinished:pop()
    local parent = self.unfinished:top()
    local closing_node = ElementNode:new("/" .. node.tag, {}, parent)
    table.insert(parent.children, node)
    table.insert(parent.children, closing_node)
  elseif contains(SELF_CLOSING_TAGS, tag) then
    local parent = self.unfinished:top()
    local node = ElementNode:new(tag, attributes, parent)
    table.insert(parent.children, node)
  else
    local parent = self.unfinished:top()
    local node = ElementNode:new(tag, attributes, parent)
    self.unfinished:push(node)
  end
end

function Parser:get_attributes(text)
  local tokens = split_string(text)
  local tag = tokens[1]
  local attributes = {}

  for i=2, #tokens, 1 do
    attributes[i - 1] = tokens[i]
  end

  return {
    tag = tag,
    attributes = attributes,
  }
end

function Parser:parse()
  local text = ""
  local in_tag = false

  local content = self.content
  local len = #content

  self.i = 1
  for q=0, len, 1 do
    local i = self.i
    local j = self.i
    if (i > len) then
      if text ~= "" then
        self:add_text(text)
        text = ""
      end
      break
    end
    local char = self.content:sub(i, j)
    local code = char:byte()

    if (code >= 0 and code <= 127) then
      j = i + 0
    elseif (bit.band(code, 0xE0) == 0xC0) then
      j = i + 1
    elseif (bit.band(code, 0xF0) == 0xE0) then
      j = i + 2
    elseif (bit.band(code, 0xF8) == 0xF0) then
      j = i + 3
    elseif (bit.band(code, 0xFC) == 0xF8) then
      j = i + 4
    elseif (bit.band(code, 0xFE) == 0xFC) then
      j = i + 5
    else
    end

    char = self.content:sub(i, j)
    if (char == "<") then
      in_tag = true
      if text ~= "" then
        self:add_text(text)
      end
      text = ""
    elseif (char == ">") then
      in_tag = false
      self:add_tag(text)
      text = ""
    else
      text = text .. char
    end

    j = j + 1

    self.i = j
  end

  if not in_tag and text ~= "" then
    self:add_text(text)
  end

  return self:finish()
end

function Parser:finish()
  while self.unfinished:size() > 1 do
    local node = self.unfinished:pop()
    local parent = self.unfinished:top()
    table.insert(parent.children, node)
  end

  return self.unfinished:pop()
end

return Parser
