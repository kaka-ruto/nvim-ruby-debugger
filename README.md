# nvim-ruby-debugger

A Neovim plugin for debugging Ruby applications, including Rails servers, Solid Queue workers, and Minitest files.

## Features

- Debug Rails servers
- Debug Solid Queue workers
- Debug Minitest files (entire file or specific line)
- Integrated with nvim-dap for a smooth debugging experience
- Customizable configurations

## Requirements

- [Neovim](https://github.com/neovim/neovim) (>= 0.10.0)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)
- [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)
- The [debug.rb](https://github.com/ruby/debug) gem installed in your Ruby project

## Installation

### Using packer.nvim:

```lua
use {
  'kaka-ruto/nvim-ruby-debugger',
  requires = {
    'mfussenegger/nvim-dap',
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
  },
  config = function()
    require('nvim-ruby-debugger').setup()
  end
}
```

### Using vim-plug:

```
Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'
Plug 'theHamsta/nvim-dap-virtual-text'
Plug 'your-username/nvim-ruby-debugger'

" In your init.vim or init.lua
lua require('nvim-ruby-debugger').setup()
```

## Configuration

The plugin comes with the following customizable default configurations

```lua
require('nvim-ruby-debugger').setup({
  rails_port = 38698,
  worker_port = 38699,
  minitest_port = 38700,
  host = "127.0.0.1",
})
```

## Usage

### Debugging a Rails server

This is akin to the usual process of setting `binding.break` or `binding.pry` in your file and going to the browser to trigger execution.

With this plugin, the process is a little different.

1. First, you need to start the Rails server with [rdbg](https://github.com/ruby/debug/blob/master/exe/rdbg) from the debug gem

```
bundle exec rdbg -n --open --port 38698 -c -- bin/rails server -p 3000
```

By default, this plugin is set to debug Rails servers via port 38698 but you can customize it in your config

2. Your Rails server should now be running with rdbg waiting for a debug connection

```
DEBUGGER: Debugger can attach via TCP/IP (127.0.0.1:38698)
```

3. On Neovim, navigate to the file that you want to debug and first set the breakpoint with `<Leader>db` or `:lua require('dap').toggle_breakpoint()`

You can set as many breakpoints as you want

4. Hit `<Leader>ds` or run `:DebugRails` to debug the rails server

5. Go to the browser to trigger a request that will hit your breakpoints. The debugger will attach and pause when it hits the first.

6. Dap UI will then kick in on your first breakpoint and open up a few windows for your ingestion! I recommend their [docs](https://github.com/rcarriga/nvim-dap-ui) for how to navigate the debugger UI

7. Once your curiosity is satisfied, hit `<Leader>dc` to continue with execution

### Debugging Solid Queue Workers

1. In a similar manner to debugging the rails server, we need to connect the solid queue process with the Ruby debugger.

I could not make `bundle exec rdbg` work well with solid queue, but the following substitute did the job (it still connects without blocking the worker)

```
RUBYOPT="-r debug/open" bin/jobs
```

The plugin provides the following commands:
• ﻿:DebugRailsServer: Debug a Rails server
• ﻿:DebugSolidQueueWorker: Debug a Solid Queue worker
• ﻿:DebugMinitestFile: Debug the current Minitest file
• ﻿:DebugMinitestLine: Debug the Minitest at the current line
To use these commands: 1. Open your Ruby file in Neovim. 2. Set breakpoints using ﻿:lua require('dap').toggle_breakpoint(). 3. Run one of the debug commands above.
The debugger will start, and you can use nvim-dap commands to step through your code, inspect variables, etc.
Extending the Plugin
You can extend the plugin by modifying or adding to the existing files:
• ﻿lua/nvim-ruby-debugger/init.lua: Main entry point
• ﻿lua/nvim-ruby-debugger/config.lua: Configuration options
• ﻿lua/nvim-ruby-debugger/adapters.lua: DAP adapters
• ﻿lua/nvim-ruby-debugger/configurations.lua: DAP configurations
• ﻿lua/nvim-ruby-debugger/commands.lua: User commands
• ﻿lua/nvim-ruby-debugger/utils.lua: Utility functions
To add a new debugging configuration: 1. Add a new configuration in ﻿configurations.lua. 2. Create a new command in ﻿commands.lua to run this configuration. 3. If needed, add new options in ﻿config.lua.
Contributing
Contributions are welcome! Here's how you can contribute: 1. Fork the repository. 2. Create a new branch for your feature or bug fix. 3. Make your changes and commit them with a clear commit message. 4. Push your changes to your fork. 5. Create a pull request to the main repository.
When contributing, please:
• Follow the existing code style.
• Add tests for new features or bug fixes.
• Update the README if you're adding new features or changing existing ones.
• Make sure all existing tests pass.
Setting Up Development Environment 1. Clone your fork of the repository. 2. Install the plugin in Neovim using your preferred method, pointing to your local clone. 3. Make changes to the plugin code. 4. Restart Neovim or reload the plugin to test your changes.
