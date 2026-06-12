# Neovim Lua API quick reference

## vim.keymap.set

```lua
vim.keymap.set("n", "<Leader>x", function() ... end, { desc = "Do thing" })
vim.keymap.set({ "n", "x" }, "j", "gj")                        -- multiple modes
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
vim.keymap.set("n", "key", "rhs", { buffer = bufnr })           -- buffer-local
vim.keymap.set("n", "key", "rhs", { remap = true, silent = true })
vim.keymap.del("n", "<Leader>x")                                -- remove mapping
```

## vim.api essentials

```lua
-- Autocommands
vim.api.nvim_create_augroup("my-group", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "my-group", pattern = "*.cpp",
  callback = function(ev) end,  -- ev.buf, ev.file, ev.match, ev.data
})

-- User commands
vim.api.nvim_create_user_command("Greet", function(opts)
  print(opts.args)  -- .fargs (table), .bang (bool), .range
end, { nargs = "?", bang = true, desc = "Greet", complete = "file" })

-- Highlights
vim.api.nvim_set_hl(0, "MyGroup", { fg = "#ff0000", bold = true })
vim.api.nvim_set_hl(0, "MyGroup", { link = "ErrorMsg" })

-- Buffer/window
vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)        -- all lines
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.api.nvim_get_current_buf()                          -- current bufnr
vim.api.nvim_win_get_cursor(0)          -- {row, col} (1-indexed row, 0-indexed col)
```

## vim.lsp.*

```lua
-- Config (0.11+ style)
vim.lsp.config("clangd", { cmd = { "clangd" }, settings = {} })
vim.lsp.enable({ "clangd", "lua_ls" })

-- Completion
vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })

-- Inlay hints
vim.lsp.inlay_hint.enable(true)         -- enable globally
vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })

-- Folding
vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"

-- Buffer actions
vim.lsp.buf.hover()              vim.lsp.buf.definition()
vim.lsp.buf.references()         vim.lsp.buf.rename()
vim.lsp.buf.code_action()        vim.lsp.buf.document_highlight()
vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
```

## vim.diagnostic.*

```lua
vim.diagnostic.config({
  virtual_text = false, virtual_lines = { current_line = true },
  signs = { text = { [vim.diagnostic.severity.ERROR] = "" } },
  severity_sort = true,
})
vim.diagnostic.jump({ count = 1 })                                  -- next
vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
vim.diagnostic.setqflist()              -- all to quickfix
vim.diagnostic.setloclist()             -- buffer to loclist
vim.diagnostic.enable(false)            -- disable (true to re-enable)
vim.diagnostic.open_float()             -- float at cursor
vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
```

## vim.treesitter.*

```lua
vim.treesitter.start()                          -- enable highlighting
vim.treesitter.get_parser(bufnr, "cpp")         -- get/create parser
vim.treesitter.get_node()                       -- node under cursor
vim.treesitter.get_node():type()                -- node type string
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"  -- treesitter folding

local query = vim.treesitter.query.parse("cpp", "(function_definition) @func")
for id, node, metadata in query:iter_captures(root, bufnr) do ... end
```

## Options: vim.opt / vim.o / vim.bo / vim.wo

```lua
vim.o.number = true                     -- raw get/set (global scope)
vim.opt.number = true                   -- rich wrapper (supports :append/:remove/:get)
vim.bo.filetype                         -- buffer-local
vim.wo.wrap                             -- window-local
vim.bo[bufnr].modifiable = false        -- specific buffer
vim.wo[winid][0].foldmethod = "expr"    -- specific window

vim.opt.shortmess:append({ W = true, I = true })
vim.opt.completeopt = { "menuone", "noinsert", "popup" }  -- list -> comma-sep
local val = vim.opt.completeopt:get()                      -- returns table
```

## vim.fn vs vim.api vs vim.cmd

| Namespace | Use for |
|-----------|---------|
| `vim.fn` | Vimscript functions: `vim.fn.expand("%")`, `vim.fn.getcwd()` |
| `vim.api` | Neovim API (nvim_*): buffers, windows, autocmds, highlights |
| `vim.cmd` | Ex commands: `vim.cmd("write")`, `vim.cmd.bprevious()` |

## vim.uv and vim.system

```lua
-- Timer (libuv)
local timer = vim.uv.new_timer()
timer:start(1000, 0, vim.schedule_wrap(function() timer:close() end))

-- Filesystem
vim.uv.fs_stat("/path")                        -- sync stat

-- Async command
vim.system({ "git", "status" }, { text = true }, function(obj)
  vim.schedule(function() print(obj.stdout) end)  -- obj.code, .stdout, .stderr
end)
-- Sync: vim.system({ "cmd" }, { text = true }):wait()
```

## vim.schedule / vim.defer_fn

```lua
vim.schedule(function() ... end)        -- safe API calls from async contexts
vim.defer_fn(function() ... end, 100)   -- run after 100ms (already scheduled)
vim.schedule_wrap(fn)                   -- wraps fn to call via vim.schedule
```

## Debugging

```lua
vim.print(value)                        -- pretty-print to :messages
print(vim.inspect(tbl))                 -- inspect table structure
:messages                               -- view message log
:verbose map <Leader>ff                 -- who set this mapping
:verbose set number?                    -- who set this option
:lua vim.print(vim.lsp.get_clients())   -- inspect active LSP clients
:checkhealth                            -- health checks
:.lua                                   -- execute current line as Lua
:so %                                   -- source current file
```
