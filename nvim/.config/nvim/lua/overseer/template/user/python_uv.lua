-- ~/.config/nvim/lua/overseer/template/user/python_uv.lua
-- Provides: uv: run current file / uv: sync / uv: pytest
-- Project root = nearest pyproject.toml upward, falls back to cwd.

local overseer = require("overseer")

---@type overseer.TemplateFileProvider
return {
  generator = function(search, callback)
    local pyproject = vim.fs.find("pyproject.toml", { upward = true, type = "file", path = search.dir })[1]
    local root = pyproject and vim.fs.dirname(pyproject) or search.dir

    callback({
      {
        name = "uv: run current file",
        builder = function()
          return {
            cmd = { "uv", "run", vim.fn.expand("%:p") },
            cwd = root,
            components = { "default" },
          }
        end,
        desc = "Run the current file with `uv run`",
        tags = { overseer.TAG.RUN },
      },
      {
        name = "uv: sync",
        builder = function()
          return { cmd = { "uv", "sync" }, cwd = root, components = { "default" } }
        end,
        desc = "Install/sync dependencies from pyproject.toml / uv.lock",
        tags = { overseer.TAG.BUILD },
      },
      {
        name = "uv: pytest",
        builder = function()
          return { cmd = { "uv", "run", "pytest" }, cwd = root, components = { "on_output_quickfix", "default" } }
        end,
        desc = "Run the test suite with `uv run pytest`",
        tags = { overseer.TAG.TEST },
      },
    })
  end,
  condition = {
    filetype = { "python" },
  },
  cache_key = function(opts)
    return vim.fs.find("pyproject.toml", { upward = true, type = "file", path = opts.dir })[1] or opts.dir
  end,
}
