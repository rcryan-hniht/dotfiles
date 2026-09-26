-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>bD", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bd", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
map("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })

-- ── Overseer ──────────────────────────────────────────────────────────

map("n", "<leader>ot", "<cmd>OverseerToggle<cr>", { desc = "Toggle Task List" })
map("n", "<leader>oo", "<cmd>OverseerOpen<cr>", { desc = "Open" })
map("n", "<leader>or", "<cmd>OverseerRun<cr>", { desc = "Run template" })
map("n", "<leader>oa", "<cmd>OverseerTaskAction<cr>", { desc = "Task Action" })
map("n", "<leader>oc", "<cmd>OverseerClose<cr>", { desc = "Close" })
map("n", "<leader>os", "<cmd>OverseerShell<cr>", { desc = "Open Shell" })
map("n", "<leader>oi", "<cmd>OverseerInfo<cr>", { desc = "Info" })

map("n", "<leader>ol", function()
  local tasks = require("overseer").list_tasks({ recent_first = true })
  if tasks[1] then
    require("overseer").run_action(tasks[1], "restart")
  else
    vim.notify("No overseer tasks to restart", vim.log.levels.WARN)
  end
end, { desc = "Overseer: Restart last task" })
