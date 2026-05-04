require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- Native vim.pack adapter for the existing lazy.nvim-style plugin specs.
--
-- This file lets us switch between lazy.nvim and Neovim's built-in
-- vim.pack without duplicating the plugin list. It reads lua/plugins/init.lua,
-- converts each lazy.nvim-style spec into a vim.pack spec, installs the
-- plugins with vim.pack.add(), and then emulates the most important lazy.nvim
-- behavior manually:
--
--   - dependencies
--   - opts / config = true / config = function()
--   - lazy = false eager loading
--   - event, ft, cmd, and keys lazy triggers
--   - build hooks through PackChanged
--   - lazy.nvim's VeryLazy event via User VeryLazy
--
-- This is intentionally a compatibility layer, not a full lazy.nvim clone.
-- Some lazy.nvim features are only approximated or ignored.
-- Note: I ended up replacing this with another pack_plugins.lua that's more 
-- in line with vim.pack...

local plugin_specs = require("plugins")

local M = {}

M._configured = {}
M._loaded = {}

local function notify(msg, level)
  vim.notify("[pack_plugins] " .. msg, level or vim.log.levels.INFO)
end

local function is_plugin_spec(t)
  return type(t) == "table" and type(t[1]) == "string"
end

local function is_list(t)
  if type(t) ~= "table" then
    return false
  end

  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      return false
    end
  end

  return true
end

local function plugin_name_from_repo(repo)
  local name = repo:match("/([^/]+)$") or repo
  name = name:gsub("%.git$", "")
  return name
end

local function repo_to_src(repo)
  if repo:match("^https?://") or repo:match("^git@") then
    return repo
  end

  return "https://github.com/" .. repo
end

local function lazy_version_to_pack_version(spec)
  if spec.branch then
    return spec.branch
  end

  if spec.tag then
    return spec.tag
  end

  if spec.commit then
    return spec.commit
  end

  -- lazy.nvim's version="*" means latest semver release.
  -- This adapter does not emulate that exactly.
  -- Omit it and let vim.pack use default branch / lockfile behavior.
  if spec.version == false or spec.version == "*" then
    return nil
  end

  if type(spec.version) == "string" then
    return spec.version
  end

  return nil
end

local function flatten_lazy_specs(specs, out, seen)
  out = out or {}
  seen = seen or {}

  for _, spec in ipairs(specs) do
    if type(spec) == "string" then
      spec = { spec }
    end

    if type(spec) == "table" then
      if is_plugin_spec(spec) then
        local repo = spec[1]

        if not seen[repo] then
          seen[repo] = true

          if type(spec.dependencies) == "table" then
            flatten_lazy_specs(spec.dependencies, out, seen)
          elseif type(spec.dependencies) == "string" then
            flatten_lazy_specs({ spec.dependencies }, out, seen)
          end

          table.insert(out, spec)
        end
      elseif is_list(spec) then
        flatten_lazy_specs(spec, out, seen)
      end
    end
  end

  return out
end

local function to_pack_spec(spec)
  local repo = spec[1]
  local src = repo_to_src(repo)
  local name = spec.name or plugin_name_from_repo(repo)
  local version = lazy_version_to_pack_version(spec)

  local pack_spec = {
    src = src,
    name = name,
  }

  if version then
    pack_spec.version = version
  end

  return pack_spec
end

local function normalize_spec_name(spec)
  return spec.name or plugin_name_from_repo(spec[1])
end

local function packadd_spec(spec)
  local name = normalize_spec_name(spec)

  if M._loaded[name] then
    return
  end

  local ok, err = pcall(vim.cmd.packadd, name)

  if not ok then
    notify("packadd failed for " .. name .. ": " .. tostring(err), vim.log.levels.WARN)
  end

  M._loaded[name] = true
end

local function get_main_module_candidates(spec)
  if spec.main then
    return { spec.main }
  end

  local repo_name = plugin_name_from_repo(spec[1])
  local candidates = {}

  local function add(v)
    if v and v ~= "" then
      table.insert(candidates, v)
    end
  end

  -- Exact repo/plugin directory name.
  add(repo_name)

  -- Common lazy.nvim-ish guesses.
  add(repo_name:gsub("%.nvim$", ""))
  add(repo_name:gsub("%.lua$", ""))
  add(repo_name:gsub("^nvim%-", ""))
  add(repo_name:gsub("^vim%-", ""))

  -- Common explicit module mappings.
  local explicit = {
    ["Comment.nvim"] = "Comment",
    ["actions-preview.nvim"] = "actions-preview",
    ["avante.nvim"] = "avante",
    ["blink.cmp"] = "blink.cmp",
    ["diffview.nvim"] = "diffview",
    ["fzf-lua"] = "fzf-lua",
    ["gen.nvim"] = "gen",
    ["gitgraph.nvim"] = "gitgraph",
    ["gp.nvim"] = "gp",
    ["image_preview.nvim"] = "image_preview",
    ["lualine.nvim"] = "lualine",
    ["model.nvim"] = "model",
    ["nvim-colorizer.lua"] = "colorizer",
    ["nvim-lspconfig"] = "lspconfig",
    ["nvim-treesitter"] = "nvim-treesitter.configs",
    ["oil.nvim"] = "oil",
    ["roslyn.nvim"] = "roslyn",
    ["telescope.nvim"] = "telescope",
    ["treesj"] = "treesj",
    ["treewalker.nvim"] = "treewalker",
    ["trouble.nvim"] = "trouble",
    ["undotree"] = "undotree",
  }

  add(explicit[repo_name])

  -- De-duplicate while preserving order.
  local out = {}
  local seen = {}

  for _, candidate in ipairs(candidates) do
    if not seen[candidate] then
      seen[candidate] = true
      table.insert(out, candidate)
    end
  end

  return out
