---
session: 07
title: Plugin Architecture — lazy.nvim + vim.pack
phase: B
prerequisites: [6]
duration: 45 min
---

# Session 07 — Plugin Architecture (lazy.nvim + vim.pack)

## 1. Objective

Understand exactly what lazy.nvim does with your `plugins/*.lua` files, when each plugin loads, why startup time matters, and what `vim.pack` (the 0.12 builtin) would look like as an alternative. After this session, you can read any plugin spec and predict when it loads — and write specs that don't bloat startup.

## 2. Why it matters

Plugin lifecycle is the difference between a 60ms cold start and a 600ms one. For C++/Python/Rust workflows where you `:e` lots of files quickly, every saved millisecond compounds. And mis-configured `lazy = false` plugins are the #1 cause of "why is my Neovim slow."

## 3. Core concepts

### What lazy.nvim does

Given the spec `{ import = "custom.plugins" }` in your `init.lua`, lazy.nvim:

1. Loads every file in `lua/custom/plugins/` (including subdirectories).
2. Each file `return`s a **plugin spec table** (or a list of them).
3. Lazy merges all specs into a single dependency graph.
4. For each plugin: clones it (if missing), checkouts the pinned commit (from `lazy-lock.json`), defers loading until a *trigger* fires.

### A plugin spec

The minimum viable spec:

```lua
return {
  "owner/repo",
}
```

The realistic spec:

```lua
return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  event = { "BufReadPre", "BufNewFile" },     -- load when a buffer is read or created
  cmd = { "ConformInfo" },                    -- also load on these :commands
  ft = { "lua", "python", "rust" },           -- also load when these filetypes open
  keys = {
    { "<Leader>cf", function() require("conform").format() end, desc = "Format" },
  },
  build = ":MasonInstallAll",                 -- post-install build step
  opts = {                                    -- shorthand: lazy calls require(name).setup(opts)
    formatters_by_ft = { ... },
  },
  config = function()                         -- OR: full config function (you control require/setup)
    require("conform").setup({...})
  end,
  lazy = false,                               -- explicitly eager (rare; usually for theme/treesitter)
  priority = 1000,                            -- load order when multiple lazy=false (theme = 1000)
}
```

### Triggers (when does my plugin load?)

| Trigger              | Fires when                                                   | Use for                                                   |
| -------------------- | ------------------------------------------------------------ | --------------------------------------------------------- |
| `event = "BufRead"` etc. | An autocmd event fires                                       | Most "file-related" plugins (formatters, LSP-attach helpers) |
| `cmd = "Telescope"`   | A `:command` is invoked                                       | Plugins you only access via `:cmd`                        |
| `ft = "rust"`        | A buffer of that filetype opens                              | Per-language plugins (rustaceanvim, crates.nvim)          |
| `keys = { "..." }`   | A key is pressed                                              | Plugins triggered by a leader chord                       |
| `lazy = true` (default) | Never auto-loaded; only when above triggers fire             | Most plugins                                              |
| `lazy = false`       | At startup                                                    | Theme (must paint immediately); treesitter (start before files open) |
| `priority = N`       | Among `lazy = false` plugins, higher priority loads first     | Theme = 1000 (loads before others to avoid flash)         |

**Rule:** prefer the most *narrow* trigger. `event = "BufReadPre"` loads earlier than `event = "VeryLazy"`; `keys = { ... }` is even narrower if you only use it via that key.

### `lazy-lock.json`

Pins each plugin to a specific commit. Commit this file to git. Reproducible installs across machines. Run `:Lazy update` to bump (and re-pin); `:Lazy restore` to roll back to the lockfile.

### `vim.pack` (Neovim 0.12 built-in)

```lua
vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})
```

What `vim.pack` gives you:
- Built-in. No bootstrap needed.
- Clones into `~/.local/share/nvim/site/pack/core/opt/...`.
- Activates with `:packadd <name>` or `vim.cmd.packadd("<name>")`.

What `vim.pack` does NOT give you (yet):
- Event-based lazy loading.
- `keys`/`cmd`/`ft` triggers.
- A UI like `:Lazy`.
- Lockfile management.
- Dependency resolution.

**Verdict for the user:** stay on lazy.nvim. `vim.pack` is the right answer for *minimalist* configs (a 100-line `init.lua`). Your config has 18+ plugins with rich triggers — lazy.nvim earns its keep.

## 4. Config notes

Your `init.lua:20-38` configures lazy with:

