<h1 align="center">NBuftabline</h1>

<div align="center">
A well-integrated, low-configuration buffer list that lives in the tabline, Fork of <a href="https://github.com/ap/vim-buftabline">Buftabline<br>
<img src="https://i.postimg.cc/zXnRjGV1/1726360014.png" width="787">
</div>

#### Installation
##### lazy.nvim
```lua
{
    'kamal-elbalaidi/vim-buftabline',
}
```
#### Configuration
```lua
     config = function()

      function ToggleTabline()
        if vim.o.showtabline == 2 then
          vim.o.showtabline = 0
        else
          vim.o.showtabline = 2
        end
      end

      vim.g.buftabline_separator = '│'
      vim.g.buftabline_mark_modified = '●'
      vim.g.buftabline_tab_width = 20

      vim.api.nvim_set_keymap('n', '<leader>tt', ':lua ToggleTabline()<CR>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>th', ':bp<cr>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>tl', ':bn<cr>', { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>tx', ':bd<cr>', { noremap = true, silent = true })

```
#### Customizing Colors

```lua
      vim.api.nvim_set_hl(0, 'BufTabLineCurrent', { fg=#aaaaaa, bold=true })
      vim.api.nvim_set_hl(0, 'BufTabLineFill',   { fg=#3c3c3c, bold=false })
      vim.api.nvim_set_hl(0, 'BufTabLineHidden', { fg=#3c3c3c, bold=false })
      vim.api.nvim_set_hl(0, 'BufTabLineActive', { fg=#3c3c3c, bold=false })
```