end

local function require_first_available(spec)
  local errors = {}

  for _, module_name in ipairs(get_main_module_candidates(spec)) do
    local ok, mod = pcall(require, module_name)

    if ok then
      return mod, module_name
    end

    table.insert(errors, module_name .. ": " .. tostring(mod))
  end

  return nil, nil, errors
end

local function run_setup_with_opts(spec)
  local mod, module_name, errors = require_first_available(spec)

  if not mod then
    notify(
      "could not find setup module for " .. tostring(spec[1]) .. "\n" .. table.concat(errors or {}, "\n"),
      vim.log.levels.WARN
    )
    return
  end

  if type(mod.setup) ~= "function" then
    notify(
      "module " .. module_name .. " for " .. tostring(spec[1]) .. " has no setup()",
      vim.log.levels.WARN
    )
    return
  end

  local ok, err = pcall(mod.setup, spec.opts or {})

  if not ok then
    notify(
      "setup failed for " .. tostring(spec[1]) .. " using module " .. module_name .. ":\n" .. tostring(err),
      vim.log.levels.ERROR
    )
  end
end

function M.configure_spec(spec)
  local name = normalize_spec_name(spec)

  if M._configured[name] then
    return
  end

  M._configured[name] = true

  if type(spec.config) == "function" then
    local ok, err = pcall(spec.config)

    if not ok then
      notify(
        "config failed for " .. tostring(spec[1]) .. ":\n" .. tostring(err),
        vim.log.levels.ERROR
      )
    end

    return
  end

  if spec.config == true or spec.opts ~= nil then
    run_setup_with_opts(spec)
  end
end

local function as_list(value)
  if value == nil then
    return {}
  end

  if type(value) == "table" then
    return value
  end

  return { value }
end

local function apply_keys(spec)
  if type(spec.keys) ~= "table" then
    return
  end

  for _, key_spec in ipairs(spec.keys) do
    if type(key_spec) == "string" then
      -- lazy.nvim supports plain string keys as lazy-load triggers.
      -- There is no RHS to map here.
    elseif type(key_spec) == "table" then
      local lhs = key_spec[1]
      local rhs = key_spec[2]
      local mode = key_spec.mode or "n"

      if lhs and rhs then
        local opts = {
          noremap = key_spec.noremap ~= false,
          silent = key_spec.silent ~= false,
          expr = key_spec.expr,
          desc = key_spec.desc,
        }

        vim.keymap.set(mode, lhs, function(...)
          packadd_spec(spec)
          M.configure_spec(spec)

          if type(rhs) == "function" then
            return rhs(...)
          end

          if type(rhs) == "string" then
            local keys = vim.api.nvim_replace_termcodes(rhs, true, false, true)
            vim.api.nvim_feedkeys(keys, "m", false)
          end
        end, opts)
      elseif lhs then
        -- If there is only a lhs, use it as a load trigger.
        vim.keymap.set(mode, lhs, function()
          packadd_spec(spec)
          M.configure_spec(spec)
        end, {
          noremap = true,
          silent = true,
          desc = key_spec.desc,
        })
      end
    end
  end
end

local function split_event(event_name)
  if type(event_name) ~= "string" then
    return nil, nil
  end

  -- Supports:
  --   "BufReadPost"
  --   "BufReadPost *.lua"
  --   "User VeryLazy"
  local event, pattern = event_name:match("^(%S+)%s+(.+)$")

  if event then
    return event, pattern
  end

  return event_name, nil
end

local function is_user_event_name(event_name)
  -- lazy.nvim convenience event.
  -- Native nvim_create_autocmd does not accept "VeryLazy" directly.
  return event_name == "VeryLazy"
end

