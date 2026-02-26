-- load Plugins
require('nvim-autopairs').setup()
require('ibl').setup()
require('nvim-surround').setup()
require('which-key').setup()
require('bufferline').setup()
require('diffview').setup()

require('gitsigns').setup({
	current_line_blame = true,
	word_diff = true,
	linehl = true,
})

require('lualine').setup({
	sections = {
		lualine_d = { 'diff' },
	}
})

require('Comment').setup({
	toggler = {
		line = '<leader>/',
	},
	opleader = {
		line = '<leader>/',
	},
})
