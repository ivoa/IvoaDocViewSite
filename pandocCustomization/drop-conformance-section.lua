-- drop-conformance-section.lua
-- Remove the "Conformance-related definitions" boilerplate section that
-- appears in every IVOA standard.  This section is standard ivoatex
-- scaffolding (RFC 2119 keyword definitions) and is not useful as rendered
-- per-document prose on the multi-document site.
--
-- The section header is identified by a case-insensitive match on the words
-- "conformance" and "definition" appearing together in the header text.
-- All blocks that belong to the matched section (from its header up to, but
-- not including, the next header at the same or higher level) are dropped.
--
-- Placement in the filter chain:
--   Run before number-sections.lua so the header text has not yet been
--   prefixed with a section number.

local function is_conformance_header(header)
    local text = pandoc.utils.stringify(header.content):lower()
    return text:find("conformance") and text:find("definition")
end

function Pandoc(doc)
    local new_blocks = {}
    local skip       = false
    local skip_level = nil

    for _, block in ipairs(doc.blocks) do
        if block.tag == "Header" then
            if not skip and is_conformance_header(block) then
                -- Start skipping: record the section level so we know when
                -- a sibling or ancestor header ends the skipped region.
                skip       = true
                skip_level = block.level
            elseif skip and block.level <= skip_level then
                -- A header at the same or higher level (numerically <=) ends
                -- the conformance section; stop skipping and keep this block.
                skip       = false
                skip_level = nil
                new_blocks[#new_blocks + 1] = block
            elseif not skip then
                new_blocks[#new_blocks + 1] = block
            end
            -- (if skip and block.level > skip_level: a sub-section inside
            --  the conformance section – keep skipping, do nothing)
        elseif not skip then
            new_blocks[#new_blocks + 1] = block
        end
    end

    doc.blocks = pandoc.Blocks(new_blocks)
    return doc
end

return {
    { Pandoc = Pandoc }
}
