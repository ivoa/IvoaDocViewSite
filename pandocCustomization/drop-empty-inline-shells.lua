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
    -- newline, etc.).  Unicode whitespace (e.g., U+00A0 non-breaking space)
    -- will not be treated as empty, so a Span containing only a non-breaking
    -- space will be kept rather than dropped.  This is acceptable for current
    -- IVOA standards content; add a UTF-8 check here if Unicode-only whitespace
    -- containers become a problem in the future.
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
