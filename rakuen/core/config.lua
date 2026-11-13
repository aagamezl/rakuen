-- Rakuen configuration: safe defaults plus an optional user file.
--
-- The user file lives outside the repo at ~/.config/rakuen/config.lua and
-- returns a table. Every key is optional:
--
--   return {
--     mode = "match",                 -- "log" (default) or "match"
--     log_level = "info",             -- debug | info | warn | error
--     only = "editing",               -- enable just this module, ignore the rest
--     block_native_cmd = false,       -- swallow the native Cmd chords Rakuen replaces
--     modules = {
--       editing = {
--         enabled = true,
--         bindings = {
--           -- keyed by the rule's description
--           Copy = { applications = { disable = { "com.apple.Terminal" } } },
--           Bold = { enabled = false },
--         },
--       },
--     },
--   }

local config = {}

config.MODULE_NAMES = {
  "editing",
  "text_navigation",
  "windows",
  "focus",
  "workspaces",
  "applications",
  "shell",
  "session",
}

local VALID_MODES = { log = true, match = true }
local VALID_LOG_LEVELS = { debug = true, info = true, warn = true, error = true }
local TOP_LEVEL_KEYS = {
  mode = true,
  log_level = true,
  only = true,
  block_native_cmd = true,
  modules = true,
}
local MODULE_KEYS = { enabled = true, bindings = true }
local BINDING_KEYS = { enabled = true, applications = true }

local function is_module_name(name)
  for _, known in ipairs(config.MODULE_NAMES) do
    if known == name then
      return true
    end
  end
  return false
end

local function reject_unknown_keys(table_value, allowed, context)
  for key in pairs(table_value) do
    assert(allowed[key], "unknown config key '" .. tostring(key) .. "' in " .. context)
  end
end

local function validate_bindings(bindings, module_name)
  assert(type(bindings) == "table", module_name .. ".bindings must be a table")

  for description, override in pairs(bindings) do
    local context = module_name .. ".bindings." .. tostring(description)
    assert(type(override) == "table", context .. " must be a table")
    reject_unknown_keys(override, BINDING_KEYS, context)

    if override.enabled ~= nil then
      assert(type(override.enabled) == "boolean", context .. ".enabled must be a boolean")
    end
    if override.applications ~= nil then
      assert(type(override.applications) == "table", context .. ".applications must be a table")
    end
  end
end

local function validate_modules(modules)
  assert(type(modules) == "table", "modules must be a table")

  for module_name, module_config in pairs(modules) do
    assert(is_module_name(module_name), "unknown module '" .. tostring(module_name) .. "'")
    assert(type(module_config) == "table", "modules." .. module_name .. " must be a table")
    reject_unknown_keys(module_config, MODULE_KEYS, "modules." .. module_name)

    if module_config.enabled ~= nil then
      assert(
        type(module_config.enabled) == "boolean",
        "modules." .. module_name .. ".enabled must be a boolean"
      )
    end
    if module_config.bindings ~= nil then
      validate_bindings(module_config.bindings, "modules." .. module_name)
    end
  end
end

--- Return the default configuration: log mode, native Cmd chords untouched (D3),
--- every module disabled.
function config.defaults()
  local modules = {}
  for _, name in ipairs(config.MODULE_NAMES) do
    modules[name] = { enabled = false, bindings = {} }
  end

  return {
    mode = "log",
    log_level = "info",
    only = nil,
    block_native_cmd = false,
    modules = modules,
  }
end

--- Validate a user config table and merge it over the defaults.
--- Raises an error describing the first problem found.
function config.merge(user)
  assert(type(user) == "table", "config must be a table")
  reject_unknown_keys(user, TOP_LEVEL_KEYS, "config")

  local merged = config.defaults()

  if user.mode ~= nil then
    assert(VALID_MODES[user.mode], "mode must be 'log' or 'match'")
    merged.mode = user.mode
  end

  if user.log_level ~= nil then
    assert(VALID_LOG_LEVELS[user.log_level], "log_level must be debug, info, warn or error")
    merged.log_level = user.log_level
  end

  if user.only ~= nil then
    assert(is_module_name(user.only), "only must name a known module")
    merged.only = user.only
  end

  if user.block_native_cmd ~= nil then
    assert(type(user.block_native_cmd) == "boolean", "block_native_cmd must be a boolean")
    merged.block_native_cmd = user.block_native_cmd
  end

  if user.modules ~= nil then
    validate_modules(user.modules)
    for module_name, module_config in pairs(user.modules) do
      if module_config.enabled ~= nil then
        merged.modules[module_name].enabled = module_config.enabled
      end
      if module_config.bindings ~= nil then
        merged.modules[module_name].bindings = module_config.bindings
      end
    end
  end

  return merged
end

--- Load and merge the config file at `path`.
--- Returns the merged config and nil, or the defaults and an error message when
--- the file has a problem. A missing file is not an error.
function config.load(path)
  local chunk, load_error = loadfile(path)
  if chunk == nil then
    if load_error ~= nil and load_error:find("cannot open", 1, true) then
      return config.defaults(), nil
    end
    return config.defaults(), load_error
  end

  local succeeded, user = pcall(chunk)
  if not succeeded then
    return config.defaults(), tostring(user)
  end

  local merged_ok, merged = pcall(config.merge, user)
  if not merged_ok then
    return config.defaults(), tostring(merged)
  end

  return merged, nil
end

--- Return true when `module_name` should be loaded under `settings`.
--- When `only` is set, just that module is enabled, whatever its flag says.
function config.is_module_enabled(settings, module_name)
  if settings.only ~= nil then
    return settings.only == module_name
  end
  return settings.modules[module_name].enabled
end

--- Apply per-binding overrides to a module's rules.
--- Returns new rule tables; a binding with enabled = false is dropped, and a
--- binding with `applications` replaces the rule's own filter.
function config.apply_overrides(rules, bindings)
  local result = {}

  for _, rule in ipairs(rules) do
    local override = bindings[rule.description]

    if override == nil then
      table.insert(result, rule)
    elseif override.enabled ~= false then
      local copy = {}
      for field, value in pairs(rule) do
        copy[field] = value
      end
      if override.applications ~= nil then
        copy.applications = override.applications
      end
      table.insert(result, copy)
    end
  end

  return result
end

--- Return the binding names in `bindings` that match no rule, sorted.
--- Used to warn about typos in the user config.
function config.unknown_bindings(rules, bindings)
  local known = {}
  for _, rule in ipairs(rules) do
    known[rule.description] = true
  end

  local unknown = {}
  for description in pairs(bindings) do
    if not known[description] then
      table.insert(unknown, description)
    end
  end

  table.sort(unknown)
  return unknown
end

return config
