-- Generates docs/keybindings.md from the rules the modules register.
--
--   lua scripts/generate_docs.lua           write docs/keybindings.md
--   lua scripts/generate_docs.lua --check   fail when the file is out of date
--
-- Run from the repository root. Needs plain Lua 5.4, not Hammerspoon: a small
-- stand-in for the `hs` global lets the modules load.

package.path = "./?.lua;./?/init.lua;" .. package.path

local OUTPUT_PATH = "docs/keybindings.md"

local config = require("rakuen.core.config")
local docs = require("rakuen.core.docs")
local docs_data = require("scripts.docs_data")
local hs_mock = require("spec.helpers.hs_mock")
local loader = require("rakuen.core.loader")
local logger = require("rakuen.core.logger")
local registry = require("rakuen.core.registry")

--- Registry with every module enabled and block_native_cmd off (the default).
local function registered_rules()
  local settings = config.defaults()
  for _, module_name in ipairs(config.MODULE_NAMES) do
    settings.modules[module_name].enabled = true
  end

  hs_mock.install()
  local rules = registry.new()
  loader.load({ settings = settings, registry = rules, logger = logger.new("error") })
  hs_mock.uninstall()
  return rules:all()
end

local function read_file(path)
  local file = io.open(path, "r")
  if file == nil then
    return nil
  end
  local content = file:read("a")
  file:close()
  return content
end

local function main(arguments)
  local rules = registered_rules()

  local missing = docs.missing_gnome(rules, docs_data.gnome)
  if #missing > 0 then
    io.stderr:write("No GNOME chord in scripts/docs_data.lua for:\n  ")
    io.stderr:write(table.concat(missing, "\n  ") .. "\n")
    return 1
  end

  local text = docs.render(rules, docs_data)

  if arguments[1] == "--check" then
    if read_file(OUTPUT_PATH) ~= text then
      io.stderr:write(OUTPUT_PATH .. " is out of date. Run: make docs\n")
      return 1
    end
    print(OUTPUT_PATH .. " is up to date")
    return 0
  end

  local file = assert(io.open(OUTPUT_PATH, "w"))
  file:write(text)
  file:close()
  print("wrote " .. OUTPUT_PATH .. " (" .. #rules .. " rules)")
  return 0
end

os.exit(main({ ... }))
