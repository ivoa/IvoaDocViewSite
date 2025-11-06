-- pandoc filter to convert citations into links
-- inspired by https://github.com/pandoc/lua-filters/blob/916ca389645940373d9a3c4beca3bd07d51b27aa/doi2cite/doi2cite.lua#L36

local io = require 'io'

local bibmap = {}
local docname

function Meta(m)
--  local mapfilepath = PANDOC_WRITER_OPTIONS.variables["bibmap"] -- this returns a Doc surprisingly... have to do via meta
    local mapfilepath = m["bibmap"]
    docname = m["DOCNAME"]
    f = io.open(mapfilepath,"r")
    if f then
        for line in f:lines() do
            bibmap[line:match('"([^"]+)"')] = line:match("^%a+")
        end
    else
        pandoc.log.error("cannot open " .. mapfilepath)
    end
end


function Cite(c)
    for _, v in ipairs(c.content) do -- FIXME really need to return table to match what is happening for multiple citation keys
        if (v.tag == "RawInline" and v.format == "latex") then
            bibkey = v.text:match("{([^}]+)}")
            if bibmap[bibkey] then
                -- TODO - is this the best way to present?
                if(v.text:find("citep")) then
                    citetext = "ref"
                else
                    citetext = bibmap[bibkey]
                end
                outstring = ":doc:`".. citetext .." <../" .. bibmap[bibkey] .. "/" .. bibmap[bibkey] ..">`"
            else
                outstring = v.text:gsub("\\cite([pt]){([^}]+)}",":cite:%1:`%2`")
            end
            pandoc.log.info("raw ".. v.text .. " -> " .. outstring)
        end
    end
    return {pandoc.RawInline("rst",outstring)}
end

return {
    {Meta = Meta},
    {Cite = Cite}
}