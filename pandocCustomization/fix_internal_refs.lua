
-- make sure that internal references are unique globally bt prefixing docname

--

local docname

function Meta(m)
    docname = pandoc.utils.stringify(m["DOCNAME"])
end


function RawInline(r) -- this fixes up refs

    if(r.format == "latex" and r.text:find("^\\ref{")) then
        ref = r.text:match("{([^}]+)}")
        if (ref) then
            outstring = ":ref:`".. docname .. ":" .. ref .."`"
            return {pandoc.RawInline("rst",outstring)}
        end
    end
end

function Header(h) -- headers will already have ID from the latex processing
    if(h.identifier) then
      h.identifier = docname .. ":" .. h.identifier
      return {h}
    end
end

-- TODO equations  etc.??

return {
    {Meta = Meta},
    {RawInline = RawInline},
    {Header = Header},
    {Figure = Header}
}