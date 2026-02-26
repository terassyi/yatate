-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin definitions
require("lazy").setup({
  { "numToStr/Comment.nvim" },
  { "akinsho/bufferline.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "windwp/nvim-autopairs" },
  { "easymotion/vim-easymotion" },
  { "kylechui/nvim-surround" },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl" },
  { "folke/which-key.nvim" },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "lewis6991/gitsigns.nvim" },
  { "sindrets/diffview.nvim" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "dockerfile", "fish", "go", "json", "just",
          "lua", "make", "markdown", "nix", "proto", "python",
          "rust", "toml", "yaml", "query",
        },
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
      })
    end,
  },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "j-hui/fidget.nvim" },
  { "L3MON4D3/LuaSnip" },
  { "stevearc/conform.nvim" },
})

-- Color scheme
vim.cmd("colorscheme tokyonight")

-- Basic options
require('options')

-- Key maps
require('keymaps')

-- Plugins
require('plugins')

-- LSP
require('lsp')
