-- page-code: {{< page-code part-2 >}} on a dashboard page adds a "Code"
-- button to the navbar that, while that page is showing, opens a window
-- with the code of the cell labeled part-2. The code is read from the .qmd
-- itself, so it is exactly what was written, minus the #| option lines.

local source_lines = nil   -- the .qmd, read once
local used = {}            -- shortcode lines in the source already matched
local calls = 0

local function read_source()
  if source_lines then return source_lines end
  source_lines = {}
  local f = io.open(quarto.doc.input_file, "r")
  if f then
    for line in f:lines() do table.insert(source_lines, line) end
    f:close()
  end
  return source_lines
end

-- Each code cell's lines (without #| options), keyed by its label, and each
-- page-code shortcode in the source (outside comments and code cells): its
-- labels and the page title (level-1 heading) it sits under.
local function scan()
  local lines = read_source()
  local cells, pages = {}, {}
  local in_cell, in_comment, fence, page = false, false, nil, nil
  local label, body = nil, {}
  for _, line in ipairs(lines) do
    if in_cell then
      if line:match("^%s*" .. fence .. "%s*$") then
        if label then cells[label] = body end
        in_cell, label, body = false, nil, {}
      else
        local opt = line:match("^%s*#|%s*label:%s*(.-)%s*$")
        if opt then
          label = opt:gsub("^[\"']", ""):gsub("[\"']$", "")
        elseif not line:match("^%s*#|") then
          table.insert(body, line)
        end
      end
    elseif in_comment then
      if line:find("-->", 1, true) then in_comment = false end
    else
      local f, header = line:match("^%s*(```+)%s*{r%s*(.-)}%s*$")
      if f then
        in_cell, fence, body = true, f, {}
        label = header:match("^([%w_%-]+)") -- {r label}
      elseif line:find("<!--", 1, true) and not line:find("-->", 1, true) then
        in_comment = true
      else
        local title = line:match("^#%s+(.-)%s*$")
        if title then page = title:gsub("%s*{.-}%s*$", "") end
        local args = line:match("{{<%s*page%-code%s+(.-)%s*>}}")
        if args then table.insert(pages, { args = args:gsub("%s+", " "), page = page or "" }) end
      end
    end
  end
  return cells, pages
end

local function trim_blank(lines)
  local first, last = 1, #lines
  while first <= last and lines[first]:match("^%s*$") do first = first + 1 end
  while last >= first and lines[last]:match("^%s*$") do last = last - 1 end
  return table.concat(lines, "\n", first, last)
end

local function highlight(code, n)
  local doc = pandoc.Pandoc({ pandoc.CodeBlock(code, { class = "r" }) })
  local opts = pandoc.WriterOptions({ identifier_prefix = "page-code-" .. n .. "-" })
  return pandoc.write(doc, "html", opts)
end

return {
  ["page-code"] = function(args)
    if not quarto.doc.is_format("html") then return pandoc.Null() end
    calls = calls + 1
    local cells, shortcodes = scan()
    -- Quarto also runs shortcodes inside HTML comments, so match this call to
    -- the next unmatched shortcode in the source with the same labels; a call
    -- with no match came from a comment and is skipped.
    local labels = {}
    for _, arg in ipairs(args) do table.insert(labels, pandoc.utils.stringify(arg)) end
    local key, page = table.concat(labels, " "), nil
    for i, sc in ipairs(shortcodes) do
      if not used[i] and sc.args == key then used[i], page = true, sc.page; break end
    end
    if not page then return pandoc.Null() end
    local blocks = {}
    for i, arg in ipairs(args) do
      local label = pandoc.utils.stringify(arg)
      local code = cells[label]
      if code then
        table.insert(blocks, { label = label, html = highlight(trim_blank(code), calls .. "-" .. i) })
      else
        quarto.log.warning("page-code: no code cell labeled '" .. label .. "'")
        table.insert(blocks, { label = label, html = "<p>No code cell labeled <code>" .. label .. "</code>.</p>" })
      end
    end
    quarto.doc.add_html_dependency({
      name = "page-code", version = "1.0.0",
      scripts = { "page-code.js" }, stylesheets = { "page-code.css" },
    })
    local data = pandoc.json.encode({ page = page, blocks = blocks }):gsub("</", "<\\/")
    quarto.doc.include_text("after-body",
      '<script type="application/json" class="page-code-data">' .. data .. "</script>")
    return pandoc.Null()
  end
}
