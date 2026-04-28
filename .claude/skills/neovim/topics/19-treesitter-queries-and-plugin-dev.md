---
session: 19
title: Treesitter queries & local plugin development
phase: F
prerequisites: [07, 09]
duration: 60 min
---

# Session 19 — Treesitter Queries & Local Plugin Development

## 1. Objective

Two graduations in one session:

1. Write your own treesitter `.scm` query — a custom capture for a textobject like "C++ function body excluding the leading docblock comment", scoped per-language under `~/.config/nvim/queries/<lang>/textobjects.scm`.
2. Structure a local plugin under `~/x/dotfiles/.config/nvim/lua/custom/plugins/local/<name>.lua` that loads via `lazy.nvim` with `dir = ...` — the canonical pattern for "I want this plugin only on my machine."

After this session you stop forking other people's plugins for one-line tweaks.

## 2. Why it matters

Custom textobjects in Lua (Session 18) work, but they're language-agnostic and rely on regex/indent. Treesitter sees real ASTs. A `.scm` query that captures `(function_definition body: (compound_statement) @function.inner)` will work in *every* C++ file forever, no matter how the user formats braces. And the `lua/custom/plugins/local/` pattern lets you commit experimental code in dotfiles without publishing — you get plugin-manager loading semantics (events, ft, keys) without GitHub.

## 3. Core concepts

### Treesitter query basics

Queries are `.scm` (Scheme-like) files. Each query is one or more *patterns*: `(node_type child: (other_node) @capture_name)`.

Capture names that the textobjects plugin recognizes (this is a convention, not a rule):

| Capture                    | Triggers (in `o`/`x` mode) |
| -------------------------- | -------------------------- |
| `@function.outer` / `@function.inner` | `af` / `if`               |
| `@class.outer`   / `@class.inner`     | `ac` / `ic`               |
| `@parameter.outer` / `@parameter.inner` | `aa` / `ia`             |
| `@call.outer`   / `@call.inner`       | `ai` / `ii`               |
| `@comment.outer`                       | `aN` (custom — pick anything) |

To extend or override, drop a file at `~/.config/nvim/queries/<lang>/textobjects.scm`. Treesitter merges it on top of the bundled defaults via runtimepath.

### `:InspectTree` and `:EditQuery`

- `:InspectTree` opens a window showing the AST of the current buffer. Move cursor in your code; the tree window highlights the node. Indispensable.
- `:EditQuery` opens an interactive playground: write queries on the left, see live captures on the right. The fastest way to iterate.

### Local plugin pattern (`dir =`)

`lazy.nvim` accepts `dir = "/abs/path"` instead of `"author/repo"`. That path becomes the plugin root. Create:

```
~/x/dotfiles/.config/nvim/lua/custom/plugins/local/yank_jira/
├── lua/
│   └── yank_jira/
│       └── init.lua  -- returns { setup = function(opts) ... end }
└── plugin/  (optional — files here load on startup like a real plugin)
```

Then a lazy spec:

```lua
-- lua/custom/plugins/local-yank-jira.lua
return {
  dir = vim.fn.stdpath('config') .. '/lua/custom/plugins/local/yank_jira',
  name = 'yank-jira',
  keys = { { '<Leader>cj', desc = 'Yank Jira link' } },
  config = function() require('yank_jira').setup() end,
}
```

That's it. lazy treats it like any other plugin: events, keys, lazy-loading, the works. You commit it in dotfiles. No GitHub round-trip.

## 4. Config notes

- Your `treesitter.lua` uses the new install API and registers `nvim-treesitter-textobjects`. Bundled `textobjects.scm` per parser ships under `~/.local/share/nvim/lazy/nvim-treesitter-textobjects/queries/<lang>/textobjects.scm`. **Your overrides at `~/.config/nvim/queries/<lang>/textobjects.scm` win** — they don't replace, they extend.
- No `lua/custom/plugins/local/` directory exists yet. The Optional config edit below proposes creating it with one example.
- `:checkhealth nvim-treesitter` confirms which parsers are installed and where their queries live.

## 5. Concrete examples

### Example A — A custom C++ "function body without leading comment"

`~/.config/nvim/queries/cpp/textobjects.scm`:

```scheme
;; extends

;; @function.inner already exists in the bundled query.
;; Add @function.body — the body MINUS any leading comment block.
(function_definition
  body: (compound_statement
    .  ; first child
    [(comment) (line_comment) (block_comment)]?
    .
    (_) @function.body
    (_)*) @_outer)

;; The `;; extends` directive at top is critical:
;; it says "merge with the bundled query; don't replace it."
```

Bind it in your `mini.ai` spec or via `nvim-treesitter-textobjects`:

```lua
-- in treesitter.lua's textobjects.select.keymaps:
['iB'] = '@function.body',  -- iB = inside Body
```

Restart, open a `.cpp` file with a docblocked function, type `viB` — selection skips the docstring.

### Example B — `:EditQuery` workflow

