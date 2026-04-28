-- fix-figure-media-links.lua
-- Replace Image elements whose source file is a PDF with an RST hyperlink,
-- since browsers cannot render PDFs as inline images.
--
-- Policy: PDF image src -> RST anonymous reference link to the PDF file.
-- The image alt-text (or the bare filename when alt is empty) is used as the
-- visible link label.
--
-- Handles both:
--   * Inline images inside Para elements
--   * Block images inside Figure elements (the Image node is reached in both
--     cases because Pandoc walks all Image elements regardless of context)
--
-- Placement in the filter chain:
--   Run after fix_internal_refs.lua and before number-sections.lua.

local function is_pdf(src)
    return src:match("%.[Pp][Dd][Ff]$") ~= nil
end

local function basename(path)
    return path:match("([^/\\]+)$") or path
end

-- Escape backticks in RST link label text to avoid breaking the reference syntax.
local function escape_rst_label(s)
    return s:gsub("`", "\\`")
end

function Image(el)
    if not is_pdf(el.src) then return end

    local alt = pandoc.utils.stringify(el.caption)
    if alt == "" then
        alt = basename(el.src)
    end

    -- Emit an RST anonymous reference so the PDF is reachable as a link.
    local rst = "`" .. escape_rst_label(alt) .. " <" .. el.src .. ">`__"
    return pandoc.RawInline("rst", rst)
end

return {
    { Image = Image }
}
