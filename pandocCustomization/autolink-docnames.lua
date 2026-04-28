-- autolink-docnames.lua
-- Replaces bare occurrences of known IVOA DOCNAME words in prose with
-- RST :doc: cross-reference links.
--
-- Guards:
--   * No self-links (current doc's own DOCNAME is skipped).
--   * Text inside Link, Span (\texttt{}/\textsf{} → code-like), Code, RawInline
--     (already-converted citations), or Header nodes is left untouched.
--
-- Requires pandoc ≥ 3.0 for topdown traversal.
--
-- Placement in the filter chain:
--   Run AFTER relink-ivoa-citations.lua so that \cite{...} nodes have already
--   been converted to RawInline("rst", ...) and won't be double-processed.

local io = require 'io'

local docnames = {}  -- set: docnames[name] = true for each known DOCNAME
local docname  = "" -- this document's own DOCNAME (self-link guard)

-- ── Metadata ─────────────────────────────────────────────────────────────────

function Meta(m)
    docname = pandoc.utils.stringify(m["DOCNAME"])

    local mapfilepath = m["bibmap"]
    if not mapfilepath then
        pandoc.log.warning("autolink-docnames: no 'bibmap' metadata; skipping.")
        return
    end

    local f = io.open(mapfilepath, "r")
    if f then
        for line in f:lines() do
            -- Match the YAML key: lines like  "VOResource: ..."
            local key = line:match("^([%a][%w%-_]*)%s*:")
            if key then
                docnames[key] = true
            end
        end
        f:close()
    else
        pandoc.log.error("autolink-docnames: cannot open " .. tostring(mapfilepath))
    end
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function make_doc_link(name)
    -- Same :doc: path convention used by relink-ivoa-citations.lua
    local rst = ":doc:`" .. name .. " <../" .. name .. "/" .. name .. ">`"
    return pandoc.RawInline("rst", rst)
end

-- ── Guard containers ──────────────────────────────────────────────────────────
-- With traverse = 'topdown', returning (el, false) prevents pandoc from
-- recursing into the element's children, so Str nodes inside are never seen
-- by the Str handler below.

-- Links: content is a human-readable label, already purposefully worded.
function Link(el)     return el, false end

-- Spans: \texttt{X} / \textsf{X} etc. arrive as Span([Str("X")]) – code-like.
function Span(el)     return el, false end

-- Code spans: obvious
function Code(el)     return el, false end

-- RawInline: includes already-converted :doc: links from relink-ivoa-citations.lua
function RawInline(el) return el, false end

-- Headers: don't auto-link section titles
function Header(el)   return el, false end

-- ── Core replacement ──────────────────────────────────────────────────────────

function Str(el)
    local text = el.text

    -- Split off leading and trailing punctuation so "TAP," or "(ADQL)" still match.
    local pre, word, post = text:match("^([%p]*)([%a][%w%-]*)([%p]*)$")

    if not word then return end           -- no alpha word component
    if not docnames[word] then return end -- not a known DOCNAME
    if word == docname then return end    -- self-link guard

    local result = {}
    if pre  ~= "" then result[#result+1] = pandoc.Str(pre) end
    result[#result+1] = make_doc_link(word)
    if post ~= "" then result[#result+1] = pandoc.Str(post) end
    return result
end

-- ── Filter pipeline ───────────────────────────────────────────────────────────
-- traverse = 'topdown' ensures parent handlers fire before children,
-- so (el, false) guards correctly block child Str processing.

return {
    { Meta = Meta },
    {
        traverse  = 'topdown',
        Link      = Link,
        Span      = Span,
        Code      = Code,
        RawInline = RawInline,
        Header    = Header,
        Str       = Str,
    }
}