1. Open a `.cpp` file at any function.
2. Run `:InspectTree` (split to right). Notice the `function_definition` node with its `body:` child.
3. Run `:EditQuery cpp`. Type a query in the left pane:
   ```
   (function_definition body: (compound_statement) @target)
   ```
4. The right pane highlights the matched body node. Iterate until the capture is exactly what you want, then save it to your `queries/cpp/textobjects.scm`.

### Example C — A 50-line local plugin (`yank-jira`)

`lua/custom/plugins/local/yank_jira/lua/yank_jira/init.lua`:

```lua
local M = {}

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', { prefix = 'PROJ-' }, opts or {})
  M._opts = opts
  vim.keymap.set('n', '<Leader>cj', M.yank_link, { desc = 'Yank Jira link' })
end

function M.yank_link()
  vim.ui.input({ prompt = 'Issue # (' .. M._opts.prefix .. '...): ' }, function(num)
    if not num or num == '' then return end
    local id = M._opts.prefix .. num
    local url = ('https://jira.example.com/browse/%s'):format(id)
    vim.fn.setreg('+', url)
    vim.notify('Yanked: ' .. url)
  end)
end

return M
```

`lua/custom/plugins/local-yank-jira.lua` (the lazy spec):

```lua
return {
  dir  = vim.fn.stdpath('config') .. '/lua/custom/plugins/local/yank_jira',
  name = 'yank-jira',
  keys = { { '<Leader>cj', desc = 'Yank Jira link' } },
  config = function() require('yank_jira').setup({ prefix = 'PROJ-' }) end,
}
```

Restart Neovim, press `<Leader>cj`, type a number, paste anywhere — your Jira URL.

## 6. Shortcuts to memorize

### ESSENTIAL
`:InspectTree  :EditQuery <lang>  :checkhealth nvim-treesitter  ~/.config/nvim/queries/<lang>/textobjects.scm`

### OPTIONAL
`;; extends  ;; inherits: <lang>,<lang>  @function.inner @class.outer @parameter.inner @comment.outer`

### ADVANCED
`vim.treesitter.query.parse  vim.treesitter.get_parser  query:iter_captures  vim.treesitter.foldexpr (already wired in Bucket 3.1)`

## 7. Drills

Run each in your own Neovim. Confirm with `done N` / `stuck N <details>`.

1. Open any C++ source. Run `:InspectTree`. Move the cursor inside a function body — confirm the tree-window highlight follows.
2. Open `:EditQuery cpp`. Write a query that captures every `if_statement` body. Verify the captures highlight live.
3. Create `~/.config/nvim/queries/cpp/textobjects.scm` with the `;; extends` directive and add **one** new capture (e.g. `@conditional.outer` for `if_statement`). Restart. Test the capture is recognized via `:lua = require('vim.treesitter.query').parse('cpp', io.open(vim.fn.stdpath('config')..'/queries/cpp/textobjects.scm'):read('*a'))`.
4. Scaffold the `yank-jira` local plugin (Example C). Wire its lazy spec. Restart, press `<Leader>cj`, verify the keymap fires and clipboard contains the URL.

## 8. Troubleshooting

- **"My queries/cpp/textobjects.scm is ignored."** Missing `;; extends` — without it, your query *replaces* the bundled one entirely. Or: parser not installed (`:TSInstall cpp` / new API equivalent in your config).
- **"`:EditQuery` shows no matches."** The pattern uses the wrong node type. Run `:InspectTree` and copy the exact node name from there.
- **"My `dir =` plugin doesn't load."** lazy needs *either* `name` set or the dir's basename to be unique. Also: `dir` must be absolute. `vim.fn.stdpath('config')` expands to your nvim config path.
- **"Lua module not found."** lazy doesn't add `dir/lua` to runtimepath unless the spec is loaded. Use `keys`/`event`/`cmd` to trigger load, or `lazy = false`.

## 9. Optional config edit

Three changes (each can be ASKed independently):

1. Create the queries skeleton: `mkdir -p ~/x/dotfiles/.config/nvim/queries/{cpp,python,rust,lua}` plus an empty `textobjects.scm` with `;; extends` in each.
2. Create `lua/custom/plugins/local/` with the `yank_jira` example as a placeholder so the pattern is real, not theoretical.
3. Add the `local-yank-jira.lua` spec to make it loadable.

## 10. Next-step upgrades

- After a few captures, group per-domain: `queries/cpp/highlights.scm`, `textobjects.scm`, `folds.scm`, `injections.scm`.
- For more sophisticated query matching, learn `#match?`, `#eq?`, `#lua-match?` predicates — `:help treesitter-predicate`.
- Once you have 3+ local plugins, consider extracting to a private GitHub repo — but most personal tools should stay in dotfiles.

## 11. Connects to

This is the last topic in Phase F. From here, the curriculum loops: alternate between `drill`/`warmup` for motion mastery and `audit` for periodic config hygiene. Optional next destinations:
- `/neovim audit` — see what HIGH/MED items have accumulated since the bundle.
- `/neovim 16` — long-term config evolution and the `:checkhealth custom` provider (Bucket 4 of the audit plan).
