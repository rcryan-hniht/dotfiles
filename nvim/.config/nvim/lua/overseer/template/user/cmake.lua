-- ~/.config/nvim/lua/overseer/template/user/cmake.lua
-- Provides: CMake: Configure / CMake: Build / CMake: Clean / CMake: Run <target>
-- Auto-detects the project root by searching upward for CMakeLists.txt.

local overseer = require("overseer")

--- Parse add_executable() from CMakeLists.txt.
--- Returns the target name (first arg) which is the binary name.
local function parse_executables(cmakelists)
  local names = {}
  local seen = {}
  for _, line in ipairs(vim.fn.readfile(cmakelists)) do
    line = line:gsub("#.*$", "")
    local name = line:match("add_executable%s*%(%s*([%w_%-]+)")
    if name and not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end
  return names
end

---@type overseer.TemplateFileProvider
return {
  generator = function(search, callback)
    local found = vim.fs.find("CMakeLists.txt", { upward = true, type = "file", path = search.dir })[1]
    if not found then
      callback("No CMakeLists.txt found")
      return
    end

    local root = vim.fs.dirname(found)
    local build_dir = "build"
    local ok, executables = pcall(parse_executables, found)
    if not ok then
      executables = {}
    end

    local templates = {
      {
        name = "CMake: Configure",
        params = {
          werror = {
            type = "boolean",
            default = false,
            desc = "Treat warnings as errors (-Werror)",
          },
          sanitize = {
            type = "boolean",
            default = false,
            desc = "Enable AddressSanitizer + UndefinedBehaviorSanitizer",
          },
          fresh = {
            type = "boolean",
            default = false,
            desc = "Wipe cached flags and reconfigure from scratch (CMake >= 3.24)",
          },
        },
        builder = function(params)
          local flags = { "-Wall", "-Wextra", "-g" }
          if params.werror then
            table.insert(flags, "-Werror")
          end
          if params.sanitize then
            table.insert(flags, "-fsanitize=address,undefined")
          end
          local flag_str = table.concat(flags, " ")
          local args = {
            "-S", ".", "-B", build_dir,
            "-DCMAKE_BUILD_TYPE=Debug",
            "-DCMAKE_C_FLAGS=" .. flag_str,
            "-DCMAKE_CXX_FLAGS=" .. flag_str,
          }
          -- CMake caches -D flags in CMakeCache.txt on first configure; without
          -- --fresh (or deleting build/), later runs silently keep the old values.
          if params.fresh then
            table.insert(args, "--fresh")
          end
          return {
            cmd = { "cmake" },
            args = args,
            cwd = root,
            components = { "default" },
          }
        end,
        desc = "Configure the project into ./build (with -Wall -Wextra -g by default)",
        tags = { overseer.TAG.BUILD },
      },
      {
        name = "CMake: Build",
        builder = function()
          return {
            cmd = { "cmake" },
            args = { "--build", build_dir },
            cwd = root,
            components = { "on_output_quickfix", "default" },
          }
        end,
        desc = "Build the already-configured project",
        tags = { overseer.TAG.BUILD },
      },
      {
        name = "CMake: Clean",
        builder = function()
          return {
            cmd = { "rm" },
            args = { "-rf", build_dir },
            cwd = root,
            components = { "default" },
          }
        end,
        desc = "Remove the build/ directory entirely",
        tags = { overseer.TAG.BUILD },
      },
    }

    if #executables > 0 then
      for _, exe in ipairs(executables) do
        table.insert(templates, {
          name = "CMake: Run " .. exe,
          builder = function()
            return {
              cmd = { "./" .. build_dir .. "/" .. exe },
              cwd = root,
              components = { "default" },
            }
          end,
          desc = "Run ./" .. build_dir .. "/" .. exe,
          tags = { overseer.TAG.RUN },
        })
      end
    else
      table.insert(templates, {
        name = "CMake: Run",
        params = {
          executable = {
            type = "string",
            default = "",
            desc = "Executable name inside the build dir (couldn't auto-detect it)",
          },
        },
        builder = function(params)
          return {
            cmd = { "./" .. build_dir .. "/" .. params.executable },
            cwd = root,
            components = { "default" },
          }
        end,
        desc = "Run a built executable from ./build",
        tags = { overseer.TAG.RUN },
      })
    end

    callback(templates)
  end,
  condition = {
    filetype = { "c", "cpp" },
  },
  -- Cache is invalidated automatically whenever CMakeLists.txt is written.
  cache_key = function(opts)
    return vim.fs.find("CMakeLists.txt", { upward = true, type = "file", path = opts.dir })[1]
  end,
}
