-- drop-empty-inline-shells.lua
-- Remove inline container elements that carry no visible content.
--
-- Empty containers arise from LaTeX constructs such as \emph{}, \textbf{},
-- or empty groupings left over from macro expansion.  They produce stray
-- whitespace or orphan punctuation in the rendered HTML output.
--
-- An element is treated as empty when its content list contains only Space,
-- SoftBreak, LineBreak, or whitespace-only Str nodes.
--
-- Handled element types:
--   Span, Emph, Strong, Strikeout, Superscript, Subscript, SmallCaps
--
-- Placement in the filter chain:
--   Run after fix_internal_refs.lua and before number-sections.lua.

local function is_whitespace_only(inlines)
    -- Note: %s in Lua patterns matches ASCII whitespace only (space, tab,
    -- newline, etc.).  Non-breaking spaces (U+00A0) and other Unicode
    -- whitespace are not caught; this is acceptable for IVOA standards content
    -- which is predominantly ASCII.
    for _, el in ipairs(inlines) do
        local t = el.tag
        if t == "Space" or t == "SoftBreak" or t == "LineBreak" then
            -- acceptable whitespace node
        elseif t == "Str" then
            if not el.text:match("^%s*$") then
                return false
            end
        else
            return false
        end
    end
    return true
end

local function drop_if_empty(el)
    if not el.content then return end
    if #el.content == 0 or is_whitespace_only(el.content) then
        return {}
    end
end

return {
    {
        Span        = drop_if_empty,
        Emph        = drop_if_empty,
        Strong      = drop_if_empty,
        Strikeout   = drop_if_empty,
        Superscript = drop_if_empty,
        Subscript   = drop_if_empty,
        SmallCaps   = drop_if_empty,
    }
}
