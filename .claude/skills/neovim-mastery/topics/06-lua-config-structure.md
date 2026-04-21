---
session: 06
title: Lua Config Structure
phase: B
prerequisites: []
duration: 45 min
---

# Session 06 — Lua Config Structure

## 1. Objective

Organize `init.lua` and `lua/` modules so the config stays legible at year five. After this session you can defend every line of structure in your config and explain why it was split (or *not* split) the way it is.

## 2. Why it matters

A messy `init.lua` becomes "I'm afraid to touch it." A well-structured one becomes a small library you maintain like any other Lua project. Your stack is mature C++/Python/Rust — you already know what good module boundaries look like. This is just applying it to your editor.

## 3. Core concepts

### `runtimepath` (rtp)

Neovim looks for Lua modules under any directory in `runtimepath`. The most important one is `~/.config/nvim/` (or `$XDG_CONFIG_HOME/nvim/`). Inside it:

```
~/.config/nvim/
├── init.lua             # entry point
├── lua/
│   ├── custom/          # YOUR namespace (avoid collisions)
│   │   ├── core/
│   │   │   ├── init.lua
│   │   │   ├── options.lua
│   │   │   ├── keymaps.lua
│   │   │   └── autocmds.lua
│   │   ├── plugins/     # one file per plugin (lazy.nvim spec)
│   │   │   ├── lspconfig.lua
│   │   │   ├── dap.lua
│   │   │   └── ...
│   │   └── utils/
│   │       └── globals.lua
│   └── (other namespaces if needed)
├── after/
│   └── ftplugin/        # filetype-specific overrides loaded after defaults
└── lazy-lock.json       # plugin version pin
```

**Naming:**
- The directory name `custom/` is YOUR namespace. Don't use generic names like `config/` or `user/` — they collide with distros.
- `init.lua` inside a Lua module directory is the implicit entry point: `require('custom.core')` loads `lua/custom/core/init.lua`.

### Module loading

```lua
-- init.lua
require("custom.core")              -- loads lua/custom/core/init.lua
require("custom.utils.globals")     -- loads lua/custom/utils/globals.lua
```

The `core/init.lua` chains its sub-modules:
```lua
require("custom.core.options")
require("custom.core.keymaps")
require("custom.core.autocmds")
```

### Why split by concern, not by plugin?

- **Options, keymaps, autocmds, plugins** are the *kinds* of things you tune. Each kind has its own file.
- **Per-plugin files** under `plugins/` are a lazy.nvim convention. Each file returns a *plugin spec table*. lazy.nvim collects all files in `plugins/` via `{ import = "custom.plugins" }` and merges them. Adding a plugin = adding one file.

### When to split, when NOT to split

**Split when** a file > ~150 lines, OR when a section has a distinct *concern* (e.g., LSP-specific autocmds belong in `lspconfig.lua`, not `autocmds.lua`).

**Don't split when** the result would be 5-line files. `core/options.lua` should hold all options, even if there are 80 of them — splitting `options/clipboard.lua` is overkill.

## 4. Config notes

Your structure already follows this pattern (`init.lua`, `lua/custom/{core,plugins,utils}/`). Notable details:

- **`init.lua:1`** — `require("custom.core")` first. Why first? Because the `custom.core` module sets `g.mapleader` (in `options.lua`). Lazy.nvim must see the leader BEFORE it processes plugin specs that use `keys = { "<Leader>x" }`.
- **`init.lua:3-16`** — bootstrap clones lazy.nvim if missing. This is the canonical lazy bootstrap; don't modify unless you know why.
- **`init.lua:20-38`** — `require("lazy").setup({ spec = { { import = "custom.plugins" } } })`. The single-line `import` collects every file in `lua/custom/plugins/`. Adding a plugin = creating one file.
- **`init.lua:32-37`** — `rocks` enabled (luarocks). Most plugins don't need this, but some (e.g. `magick.nvim`, treesitter advanced features) do. Leave it on.
- **`init.lua:40`** — `require("custom.utils.globals")` AFTER lazy. Globals that depend on plugins must come after lazy has loaded plugins synchronously.

The `custom/` namespace prefix protects you when adopting plugins that ship `lua/config/...` modules. Don't rename it.

## 5. Concrete examples

### Adding a new option

Open `lua/custom/core/options.lua`. Add the line near other related options. Reload with `:source %`. No restart.

### Adding a new keymap

Open `lua/custom/core/keymaps.lua`. Use `map(mode, lhs, rhs, { desc = "..." })`. Always include a `desc` — it powers `:map`, `which-key`, and your future-self.

