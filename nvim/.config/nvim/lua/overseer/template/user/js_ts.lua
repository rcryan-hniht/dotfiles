-- ~/.config/nvim/lua/overseer/template/user/js_ts.lua
-- Provides:
--   "bun: run current file"  -> runs .js/.ts directly, no build/transpile step
--   "<pm>: install"          -> install deps with whichever package manager the lockfile indicates
--   "<pm> run <script>"      -> one task per script in package.json
--
-- Requires the `bun` binary for running files directly. Install: https://bun.sh

local overseer = require("overseer")

local function detect_pm(root)
  if vim.fn.filereadable(root .. "/bun.lockb") == 1 or vim.fn.filereadable(root .. "/bun.lock") == 1 then
    return "bun"
  elseif vim.fn.filereadable(root .. "/pnpm-lock.yaml") == 1 then
    return "pnpm"
  elseif vim.fn.filereadable(root .. "/yarn.lock") == 1 then
    return "yarn"
  else
    return "npm"
  end
end

---@type overseer.TemplateFileProvider
return {
  generator = function(search, callback)
    local pkg = vim.fs.find("package.json", { upward = true, type = "file", path = search.dir })[1]
    local root = pkg and vim.fs.dirname(pkg) or search.dir
    local pm = detect_pm(root)

    local templates = {
      {
        name = "bun: run current file",
        builder = function()
          return {
            cmd = { "bun", "run", vim.fn.expand("%:p") },
            cwd = root,
            components = { "default" },
          }
        end,
        desc = "Run the current .js/.ts file directly with Bun",
        tags = { overseer.TAG.RUN },
        condition = { filetype = { "javascript", "typescript" } },
      },
      {
        name = pm .. ": install",
        builder = function()
          return { cmd = { pm, "install" }, cwd = root, components = { "default" } }
        end,
        desc = "Install dependencies with " .. pm,
        tags = { overseer.TAG.BUILD },
      },
    }

    if pkg then
      local ok_read, lines = pcall(vim.fn.readfile, pkg)
      if ok_read then
        local ok_json, data = pcall(vim.json.decode, table.concat(lines, "\n"))
        if ok_json and type(data.scripts) == "table" then
          for script_name in pairs(data.scripts) do
            table.insert(templates, {
              name = pm .. " run " .. script_name,
              builder = function()
                return { cmd = { pm, "run", script_name }, cwd = root, components = { "default" } }
              end,
              desc = "Run package.json script: " .. script_name,
              tags = { overseer.TAG.RUN },
            })
          end
        end
      end
    end

    callback(templates)
  end,
  condition = {
    filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  cache_key = function(opts)
    return vim.fs.find("package.json", { upward = true, type = "file", path = opts.dir })[1] or opts.dir
  end,
}
