-- sanitize-raw-inline.lua
-- Strip or convert residual LaTeX control sequences that survive pandoc's
-- latex+raw_tex pass as RawInline("latex", ...) nodes.
--
-- Placement in the filter chain:
--   Run AFTER fix_internal_refs.lua so that \ref{} and \label{} have already
--   been converted to RST and will not be seen here.
--
-- Policy:
--   * Whitespace/layout commands  -> removed (return {})
--   * Known text-expansion macros -> literal text
--   * \index{...}, \phantom{...}  -> removed
--   * \hspace{...}, \vspace{...}  -> removed
--   * \url{...}                   -> RST anonymous hyperlink
--   * \href{url}{text}            -> RST anonymous hyperlink
--   * Anything else               -> left unchanged (preserve unknown macros)

-- Commands that produce no visible output and should be silently dropped.
local DROP_COMMANDS = {
    ["\\noindent"]   = true,
    ["\\par"]        = true,
    ["\\clearpage"]  = true,
    ["\\newpage"]    = true,
    ["\\linebreak"]  = true,
    ["\\hfill"]      = true,
    ["\\vfill"]      = true,
    ["\\newline"]    = true,
    ["\\centering"]  = true,
    ["\\raggedright"]= true,
    ["\\raggedleft"] = true,
    ["\\null"]       = true,
    ["\\relax"]      = true,
    ["\\-"]          = true,
}

-- Commands that expand to a fixed literal string.
local EXPAND_COMMANDS = {
    ["\\TeX"]          = "TeX",
    ["\\LaTeX"]        = "LaTeX",
    ["\\BibTeX"]       = "BibTeX",
    ["\\textbackslash"]= "\\",
    ["\\ldots"]        = "\226\128\166",  -- U+2026 HORIZONTAL ELLIPSIS
    ["\\dots"]         = "\226\128\166",  -- U+2026 HORIZONTAL ELLIPSIS
    ["\\lq"]           = "\226\128\152",  -- U+2018 LEFT SINGLE QUOTATION MARK
    ["\\rq"]           = "\226\128\153",  -- U+2019 RIGHT SINGLE QUOTATION MARK
}

function RawInline(el)
    if el.format ~= "latex" then return end
    local text = el.text

    -- 1. Drop pure layout/whitespace macros (bare command, optional trailing *)
    local cmd = text:match("^(\\%a+)%*?%s*$") or text:match("^(\\%-)$")
    if cmd and DROP_COMMANDS[cmd] then
        return {}
    end

    -- 2. Text-expansion macros (bare, possibly followed by {} or whitespace)
    -- The third pattern intentionally omits an end-anchor so that a macro
    -- immediately followed by punctuation (e.g. "\LaTeX.") is still matched;
    -- the suffix is preserved and appended to the expansion below.
    local bare = text:match("^(\\%a+)%s*%{%}$")
              or text:match("^(\\%a+)%s*$")
              or text:match("^(\\%a+)[%s%p]")
    if bare and EXPAND_COMMANDS[bare] then
        local suffix = text:sub(#bare + 1)
        local expansion = EXPAND_COMMANDS[bare]
        -- Drop trailing {} or whitespace (TeX swallows a space after control words)
        if suffix == "" or suffix:match("^%{%}") or suffix:match("^%s") then
            return pandoc.Str(expansion)
        end
        return pandoc.Str(expansion .. suffix)
    end

    -- 3. \index{...} and \phantom{...} – drop silently (no visible output)
    if text:match("^\\index%s*%{") or text:match("^\\phantom%s*%{") then
        return {}
    end

    -- 4. \hspace{...} / \vspace{...} (with or without *)
    if text:match("^\\[hv]space%*?%s*%{") then
        return {}
    end

    -- 5. \url{...} -> RST anonymous hyperlink
    -- Note: [^}]+ does not handle percent-encoded closing braces (%7D); this
    -- is an accepted limitation since IVOA standard sources use plain URLs.
    local url = text:match("^\\url%s*%{([^}]+)%}$")
    if url then
        return pandoc.RawInline("rst", "`" .. url .. " <" .. url .. ">`__")
    end

    -- 6. \href{url}{text} -> RST anonymous hyperlink
    -- Note: [^}]+ does not handle nested braces; accepted limitation for
    -- standard IVOA source conventions.
    local href_url, href_text = text:match("^\\href%s*%{([^}]+)%}%s*%{([^}]*)%}$")
    if href_url then
        if href_text == "" then href_text = href_url end
        return pandoc.RawInline("rst", "`" .. href_text .. " <" .. href_url .. ">`__")
    end

    -- Everything else: leave unchanged so unknown macros are preserved
end

return {
    { RawInline = RawInline }
}
