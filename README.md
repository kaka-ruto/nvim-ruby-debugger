Neovim plugin for debugging Ruby and Rails applications using nvim-dap and the debug gem.

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {'yourusername/nvim-ruby-debugger'}
```

## Configuration

In your Neovim configuration:
require('ruby_debugger').setup({
port = 3001,
host = '127.0.0.1',
debugger_cmd = 'bundle exec rdbg -n --open --port ${port} --host ${host} -- bin/rails server -p 3000',
log_level = 'info',
})

## Usage

    a.	Set breakpoints in your Ruby files using ﻿<leader>b.
    b.	Start debugging with ﻿<leader>dc.