local function setup_event_loader(spec)
  for _, raw_event_name in ipairs(as_list(spec.event)) do
    local event_name, pattern = split_event(raw_event_name)

    if event_name then
      if is_user_event_name(event_name) then
        vim.api.nvim_create_autocmd("User", {
          pattern = event_name,
          once = true,
          callback = function()
            packadd_spec(spec)
            M.configure_spec(spec)
          end,
        })
      else
        local opts = {
          once = true,
          callback = function()
            packadd_spec(spec)
            M.configure_spec(spec)
          end,
        }

        if pattern then
          opts.pattern = pattern
        end

        local ok, err = pcall(vim.api.nvim_create_autocmd, event_name, opts)

        if not ok then
          notify(
            "invalid event for " .. tostring(spec[1]) .. ": " .. tostring(raw_event_name) .. "\n" .. tostring(err),
            vim.log.levels.ERROR
          )
        end
      end
    end
  end
end

local function setup_ft_loader(spec)
  for _, ft in ipairs(as_list(spec.ft)) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      once = false,
      callback = function()
        packadd_spec(spec)
        M.configure_spec(spec)
      end,
    })
  end
end

local function setup_cmd_loader(spec)
  for _, cmd_name in ipairs(as_list(spec.cmd)) do
    if type(cmd_name) == "string" and cmd_name ~= "" then
      vim.api.nvim_create_user_command(cmd_name, function(args)
        packadd_spec(spec)
        M.configure_spec(spec)

        -- Re-run the command after loading the plugin.
        -- Delete our temporary loader command first so the plugin command can run.
        pcall(vim.api.nvim_del_user_command, cmd_name)

        local bang = args.bang and "!" or ""
        local range = ""

        if args.range and args.range > 0 then
          range = tostring(args.line1) .. "," .. tostring(args.line2)
        end

        local command = range .. cmd_name .. bang

        if args.args and args.args ~= "" then
          command = command .. " " .. args.args
        end

        vim.cmd(command)
      end, {
        bang = true,
        nargs = "*",
        range = true,
        complete = "file",
      })
    end
  end
end

local function setup_lazy_triggers(spec)
  if spec.event then
    setup_event_loader(spec)
  end

  if spec.ft then
    setup_ft_loader(spec)
  end

  if spec.cmd then
    setup_cmd_loader(spec)
  end

  if spec.keys then
    apply_keys(spec)
  end
end

local function has_lazy_trigger(spec)
  -- Important:
  -- lazy=false means configure immediately, even if the spec contains keys,
  -- opts, or other fields.
  if spec.lazy == false then
    return false
  end

  return spec.event ~= nil or spec.ft ~= nil or spec.cmd ~= nil or spec.keys ~= nil
end

local function collect_build_hooks(specs)
  local hooks = {}

  for _, spec in ipairs(specs) do
    if type(spec) == "table" and is_plugin_spec(spec) and spec.build then
      local name = normalize_spec_name(spec)
      hooks[name] = spec.build
    end
  end

  return hooks
end

local function run_build(build, path)
  if type(build) == "function" then
    local ok, err = pcall(build)

    if not ok then
      notify("build function failed: " .. tostring(err), vim.log.levels.ERROR)
    end

    return
  end

  if type(build) ~= "string" then
    return
  end

  if build:sub(1, 1) == ":" then
    local cmd = build:sub(2)
    local ok, err = pcall(vim.cmd, cmd)

    if not ok then
      notify("build command failed: " .. build .. "\n" .. tostring(err), vim.log.levels.ERROR)
    end

    return
  end

  vim.system(vim.split(build, " "), { cwd = path }, function(obj)
    if obj.code ~= 0 then
      vim.schedule(function()
        notify("build failed: " .. build .. "\n" .. tostring(obj.stderr), vim.log.levels.ERROR)
      end)
    end
  end)
end

local function setup_build_hooks(build_hooks)
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local data = ev.data or {}
      local spec = data.spec or {}
      local name = spec.name
      local kind = data.kind

      if kind ~= "install" and kind ~= "update" then
        return
      end

      local build = build_hooks[name]

      if build then
        run_build(build, data.path)
      end
    end,
  })
end

local function fire_very_lazy()
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
      end)
    end,
  })
end

function M.setup()
  if not vim.pack then
    error("vim.pack is not available. Use Neovim with vim.pack support, or set USE_LAZY = true.")
  end

  local flat_specs = flatten_lazy_specs(plugin_specs)
  local pack_specs = {}

  for _, spec in ipairs(flat_specs) do
    table.insert(pack_specs, to_pack_spec(spec))
  end

  local build_hooks = collect_build_hooks(flat_specs)
  setup_build_hooks(build_hooks)

  -- Install plugins, but do not load all immediately.
  -- We emulate lazy-style loading below.
  vim.pack.add(pack_specs, {
    confirm = false,
    load = false,
  })

  fire_very_lazy()

  for _, spec in ipairs(flat_specs) do
    if has_lazy_trigger(spec) then
      setup_lazy_triggers(spec)
    else
      packadd_spec(spec)
      M.configure_spec(spec)
    end
  end
end

M.setup()
