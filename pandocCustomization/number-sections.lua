--
-- A Pandoc Lua filter to number section headings in a hierarchical
-- format (e.g., 1, 1.1, 1.1.1).
--
-- By default, it numbers all header levels (1-6).
--
-- It switches to alphabetical top-level numbering (A, B, C...)
-- when it encounters a level 1 header that starts with "Appendix".
--
-- You can control the depth by setting a metadata field
-- in your document's YAML front matter:
-- ---
-- number-sections-depth: 3
-- ---
--
-- Headings with the class "unnumbered" will be skipped.

-- Global table to store counters for each header level
local counters = {0, 0, 0, 0, 0, 0}

-- Global variable for max depth, defaults to 6
local max_depth = 6

-- Global flag to track if we are in appendix mode
local in_appendix_mode = false

-- Helper function to convert a number (1-26) to an uppercase letter (A-Z)
local function num_to_alpha(n)
  if n >= 1 and n <= 26 then
    -- 'A' is 65. (1-1)+65=A, (2-1)+65=B, etc.
    return string.char(string.byte('A') + n - 1)
  else
    return n -- Fallback for numbers > 26 or < 1
  end
end

-- This function runs once on the document's metadata
-- to check for the 'number-sections-depth' setting.
function Meta(meta)
    if meta['number-sections-depth'] then
        -- Get the string value from the metadata
        local depth_str = pandoc.utils.stringify(meta['number-sections-depth'])
        -- Convert it to a number
        local depth_num = tonumber(depth_str)

        -- If it's a valid number, update max_depth
        if depth_num and depth_num > 0 then
            max_depth = depth_num
        end
    else
        -- default
        max_depth = 3
    end
end

-- This function runs on every Header element in the document
function Header(el)
  -- Check if the header has the 'unnumbered' class
  if el.classes:includes("unnumbered") then
    return el -- Return the element unmodified
  end

  local level = el.level

  -- Check if the header's level is within the specified depth
  if level > max_depth then
    return el -- Return the element unmodified
  end

  -- NEW: Check for Appendix trigger (before incrementing)
  -- If we're not already in appendix mode and this is an H1
  if not in_appendix_mode and level == 1 then
    -- Convert header content to a plain string
    local header_text = pandoc.utils.stringify(el.content)
    -- Check if it starts with "appendix" (case-insensitive)
    if header_text:lower():match("^appendix") then -- FIXME this is not the condition to go into appendix mode
      in_appendix_mode = true
      -- Reset all counters to start appendix numbering (e.g., A, B, C...)
      for i = 1, 6 do
        counters[i] = 0
      end
    end
  end

  -- 3. Increment the counter for the current header level
  counters[level] = counters[level] + 1

  -- 4. Reset all counters for deeper levels
  for i = level + 1, 6 do
    counters[i] = 0
  end

  -- Build the number string (e.g., "1.2.3" or "A.1.2")
  local num_parts = {}
  for i = 1, level do
    -- Check if we are at the first level AND in appendix mode
    if i == 1 and in_appendix_mode then
      table.insert(num_parts, num_to_alpha(counters[i]))
    else
      table.insert(num_parts, counters[i])
    end
  end
  local num_string = table.concat(num_parts, ".")

  -- Create the new inline elements to prepend
  -- (The number string, followed by a space)
  local prefix = {
    pandoc.Str(num_string),
    pandoc.Space()
  }

  --  Insert the prefix at the beginning of the header's content
  -- (We iterate backwards to insert at index 1)
  for i = #prefix, 1, -1 do
    el.content:insert(1, prefix[i])
  end

  -- Return the modified header element
  return el
end

-- Tell Pandoc which filters to run.
-- We run Meta first to get the max_depth, then Header.
return {
  {Meta = Meta},
  {Header = Header}
}
