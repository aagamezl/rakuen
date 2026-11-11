-- Module loader: registers the rules of every enabled module.
--
-- A module file under rakuen/modules/ returns { rules = { ... } }.
-- A module may also return `block_rules`: rules that swallow the native chords
-- its own rules replace. They are registered only when `block_native_cmd` is on.
-- A module may also return `on_load(logger)`, run once after its rules are
-- registered (for startup checks); an error there never stops loading.
-- Setting `only` in the config loads one module alone, so it can be tested
-- without the others (task 3.2).

local config = require("rakuen.core.config")

local loader = {}

local MODULE_PATH_PREFIX = "rakuen.modules."

--- Register the rules of each enabled module into `registry`.
--- options: settings (merged config), registry, logger.
--- options.require_module (optional) replaces `require`, for tests.
--- Returns the list of module names that were loaded.
function loader.load(options)
  local settings = options.settings
  local registry = options.registry
  local logger = options.logger
  local require_module = options.require_module or require

  local loaded = {}

  for _, module_name in ipairs(config.MODULE_NAMES) do
    if config.is_module_enabled(settings, module_name) then
      local module = require_module(MODULE_PATH_PREFIX .. module_name)
      assert(type(module.rules) == "table", module_name .. " must return { rules = { ... } }")

      local bindings = settings.modules[module_name].bindings
      for _, description in ipairs(config.unknown_bindings(module.rules, bindings)) do
        logger:warn(string.format("config: %s has no binding '%s'", module_name, description))
      end

      registry:add_all(module_name, config.apply_overrides(module.rules, bindings))

      if settings.block_native_cmd and type(module.block_rules) == "table" then
        registry:add_all(module_name, module.block_rules)
      end
      table.insert(loaded, module_name)

      if type(module.on_load) == "function" then
        local ok, load_error = pcall(module.on_load, logger)
        if not ok then
          logger:warn(string.format("%s on_load failed: %s", module_name, tostring(load_error)))
        end
      end
    end
  end

  return loaded
end

return loader