### Adding a per-filetype keymap

Create `~/x/dotfiles/.config/nvim/after/ftplugin/python.lua`:

```lua
vim.keymap.set("n", "<Leader>xp", function()
  vim.cmd("split | terminal python3 -i %")
end, { buffer = true, desc = "Open Python REPL with current file" })
```

The `buffer = true` scopes the map to this buffer (set per-filetype thanks to ftplugin location). Loaded automatically when a `.py` buffer opens.

### Adding a new autocmd

Open `lua/custom/core/autocmds.lua` (or create a per-plugin autocmd in the relevant `plugins/*.lua`). Use the modern API:

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("custom-fmt-on-save", { clear = true }),
  pattern = "*.lua",
  callback = function() vim.notify("saved a Lua file") end,
})
```

Always create an `augroup` with `clear = true` so re-sourcing the file doesn't double-register the autocmd.

## 6. Shortcuts to memorize

### ESSENTIAL (config-editing workflow)
`:source %` (re-source the current Lua file — fastest way to test changes)
`:e $MYVIMRC` (open `init.lua`)
`:Lazy` (`<Leader>L` in your config) — open lazy UI
`<Leader>xx` — execute current line as Lua (your config)
`<Leader>xf` — execute current file (cpp/c/python/rust/lua dispatch)

### OPTIONAL
`:lua = vim.opt.runtimepath:get()` — inspect rtp
`:lua require('custom.plugins.lspconfig')` — manually load a module to test
`:checkhealth` — run all `:checkhealth` providers

### ADVANCED
`:lua print(vim.inspect(require('lazy').stats()))` — inspect lazy state
`vim.api.nvim_set_hl()` — programmatic highlight overrides

## 7. Drills

1. Add a new option (e.g. `vim.opt.colorcolumn = "100"`) to `options.lua`. Re-source with `:source %`. Confirm with `:set colorcolumn?`. Then remove it.
2. Add a temporary keymap to `keymaps.lua` with a unique `desc` like `"DRILL: hello"`. Re-source. Verify with `:map <Leader>...` and `:Telescope keymaps` (search for "DRILL"). Remove it.
3. Open `lspconfig.lua`. Find where `vim.lsp.config("clangd", ...)` is called (line 86). Use `<Leader>xx` on a different line (e.g. `print("hello")`) to confirm scratchy execution works.
4. Create `after/ftplugin/lua.lua` (yes, for editing your own config). Add `vim.opt_local.tabstop = 2`. Open any other `.lua` file and confirm `:set tabstop?` shows 2.

## 8. Troubleshooting

- **"`require` doesn't find my module."** Lua module paths use dots: `lua/custom/foo/bar.lua` → `require("custom.foo.bar")`. NOT slashes.
- **"Changes don't take effect."** You re-sourced the wrong file. `:source %` re-runs the current buffer. For plugin specs, you need `:Lazy reload <plugin>` or restart.
- **"`:source %` errors with `attempt to call nil`."** A function was defined in a module that hasn't been loaded yet. Restart Neovim or `require()` the missing module first.
- **"My ftplugin file doesn't load."** Confirm path is `after/ftplugin/<filetype>.lua`, NOT `after/ftplugin/<extension>.lua`. Also: `:setfiletype <ft>` to test.

## 9. Optional config edit

Worth considering — **a `local` table to consolidate constants**. Currently your keymaps reference globals like `vim.g.have_nerd_font`. If you ever want a single place to override per-machine settings (e.g., disable nerd font on a remote box), create:

```lua
-- lua/custom/utils/env.lua
local M = {}
M.is_macos = vim.uv.os_uname().sysname == "Darwin"
M.is_remote = vim.env.SSH_TTY ~= nil
M.has_nerd_font = vim.g.have_nerd_font
return M
```

Then `local env = require("custom.utils.env")` in any file that needs the flags. Optional; ASK before adding.

## 10. Next-step upgrades

- Once your config is a tree of small Lua modules, you can write **tests** for the non-plugin logic. Use [`busted`](https://lunarmodules.github.io/busted/) under `:lua` or via a `make test` recipe. Niche but possible.
- Consider documenting each `plugins/*.lua` with a one-line header comment: `-- Purpose: <X>. Without it: <Y>.` Future-you will thank present-you.

## 11. Connects to

Next: **Session 7 — Plugin Architecture (lazy.nvim + vim.pack)**. The `plugins/` directory is yours; let's understand exactly what lazy.nvim does with it, when each plugin loads, and what `vim.pack` (the 0.12 builtin) would look like as an alternative.
