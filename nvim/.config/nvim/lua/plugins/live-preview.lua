return {
  "brianhuster/live-preview.nvim",
  dependencies = {
    -- You can choose one of the following pickers
    "nvim-telescope/telescope.nvim",
    "ibhagwan/fzf-lua",
    "nvim-mini/mini.pick",
    "folke/snacks.nvim",
  },
  require("livepreview.config").set({
    port = 5050,
    browser = "firefox",
    picker = "fzf-lua",
    address = "127.0.0.1",
  }),
}
