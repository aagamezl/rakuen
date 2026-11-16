-- Clipboard history (task 16.1): a bounded list of copied text, newest first.
-- Pure data, so it can be tested without hs.*.

local clipboard_history = {}
clipboard_history.__index = clipboard_history

local DEFAULT_LIMIT = 25
local PREVIEW_LENGTH = 80

--- Create an empty history that keeps at most `limit` entries.
function clipboard_history.new(limit)
  local max_entries = limit or DEFAULT_LIMIT
  assert(type(max_entries) == "number" and max_entries >= 1, "limit must be at least 1")

  return setmetatable({ limit = max_entries, entries = {} }, clipboard_history)
end

--- Add copied text. Blank text is ignored, and a repeat moves to the front.
--- Returns true when the history changed.
function clipboard_history:add(text)
  if type(text) ~= "string" or text:match("^%s*$") then
    return false
  end

  if self.entries[1] == text then
    return false
  end

  for index, entry in ipairs(self.entries) do
    if entry == text then
      table.remove(self.entries, index)
      break
    end
  end

  table.insert(self.entries, 1, text)

  while #self.entries > self.limit do
    table.remove(self.entries)
  end
  return true
end

--- Remove the entry equal to `text`. Returns true when one was removed.
function clipboard_history:remove(text)
  for index, entry in ipairs(self.entries) do
    if entry == text then
      table.remove(self.entries, index)
      return true
    end
  end
  return false
end

--- Entries, newest first.
function clipboard_history:list()
  return self.entries
end

--- Forget every entry.
function clipboard_history:clear()
  self.entries = {}
end

--- One-line label for an entry: whitespace collapsed, long text cut with "...".
function clipboard_history.preview(text)
  local single_line = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")

  if #single_line <= PREVIEW_LENGTH then
    return single_line
  end
  return single_line:sub(1, PREVIEW_LENGTH - 3) .. "..."
end

return clipboard_history
