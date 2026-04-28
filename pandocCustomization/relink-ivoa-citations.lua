-- pandoc filter to convert citations into links
-- inspired by https://github.com/pandoc/lua-filters/blob/916ca389645940373d9a3c4beca3bd07d51b27aa/doi2cite/doi2cite.lua#L36

local io = require 'io'

local bibmap = {}
local doc_to_bib = {}
local docname

function Meta(m)
--  local mapfilepath = PANDOC_WRITER_OPTIONS.variables["bibmap"] -- this returns a Doc surprisingly... have to do via meta
    local mapfilepath = m["bibmap"]
    docname = pandoc.utils.stringify(m["DOCNAME"])
    local f = io.open(mapfilepath,"r")
    if f then
        for line in f:lines() do
            local mapped_docname, mapped_bibkey = line:match('^([%w%-_]+):%s*"([^"]+)"')
            if mapped_docname and mapped_bibkey then
                bibmap[mapped_bibkey] = mapped_docname
                doc_to_bib[mapped_docname] = mapped_bibkey
            end
        end
        f:close()
    else
        pandoc.log.error("cannot open " .. mapfilepath)
    end
end


function Cite(c)
    local outstring
    for _, v in ipairs(c.content) do -- FIXME really need to return table to match what is happening for multiple citation keys
        if (v.tag == "RawInline" and v.format == "latex") then
            local bibkey = v.text:match("{([^}]+)}")
            local std_docname = bibkey and bibkey:match("^std:([%w%-_]+)$")

            if std_docname and doc_to_bib[std_docname] then
                local citemode = v.text:match("\\cite([pt])")
                if citemode then
                    outstring = ":cite:" .. citemode .. ":`" .. doc_to_bib[std_docname] .. "`"
                else
                    outstring = ":cite:`" .. doc_to_bib[std_docname] .. "`"
                end
            elseif bibkey and bibmap[bibkey] then
                -- TODO - is this the best way to present?
                if(v.text:find("citep")) then
                    local citetext = "ref"
                    outstring = ":doc:`".. citetext .." <../" .. bibmap[bibkey] .. "/" .. bibmap[bibkey] ..">`"
                else
                    local citetext = bibmap[bibkey]
                    outstring = ":doc:`".. citetext .." <../" .. bibmap[bibkey] .. "/" .. bibmap[bibkey] ..">`"
                end
            else

                outstring = v.text:gsub("\\cite([pt]){([^}]+)}",":cite:%1:`%2`")
            end
--            pandoc.log.info("raw ".. v.text .. " -> " .. outstring)
        end
    end
    if outstring then
        return {pandoc.RawInline("rst",outstring)}
    end
    return c
end

return {
    {Meta = Meta},
    {Cite = Cite}
}