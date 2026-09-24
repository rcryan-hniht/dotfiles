return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      -- your dashboard configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      row = nil,
      col = nil,
      preset = {
        keys = {

          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          {
            icon = " ",
            desc = "Browse Repo",
            padding = 1,
            key = "b",
            action = function()
              Snacks.gitbrowse()
            end,
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = [[
█    ██   ▄▄▄▄▄▄ ▀▄    ▄ 
█    █ █ ▀   ▄▄▀   █  █  
█    █▄▄█ ▄▀▀   ▄▀  ▀█   
███▄ █  █ ▀▀▀▀▀▀    █    
    ▀   █         ▄▀     
       █                 
      ▀                  
        ]],
      },

      sections = {
        { section = "header", gap = 1, padding = 1, align = "center" },
        {
          pane = 2,
          section = "terminal",
          cmd = "colorscript -e square",
          -- cmd = "fastfetch -l berserkarch --logo-height 12 --logo-width 25 -s none",
          -- cmd = "fastfetch -l BlackArch --logo-height 12 --logo-width 25 -s none",
          -- cmd = "cava",
          -- cmd = "cmatrix -a -C black",
          -- Còn lỗi cmd này
          -- cmd = [[fastfetch --logo "$HOME/dotfiles/.config/themes/fetch/Reze/*" --logo-height 12 --logo-width 25 -s none]],
          height = 8,
          --height = 22,
          padding = 1,
        },
        { pane = 1, section = "keys", gap = 1, padding = 1 },
        { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        function()
          local in_git = Snacks.git.get_root() ~= nil
          local cmds = {
            {
              icon = " ",
              title = "Git Status",
              -- cmd = "git status --short --branch --renames",
              cmd = "git --no-pager diff --stat -B -M -C",
              height = 10,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend("force", {
              pane = 2,
              section = "terminal",
              gap = 1,
              enabled = in_git,
              padding = 1,
              ttl = 5 * 60,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
        { section = "startup", gap = 1, padding = 1 },
      },
    },
  },
}