- `spec = { { import = "custom.plugins" } }` — auto-collects all files.
- `install = { colorscheme = { "catppuccin-macchiato" } }` — paint with this theme during install UI (so it's not jarring before your real theme loads).
- `checker.enabled = true, notify = false` — automatically checks for plugin updates in background, doesn't notify.
- `change_detection.notify = false` — re-detect spec changes silently.
- `rocks.enabled = true` — luarocks support; needed for some plugins (e.g. `magick.nvim`). Most users don't need it; you've enabled it preemptively.

Plugin spec patterns in your config worth noting:

- `lspconfig.lua` uses `config = function() ... end` (full control). Why? It needs to register an `LspAttach` autocmd at the right moment.
- `treesitter.lua` uses `lazy = false`. Why? Treesitter must be ready before any file opens, otherwise the first file you open won't get highlighted.
- `dap.lua` uses `keys = { ... }` only. Why? You don't need DAP loaded until you press `<Leader>db`. Saves ~30ms of startup.
- `mason.lua` uses `cmd = { "Mason", "MasonUpdate", "MasonInstall" }, keys = { ... }, opts = {}`. So Mason loads only on those commands or your `<Leader>M` keystroke.

## 5. Concrete examples

### Adding a new lazy-loaded plugin

To add `crates.nvim` (Cargo.toml info):

```lua
-- lua/custom/plugins/crates.lua
return {
  "saecki/crates.nvim",
  ft = { "toml" },                            -- only load for .toml files
  config = function()
    require("crates").setup({})
  end,
}
```

That's it. Restart Neovim or `:Lazy reload crates.nvim`. Confirm with `:Lazy` (find `crates.nvim` in the list — it should show "loaded" only after you open a `.toml`).

### Profiling startup

```bash
nvim --startuptime /tmp/startup.log +q
sort -k2 -n /tmp/startup.log | tail -30
```

In Neovim: `:Lazy profile` (or `<Leader>L` then `p`) shows per-plugin load times. Anything > 5ms in `lazy = false` is suspect; > 50ms is a problem.

### Migrating a `lazy = false` plugin to lazy

You inherit a plugin that does `lazy = false` for no reason. Look at how you actually invoke it:

- Always via `:Telescope ...`? → `cmd = { "Telescope" }`.
- Only when you press `<Leader>ff`? → `keys = { { "<Leader>ff", "<cmd>Telescope find_files<cr>" } }`.
- Only for `.go` files? → `ft = { "go" }`.

Pick the narrowest trigger. Restart. Profile. Confirm.

## 6. Shortcuts to memorize

### ESSENTIAL
`:Lazy` (`<Leader>L`) — open UI · `s` sync · `u` update · `c` clean · `p` profile · `?` help
`:Lazy reload <name>` — reload a plugin without restart
`:Lazy log <name>` — see commit log of installs/updates

### OPTIONAL
`:Lazy build <name>` — re-run build step
`:Lazy check` — check for updates (without applying)
`:Lazy clear` — remove broken installs

### ADVANCED
`vim.pack.add({...})` — known surface but not in use here
`:lua = require('lazy').stats()` — programmatic stats

## 7. Drills

1. Run `nvim --startuptime /tmp/startup.log +q` and `sort -k2 -n /tmp/startup.log | tail -30`. Identify your top 5 startup-cost lines.
2. Run `:Lazy profile` (`<Leader>L` → `p`). Note the slowest plugin and confirm whether it's `lazy = false` (and whether it needs to be).
3. Open `lua/custom/plugins/dap.lua` (line 9-15). Read the `keys = { ... }` spec. Predict: when does dap.nvim actually load? (Answer: only when you press `<Leader>db/dc/do/di/du`.)
4. Add a temporary plugin to test the cycle: create `lua/custom/plugins/temp.lua` with `return { "echasnovski/mini.cursorword", event = "VeryLazy" }`. Restart. Confirm with `:Lazy`. Then delete the file and `:Lazy clean`.

## 8. Troubleshooting

- **"`:Lazy reload` doesn't pick up changes."** Some `config` functions register autocmds that persist. Run `:autocmd <event> <pattern>` to confirm; or restart.
- **"Plugin won't install."** Run `:Lazy log <name>` to see git output. Often a network/auth issue.
- **"Updated a plugin and now it crashes."** `:Lazy restore` rolls back to `lazy-lock.json`. Then `git diff lazy-lock.json` to see what changed; pin manually if needed.
- **"My theme flashes during startup."** Theme isn't `lazy = false` with high `priority`. Move it to `priority = 1000`.

## 9. Optional config edit

If audit reveals slow startup, the typical fix is **converting `lazy = false` plugins to event-based loading**. Example diff for a hypothetical bloated plugin:

```diff
-- a/lua/custom/plugins/foo.lua
+++ b/lua/custom/plugins/foo.lua
 return {
   "owner/foo.nvim",
-  lazy = false,
+  event = "BufReadPre",
   config = function()
     require("foo").setup({})
   end,
 }
```

Always profile before AND after to confirm the change actually helped. ASK before applying.

## 10. Next-step upgrades

- Once you understand triggers, you'll naturally write tighter specs for new plugins.
- Consider documenting each plugin spec with a one-line `-- Purpose:` comment so the *why* is captured next to the spec.
- For complex specs (e.g. `nvim-lspconfig`), keep the spec file under ~150 lines. If it grows, split: `lspconfig.lua` calls into `lspconfig/clangd.lua`, `lspconfig/rust.lua`, etc. The user's current `lspconfig.lua` is ~110 lines — at the threshold. Consider splitting in audit.

## 11. Connects to

Next: **Session 8 — LSP, Completion, Diagnostics**. With config structure and lifecycle understood, time for the heart of the IDE: language servers, native completion, and the Neovim 0.11+ default keymaps that just work.
