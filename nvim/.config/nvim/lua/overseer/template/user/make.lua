-- ~/.config/nvim/lua/overseer/template/user/make.lua
-- Generates one task per target found in the project's Makefile,
-- plus a plain "make" task for the default target.

local overseer = require("overseer")

local function parse_targets(makefile)
  local targets = {}
  for line in io.lines(makefile) do
    -- "name: deps" but not "name := value", pattern rules (%...), or .PHONY etc.
    local target = line:match("^([%w][%w%-_./]*)%s*:[^=]")
    if target and not target:match("^%.") and not target:match("%%") then
      table.insert(targets, target)
    end
  end
  return targets
end

---@type overseer.TemplateFileProvider
return {
  generator = function(search, callback)
    local found = vim.fs.find({ "Makefile", "makefile" }, { upward = true, type = "file", path = search.dir })[1]
    if not found then
      callback("No Makefile found")
      return
    end

    local root = vim.fs.dirname(found)
    local ok, targets = pcall(parse_targets, found)
    if not ok then
      callback("Failed to parse Makefile")
      return
    end

    -- Warning params shared by every generated task. These are passed to `make`
    -- as command-line variable overrides, which `make` gives priority over
    -- plain `=`/`:=` assignments inside the Makefile itself (but NOT ones
    -- wrapped in `override CFLAGS := ...`).
    local warning_params = {
      warnings = {
        type = "boolean",
        default = true,
        desc = "Add -Wall -Wextra -g via CFLAGS/CXXFLAGS override",
      },
      werror = {
        type = "boolean",
        default = false,
        desc = "Also add -Werror (turns warnings into errors)",
      },
    }

    local function extra_args(params)
      if not params.warnings then
        return {}
      end
      local flags = "-Wall -Wextra -g" .. (params.werror and " -Werror" or "")
      return { "CFLAGS=" .. flags, "CXXFLAGS=" .. flags }
    end

    local templates = {
      {
        name = "make",
        params = warning_params,
        builder = function(params)
          local cmd = { "make" }
          vim.list_extend(cmd, extra_args(params))
          return { cmd = cmd, cwd = root, components = { "on_output_quickfix", "default" } }
        end,
        desc = "Run the default make target",
        tags = { overseer.TAG.BUILD },
      },
    }

    for _, target in ipairs(targets) do
      table.insert(templates, {
        name = "make " .. target,
        params = warning_params,
        builder = function(params)
          local cmd = { "make", target }
          vim.list_extend(cmd, extra_args(params))
          return { cmd = cmd, cwd = root, components = { "on_output_quickfix", "default" } }
        end,
        desc = "Run make target: " .. target,
        tags = { overseer.TAG.BUILD },
      })
    end

    callback(templates)
  end,
  condition = {
    filetype = { "c", "cpp", "make" },
  },
  cache_key = function(opts)
    return vim.fs.find({ "Makefile", "makefile" }, { upward = true, type = "file", path = opts.dir })[1]
  end,
}
