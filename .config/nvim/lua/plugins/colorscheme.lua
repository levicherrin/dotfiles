return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    config = function()
      local is_transparent = vim.uv.os_uname().sysname == 'Darwin'
        or string.find(vim.uv.os_uname().sysname, 'Windows') ~= nil
        or string.find(vim.uv.os_uname().release, 'WSL') ~= nil

      require('catppuccin').setup({
        flavour = 'mocha', -- latte, frappe, macchiato, mocha
        transparent_background = is_transparent,
        integrations = {
          gitsigns = true,
          neogit = true,
          which_key = true,
          snacks = true,
        },
      })

      vim.cmd.colorscheme('catppuccin')
    end,
  },
}
